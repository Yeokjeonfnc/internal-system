package com.yeokjeon.erp.act001.service;

import com.yeokjeon.erp.act001.entity.Act001Active;
import com.yeokjeon.erp.act001.repository.Act001Repository;
import com.yeokjeon.erp.common.RequestMapUtil;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.ntf001.service.NotificationService;
import com.yeokjeon.erp.str001.entity.Store;
import com.yeokjeon.erp.str001.repository.StoreRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class Act001Service {

    private static final String STATUS_DRAFT = "DRAFT";
    private static final String STATUS_APPROVED = "APPROVED";
    private static final String STATUS_PENDING = "PENDING";

    private final Act001Repository act001Repository;
    private final StoreRepository storeRepository;
    private final JdbcTemplate jdbcTemplate;
    private final NotificationService notificationService;

    public List<Map<String, Object>> getStatusByStore(LocalDate startDt, LocalDate endDt, String brandCd) {
        String normalizedBrand = normalizeBrand(brandCd);

        StringBuilder sql = new StringBuilder("""
                select sm.store_nm as store_nm, am.act_dt as act_dt, count(am.act_idx) as cnt
                from store_mst sm
                         left outer join active_mst am
                            on sm.store_idx = am.store_idx
                            and (am.appr_status = 'PENDING' or am.appr_status = 'APPROVED')
                where 1=1
                """);

        List<Object> params = new ArrayList<>();

        if (normalizedBrand != null) {
            sql.append("  and sm.brand_cd = ?\n");
            params.add(normalizedBrand);
        }

        sql.append("""
                group by sm.store_nm, am.act_dt
                order by sm.store_nm, am.act_dt
                """);

        return jdbcTemplate.query(
                sql.toString(),
                (rs, rowNum) -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("storeNm", rs.getString("store_nm"));
                    m.put("userName", "");
                    m.put("actDt", rs.getObject("act_dt", LocalDate.class));
                    m.put("count", rs.getLong("cnt"));
                    return m;
                },
                params.toArray());
    }

    public List<Map<String, Object>> getStatusByAssignee(LocalDate startDt, LocalDate endDt, String brandCd) {
        String normalizedBrand = normalizeBrand(brandCd);

        StringBuilder sql = new StringBuilder("""
                select um.user_name as user_name, um.user_id as sv_id, am.act_dt as act_dt, count(distinct am.store_idx) as cnt
                from user_mst um
                         left outer join active_mst am
                            on um.user_id = am.sv_id
                            and (am.appr_status = 'PENDING' or am.appr_status = 'APPROVED')
                where um.sv_yn = 'Y'
                """);

        List<Object> params = new ArrayList<>();

        if (normalizedBrand != null) {
            sql.append("""
                      and exists (
                        select 1 from store_mst sm
                        where sm.sv_id = um.user_id
                        and sm.brand_cd = ?
                      )
                    """);
            params.add(normalizedBrand);
        }

        sql.append("""
                group by um.user_id, am.act_dt, um.user_name
                order by um.user_id, am.act_dt
                """);

        return jdbcTemplate.query(
                sql.toString(),
                (rs, rowNum) -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("storeNm", "");
                    m.put("userName", rs.getString("user_name"));
                    m.put("userId", rs.getString("sv_id"));
                    m.put("actDt", rs.getObject("act_dt", LocalDate.class));
                    m.put("count", rs.getLong("cnt"));
                    return m;
                },
                params.toArray());
    }

    public List<Map<String, Object>> getAllActivities() {
        List<Act001Active> rows = act001Repository.findAllActivities();
        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActivityMap(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    public List<Map<String, Object>> getActivitiesByStatus(String apprStatus, String svId, String relUserId) {
        List<Act001Active> rows = act001Repository.findByApprStatusOrderByCreatDtDescActIdxDesc(apprStatus);

        if ("DRAFT".equals(apprStatus) && svId != null && !svId.isBlank()) {
            rows = rows.stream()
                    .filter(active -> svId.equals(active.getSvId()))
                    .collect(Collectors.toList());
        }

        if (relUserId != null && !relUserId.isBlank()
                && (STATUS_PENDING.equals(apprStatus) || STATUS_APPROVED.equals(apprStatus))) {
            final String uid = relUserId.trim();
            rows = rows.stream()
                    .filter(active -> uid.equals(active.getSvId()) || apprIdContainsUser(active.getApprId(), uid))
                    .collect(Collectors.toList());
        }

        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActivityMap(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    private static boolean apprIdContainsUser(String apprIdCsv, String userId) {
        if (apprIdCsv == null || apprIdCsv.isBlank()) {
            return false;
        }
        return Arrays.stream(apprIdCsv.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .anyMatch(userId::equals);
    }

    public Map<String, Object> getActivity(Integer actIdx) {
        Act001Active active = act001Repository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));
        Store store = storeRepository.findByStoreIdx(active.getStoreIdx()).orElse(null);
        Map<String, Object> map = toActivityMap(active, store);
        enrichApprAckMetadata(map, actIdx);
        return map;
    }

    private void enrichApprAckMetadata(Map<String, Object> map, Integer actIdx) {
        Map<String, String> dates = notificationService.approvalAckDateMapForActivity(actIdx);
        map.put("apprAckDateByUserId", new LinkedHashMap<>(dates));
        map.put("apprAckUserIds", new ArrayList<>(dates.keySet()));
    }

    public List<Map<String, Object>> getActivitiesByStore(Integer storeIdx) {
        storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        Store store = storeRepository.findByStoreIdx(storeIdx).orElse(null);
        List<Act001Active> rows = act001Repository.findByStoreIdxOrderByActDtDescActIdxDesc(storeIdx);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActivityMap(active, store, userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    public List<Map<String, Object>> getActivitiesByChecklistYn(Character chkYn) {
        List<Act001Active> rows = act001Repository.findByChkYnOrderByCreatDtDescActIdxDesc(chkYn);
        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActivityMap(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    public List<Map<String, Object>> getApprovedActivitiesWithSuggestions() {
        List<Act001Active> rows = act001Repository.findByApprStatusOrderByCreatDtDescActIdxDesc(STATUS_APPROVED);
        rows = rows.stream()
                .filter(active -> active.getSuggestions() != null
                        && !active.getSuggestions().isBlank())
                .collect(Collectors.toList());

        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActivityMap(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    @Transactional
    public Map<String, Object> createActivity(Map<String, Object> body) {
        int storeIdx = RequestMapUtil.reqInt(body, "storeIdx");
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        Act001Active active = entityFromMap(body);
        normalizeForSave(active);

        Act001Active saved = act001Repository.save(active);

        List<Map<String, Object>> checklistRows = RequestMapUtil.optMapList(body, "checklistResults");
        if (!checklistRows.isEmpty()) {
            saveChecklistResults(saved.getActIdx(), checklistRows);
            saved.setRChkId(saved.getActIdx());
            saved.setChkYn('Y');
            saved = act001Repository.save(saved);
        }

        maybeNotifyPendingApprovers(saved, RequestMapUtil.optStringList(body, "apprUserIds"), null);

        log.info("활동관리 생성 완료: {}", saved.getActIdx());
        return toActivityMap(saved, store);
    }

    @Transactional
    public Map<String, Object> updateActivity(Integer actIdx, Map<String, Object> body) {
        Act001Active active = act001Repository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));

        final String previousApprStatus = active.getApprStatus();

        applyActivityFromMap(active, body);

        List<Map<String, Object>> checklistRows = RequestMapUtil.optMapList(body, "checklistResults");
        if (!checklistRows.isEmpty()) {
            if (active.getRChkId() != null) {
                deleteChecklistResults(actIdx);
            }
            saveChecklistResults(actIdx, checklistRows);
            active.setChkYn('Y');
        }

        normalizeForSave(active);

        Store store = storeRepository.findByStoreIdx(active.getStoreIdx())
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", active.getStoreIdx()));
        Act001Active saved = act001Repository.save(active);
        maybeNotifyPendingApprovers(saved, RequestMapUtil.optStringList(body, "apprUserIds"), previousApprStatus);
        log.info("활동관리 수정 완료: {}", saved.getActIdx());
        return toActivityMap(saved, store);
    }

    private Act001Active entityFromMap(Map<String, Object> m) {
        return Act001Active.builder()
                .storeIdx(RequestMapUtil.reqInt(m, "storeIdx"))
                .actType(RequestMapUtil.reqStr(m, "actType"))
                .actDt(RequestMapUtil.optLocalDate(m, "actDt"))
                .actNotes(RequestMapUtil.optStr(m, "actNotes"))
                .svId(RequestMapUtil.optStr(m, "svId"))
                .apprId(RequestMapUtil.joinCsvDistinct(RequestMapUtil.optStringList(m, "apprUserIds")))
                .apprStatus(RequestMapUtil.optStr(m, "apprStatus"))
                .memoTxt(RequestMapUtil.optStr(m, "memoTxt"))
                .apprDt(RequestMapUtil.optLocalDateTime(m, "apprDt"))
                .suggestions(RequestMapUtil.optStr(m, "suggestions"))
                .svNotes(RequestMapUtil.optStr(m, "svNotes"))
                .rChkId(RequestMapUtil.optInt(m, "rChkId"))
                .chkYn(RequestMapUtil.optChar(m, "chkYn"))
                .build();
    }

    private void applyActivityFromMap(Act001Active active, Map<String, Object> m) {
        if (m.containsKey("storeIdx")) {
            active.setStoreIdx(RequestMapUtil.reqInt(m, "storeIdx"));
        }
        if (m.containsKey("actType")) {
            active.setActType(RequestMapUtil.reqStr(m, "actType"));
        }
        if (m.containsKey("actDt")) {
            active.setActDt(RequestMapUtil.optLocalDate(m, "actDt"));
        }
        if (m.containsKey("actNotes")) {
            active.setActNotes(RequestMapUtil.optStr(m, "actNotes"));
        }
        if (m.containsKey("memoTxt")) {
            active.setMemoTxt(RequestMapUtil.optStr(m, "memoTxt"));
        }
        if (m.containsKey("svId")) {
            active.setSvId(RequestMapUtil.optStr(m, "svId"));
        }
        if (m.containsKey("apprStatus")) {
            active.setApprStatus(RequestMapUtil.optStr(m, "apprStatus"));
        }
        if (m.containsKey("apprDt")) {
            active.setApprDt(RequestMapUtil.optLocalDateTime(m, "apprDt"));
        }
        if (m.containsKey("suggestions")) {
            active.setSuggestions(RequestMapUtil.optStr(m, "suggestions"));
        }
        if (m.containsKey("svNotes")) {
            active.setSvNotes(RequestMapUtil.optStr(m, "svNotes"));
        }
        if (m.containsKey("apprUserIds")) {
            active.setApprId(RequestMapUtil.joinCsvDistinct(RequestMapUtil.optStringList(m, "apprUserIds")));
        }
    }

    @Transactional
    public void deleteActivity(Integer actIdx) {
        Act001Active active = act001Repository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));

        deleteChecklistResults(actIdx);

        act001Repository.delete(active);
        log.info("활동관리 삭제 완료: {}", actIdx);
    }

    private void normalizeForSave(Act001Active active) {
        if (active.getApprStatus() == null || active.getApprStatus().isBlank()) {
            active.setApprStatus(STATUS_DRAFT);
        } else {
            active.setApprStatus(active.getApprStatus().trim().toUpperCase());
        }
        if (active.getChkYn() == null) {
            active.setChkYn('N');
        }
        if (STATUS_APPROVED.equals(active.getApprStatus()) && active.getApprDt() == null) {
            active.setApprDt(LocalDateTime.now());
        }
    }

    private String normalizeBrand(String brandCd) {
        if (brandCd == null || brandCd.isBlank()) return null;
        return brandCd.trim();
    }

    private Map<Integer, Store> storesByIdx(List<Act001Active> rows) {
        List<Integer> ids = rows.stream()
                .map(Act001Active::getStoreIdx)
                .distinct()
                .collect(Collectors.toList());
        return storeRepository.findAllById(ids)
                .stream()
                .collect(Collectors.toMap(Store::getStoreIdx, store -> store));
    }

    private Map<String, Object> toActivityMap(Act001Active active, Store store) {
        String svNm = null;
        String svDeptNm = null;
        if (active.getSvId() != null && !active.getSvId().isBlank()) {
            String[] wd = loadWriterNameAndDept(active.getSvId());
            svNm = wd[0];
            svDeptNm = wd[1];
        }
        return toActivityMap(active, store, svNm, svDeptNm);
    }

    private Map<String, Object> toActivityMap(Act001Active active, Store store, String svNm, String svDeptNm) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("actIdx", active.getActIdx());
        m.put("storeIdx", active.getStoreIdx());
        m.put("storeNm", store == null ? null : store.getStoreNm());
        m.put("storeCd", store == null ? null : store.getStoreCd());
        m.put("brandCd", store == null ? null : store.getBrandCd());
        m.put("brandNm", store == null ? null : toCodeName(store.getBrandCd(), store.getBrandNm()));
        m.put("actType", active.getActType());
        m.put("actDt", active.getActDt());
        m.put("creatDt", active.getCreatDt());
        m.put("memoTxt", active.getMemoTxt());
        m.put("actNotes", active.getActNotes());
        m.put("svId", active.getSvId());
        m.put("svNm", svNm);
        m.put("svDeptNm", svDeptNm);
        m.put("apprId", active.getApprId());
        m.put("apprUserIds", splitApprUserIdsCsv(active.getApprId()));
        m.put("ssvNm", store == null ? null : loadUserName(store.getSvId()));
        m.put("apprStatus", active.getApprStatus());
        m.put("apprDt", active.getApprDt());
        m.put("suggestions", active.getSuggestions());
        m.put("svNotes", active.getSvNotes());
        m.put("rChkId", active.getRChkId());
        m.put("chkYn", active.getChkYn() != null ? String.valueOf(active.getChkYn()) : null);
        return m;
    }

    private List<String> splitApprUserIdsCsv(String apprId) {
        if (apprId == null || apprId.isBlank()) {
            return List.of();
        }
        return Arrays.stream(apprId.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .distinct()
                .toList();
    }

    private void maybeNotifyPendingApprovers(Act001Active saved, List<String> apprUserIdsFromDto,
                                             String previousApprStatus) {
        if (saved.getApprStatus() == null
                || !STATUS_PENDING.equalsIgnoreCase(saved.getApprStatus().trim())) {
            return;
        }
        boolean wasAlreadyPending = previousApprStatus != null
                && STATUS_PENDING.equalsIgnoreCase(previousApprStatus.trim());
        if (wasAlreadyPending) {
            return;
        }
        List<String> ids = apprUserIdsFromDto;
        if (ids == null || ids.isEmpty()) {
            ids = splitApprUserIdsCsv(saved.getApprId());
        }
        if (ids == null || ids.isEmpty()) {
            return;
        }
        notificationService.notifyActivityApprovers(saved.getActIdx(), ids);
    }

    private String toCodeName(String code, String name) {
        return name != null ? name : code;
    }

    private void saveChecklistResults(Integer actIdx, List<Map<String, Object>> results) {
        String sql = """
                INSERT INTO chk_result_dtl (act_idx, chk_idx, answer_val, answer_score)
                VALUES (?, ?, ?, ?)
                """;

        for (Map<String, Object> result : results) {
            Integer chkIdx = RequestMapUtil.optInt(result, "chkIdx");
            if (chkIdx == null) {
                continue;
            }
            String answerVal = RequestMapUtil.optStr(result, "answerVal");
            int score = RequestMapUtil.optInt(result, "answerScore") != null
                    ? RequestMapUtil.optInt(result, "answerScore") : 0;
            jdbcTemplate.update(sql, actIdx, chkIdx, answerVal, score);
        }

        log.info("체크리스트 결과 저장 완료: actIdx={}, 항목수={}", actIdx, results.size());
    }

    private void deleteChecklistResults(Integer actIdx) {
        String sql = "DELETE FROM chk_result_dtl WHERE act_idx = ?";
        int deleted = jdbcTemplate.update(sql, actIdx);
        log.info("체크리스트 결과 삭제 완료: actIdx={}, 삭제된 항목수={}", actIdx, deleted);
    }

    private Map<String, String> loadUserNames(List<Act001Active> activities) {
        List<String> userIds = activities.stream()
                .map(Act001Active::getSvId)
                .filter(svId -> svId != null && !svId.isBlank())
                .distinct()
                .collect(Collectors.toList());

        if (userIds.isEmpty()) {
            return Map.of();
        }

        String placeholders = userIds.stream().map(id -> "?").collect(Collectors.joining(","));
        String sql = "SELECT user_id, user_name FROM user_mst WHERE user_id IN (" + placeholders + ")";

        Map<String, String> result = new LinkedHashMap<>();
        jdbcTemplate.query(sql, rs -> {
            result.put(rs.getString("user_id"), rs.getString("user_name"));
        }, userIds.toArray());

        return result;
    }

    private String[] loadWriterNameAndDept(String svId) {
        String[] empty = new String[]{null, null};
        if (svId == null || svId.isBlank()) {
            return empty;
        }
        String uid = svId.trim();
        try {
            return jdbcTemplate.queryForObject(
                    """
                            SELECT um.user_name AS user_name, dm.dept_nm AS dept_nm
                            FROM user_mst um
                                     LEFT JOIN dept_mst dm ON um.dept_idx = dm.dept_idx
                            WHERE um.user_id = ?
                            """,
                    (rs, rowNum) -> new String[]{rs.getString("user_name"), rs.getString("dept_nm")},
                    uid
            );
        } catch (Exception e) {
            log.warn("작성자 이름·부서 조회 실패: svId={}", uid, e);
            return new String[]{loadUserName(uid), null};
        }
    }

    private String loadUserName(String userId) {
        if (userId == null || userId.isBlank()) {
            return null;
        }

        String sql = "SELECT user_name FROM user_mst WHERE user_id = ?";
        try {
            return jdbcTemplate.queryForObject(sql, String.class, userId);
        } catch (Exception e) {
            log.warn("사용자 이름 조회 실패: userId={}", userId);
            return null;
        }
    }

    public List<Map<String, Object>> getChecklistResults(Integer actIdx) {
        String sql = """
                SELECT
                    CM.chk_idx AS chk_idx,
                    CM.brand_cd AS brand_cd,
                    CM.chk_type AS chk_type,
                    COD.code_nm AS chk_type_nm,
                    CM.chk_content AS chk_content,
                    CM.base_score AS base_score,
                    CM.display_order AS display_order,
                    COALESCE(CRD.answer_val, '미평가') AS answer_val,
                    COALESCE(CRD.answer_score, 0) AS answer_score
                FROM chk_mst CM
                LEFT OUTER JOIN chk_result_dtl CRD
                    ON CM.chk_idx = CRD.chk_idx
                    AND CRD.act_idx = ?
                INNER JOIN code_mst COD
                    ON CM.chk_type = COD.code_cd
                    AND COD.grp_cd = '50'
                INNER JOIN active_mst ACT
                    ON ACT.act_idx = ?
                INNER JOIN store_mst SM
                    ON SM.store_idx = ACT.store_idx
                WHERE CM.use_yn = 'Y'
                    AND CM.brand_cd = SM.brand_cd
                ORDER BY CM.display_order, CM.chk_idx
                """;

        return jdbcTemplate.query(sql, (rs, rowNum) -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("chkIdx", rs.getInt("chk_idx"));
            m.put("brandCd", rs.getString("brand_cd"));
            m.put("chkType", rs.getString("chk_type"));
            m.put("chkTypeNm", rs.getString("chk_type_nm"));
            m.put("chkContent", rs.getString("chk_content"));
            m.put("baseScore", rs.getInt("base_score"));
            m.put("displayOrder", rs.getObject("display_order", Integer.class));
            m.put("answerVal", rs.getString("answer_val"));
            m.put("answerScore", rs.getInt("answer_score"));
            return m;
        }, actIdx, actIdx);
    }
}
