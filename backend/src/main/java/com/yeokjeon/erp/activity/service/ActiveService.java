package com.yeokjeon.erp.activity.service;

import com.yeokjeon.erp.activity.dto.ActiveRequestDto;
import com.yeokjeon.erp.activity.dto.ActiveResponseDto;
import com.yeokjeon.erp.activity.dto.ActivityStatusRowDto;
import com.yeokjeon.erp.activity.entity.Active;
import com.yeokjeon.erp.activity.repository.ActiveRepository;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.store.entity.Store;
import com.yeokjeon.erp.store.repository.StoreRepository;
import com.yeokjeon.erp.notification.service.NotificationService;
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
public class ActiveService {

    private static final String STATUS_DRAFT = "DRAFT";
    private static final String STATUS_APPROVED = "APPROVED";
    private static final String STATUS_PENDING = "PENDING";

    private final ActiveRepository activeRepository;
    private final StoreRepository storeRepository;
    private final JdbcTemplate jdbcTemplate;
    private final NotificationService notificationService;

    public List<ActivityStatusRowDto> getStatusByStore(LocalDate startDt, LocalDate endDt, String brandCd) {
        String normalizedBrandCd = normalizeBrand(brandCd);
        
        StringBuilder sql = new StringBuilder("""
                select sm.store_nm, am.act_dt, count(am.act_idx) as cnt
                from store_mst sm
                         left outer join active_mst am 
                            on sm.store_idx = am.store_idx
                            and (am.appr_status = 'PENDING' or am.appr_status = 'APPROVED')
                where 1=1
                """);
        
        List<Object> params = new java.util.ArrayList<>();
        
        if (normalizedBrandCd != null) {
            sql.append("  and sm.brand_cd = ?\n");
            params.add(normalizedBrandCd);
        }
        
        sql.append("""
                group by sm.store_nm, am.act_dt
                order by sm.store_nm, am.act_dt
                """);
        
        return jdbcTemplate.query(
                sql.toString(),
                (rs, rowNum) -> ActivityStatusRowDto.builder()
                        .storeNm(rs.getString("store_nm"))
                        .actDt(rs.getObject("act_dt", LocalDate.class))
                        .count(rs.getLong("cnt"))
                        .build(),
                params.toArray());
    }

    public List<ActivityStatusRowDto> getStatusByAssignee(LocalDate startDt, LocalDate endDt, String brandCd) {
        String normalizedBrandCd = normalizeBrand(brandCd);
        
        StringBuilder sql = new StringBuilder("""
                select um.user_name, um.user_id as sv_id, am.act_dt, count(distinct am.store_idx) as cnt
                from user_mst um
                         left outer join active_mst am 
                            on um.user_id = am.sv_id
                            and (am.appr_status = 'PENDING' or am.appr_status = 'APPROVED')
                where um.sv_yn = 'Y'
                """);
        
        List<Object> params = new java.util.ArrayList<>();
        
        if (normalizedBrandCd != null) {
            sql.append("""
                      and exists (
                        select 1 from store_mst sm 
                        where sm.sv_id = um.user_id 
                        and sm.brand_cd = ?
                      )
                    """);
            params.add(normalizedBrandCd);
        }
        
        sql.append("""
                group by um.user_id, am.act_dt, um.user_name
                order by um.user_id, am.act_dt
                """);
        
        return jdbcTemplate.query(
                sql.toString(),
                (rs, rowNum) -> ActivityStatusRowDto.builder()
                        .userId(rs.getString("sv_id"))
                        .userName(rs.getString("user_name"))
                        .actDt(rs.getObject("act_dt", LocalDate.class))
                        .count(rs.getLong("cnt"))
                        .build(),
                params.toArray());
    }

    public List<ActiveResponseDto> getAllActivities() {
        List<Active> rows = activeRepository.findAllActivities();
        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);
        
        return rows.stream()
                .map(active -> toDto(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    public List<ActiveResponseDto> getActivitiesByStatus(String apprStatus, String svId, String relUserId) {
        List<Active> rows = activeRepository.findByApprStatusOrderByCreatDtDescActIdxDesc(apprStatus);

        // 임시보관(DRAFT)일 경우 로그인 유저의 것만 필터링
        if ("DRAFT".equals(apprStatus) && svId != null && !svId.isBlank()) {
            rows = rows.stream()
                    .filter(active -> svId.equals(active.getSvId()))
                    .collect(Collectors.toList());
        }

        // 결재대기·결재완료: 작성자(sv_id) 또는 결재선(appr_id CSV)에 로그인 유저가 포함된 건만
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
                .map(active -> toDto(active, stores.get(active.getStoreIdx()),
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

    public ActiveResponseDto getActivity(Integer actIdx) {
        Active active = activeRepository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));
        Store store = storeRepository.findByStoreIdx(active.getStoreIdx()).orElse(null);
        ActiveResponseDto dto = toDto(active, store);
        enrichApprAckMetadata(dto, actIdx);
        return dto;
    }

    private void enrichApprAckMetadata(ActiveResponseDto dto, Integer actIdx) {
        Map<String, String> dates = notificationService.approvalAckDateMapForActivity(actIdx);
        dto.setApprAckDateByUserId(new LinkedHashMap<>(dates));
        dto.setApprAckUserIds(new ArrayList<>(dates.keySet()));
    }

    public List<ActiveResponseDto> getActivitiesByStore(Integer storeIdx) {
        storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        Store store = storeRepository.findByStoreIdx(storeIdx).orElse(null);
        List<Active> rows = activeRepository.findByStoreIdxOrderByActDtDescActIdxDesc(storeIdx);
        Map<String, String> userNames = loadUserNames(rows);
        
        return rows.stream()
                .map(active -> toDto(active, store, userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    public List<ActiveResponseDto> getActivitiesByChecklistYn(Character chkYn) {
        List<Active> rows = activeRepository.findByChkYnOrderByCreatDtDescActIdxDesc(chkYn);
        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);
        
        return rows.stream()
                .map(active -> toDto(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    /** 결재완료이면서 건의사항(suggestions)이 비어 있지 않은 활동만 */
    public List<ActiveResponseDto> getApprovedActivitiesWithSuggestions() {
        List<Active> rows = activeRepository.findByApprStatusOrderByCreatDtDescActIdxDesc(STATUS_APPROVED);
        rows = rows.stream()
                .filter(active -> active.getSuggestions() != null
                        && !active.getSuggestions().isBlank())
                .collect(Collectors.toList());

        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toDto(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    @Transactional
    public ActiveResponseDto createActivity(ActiveRequestDto dto) {
        Store store = storeRepository.findByStoreIdx(dto.getStoreIdx())
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", dto.getStoreIdx()));
        Active active = dto.toEntity();
        normalizeForSave(active);
        
        // 먼저 활동을 저장하여 actIdx를 얻음
        Active saved = activeRepository.save(active);
        
        // 체크리스트 결과가 있으면 저장
        if (dto.getChecklistResults() != null && !dto.getChecklistResults().isEmpty()) {
            saveChecklistResults(saved.getActIdx(), dto.getChecklistResults());
            saved.setRChkId(saved.getActIdx());
            saved.setChkYn('Y');
            saved = activeRepository.save(saved);
        }

        maybeNotifyPendingApprovers(saved, dto.getApprUserIds(), null);

        log.info("활동관리 생성 완료: {}", saved.getActIdx());
        return toDto(saved, store);
    }

    @Transactional
    public ActiveResponseDto updateActivity(Integer actIdx, ActiveRequestDto dto) {
        Active active = activeRepository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));

        final String previousApprStatus = active.getApprStatus();

        active.setStoreIdx(dto.getStoreIdx());
        active.setActType(dto.getActType());
        active.setActDt(dto.getActDt());
        active.setActNotes(dto.getActNotes());
        active.setMemoTxt(dto.getMemoTxt());
        active.setSvId(dto.getSvId());
        active.setApprStatus(dto.getApprStatus());
        active.setApprDt(dto.getApprDt());
        active.setSuggestions(dto.getSuggestions());
        active.setSvNotes(dto.getSvNotes());
        if (dto.getApprUserIds() != null) {
            active.setApprId(ActiveRequestDto.joinApprUserIds(dto.getApprUserIds()));
        }

        // 체크리스트 결과 업데이트
        if (dto.getChecklistResults() != null && !dto.getChecklistResults().isEmpty()) {
            // 기존 체크리스트 결과 삭제
            if (active.getRChkId() != null) {
                deleteChecklistResults(actIdx);
            }
            // 새로운 체크리스트 결과 저장
            saveChecklistResults(actIdx, dto.getChecklistResults());
            active.setChkYn('Y');
        }
        
        normalizeForSave(active);

        Store store = storeRepository.findByStoreIdx(active.getStoreIdx())
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", active.getStoreIdx()));
        Active saved = activeRepository.save(active);
        maybeNotifyPendingApprovers(saved, dto.getApprUserIds(), previousApprStatus);
        log.info("활동관리 수정 완료: {}", saved.getActIdx());
        return toDto(saved, store);
    }

    @Transactional
    public void deleteActivity(Integer actIdx) {
        Active active = activeRepository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));
        
        // 체크리스트 결과 삭제
        deleteChecklistResults(actIdx);
        
        activeRepository.delete(active);
        log.info("활동관리 삭제 완료: {}", actIdx);
    }

    private void normalizeForSave(Active active) {
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

    private Map<Integer, Store> storesByIdx(List<Active> rows) {
        List<Integer> ids = rows.stream()
                .map(Active::getStoreIdx)
                .distinct()
                .collect(Collectors.toList());
        return storeRepository.findAllById(ids)
                .stream()
                .collect(Collectors.toMap(Store::getStoreIdx, store -> store));
    }

    private ActiveResponseDto toDto(Active active, Store store) {
        String svNm = null;
        String svDeptNm = null;
        if (active.getSvId() != null && !active.getSvId().isBlank()) {
            String[] wd = loadWriterNameAndDept(active.getSvId());
            svNm = wd[0];
            svDeptNm = wd[1];
        }
        return toDto(active, store, svNm, svDeptNm);
    }

    private ActiveResponseDto toDto(Active active, Store store, String svNm, String svDeptNm) {

        return ActiveResponseDto.builder()
                .actIdx(active.getActIdx())
                .storeIdx(active.getStoreIdx())
                .storeNm(store == null ? null : store.getStoreNm())
                .storeCd(store == null ? null : store.getStoreCd())
                .brandCd(store == null ? null : store.getBrandCd())
                .brandNm(store == null ? null : toCodeName(store.getBrandCd(), store.getBrandNm()))
                .actType(active.getActType())
                .actDt(active.getActDt())
                .creatDt(active.getCreatDt())
                .memoTxt(active.getMemoTxt())
                .actNotes(active.getActNotes())
                .svId(active.getSvId())
                .svNm(svNm)  // 활동관리작성자
                .svDeptNm(svDeptNm)
                .apprId(active.getApprId())
                .apprUserIds(splitApprUserIdsCsv(active.getApprId()))
                .sSvNm(store == null ? null : loadUserName(store.getSvId()))  // 가맹점 담당 수퍼바이저 이름
                .apprStatus(active.getApprStatus())
                .apprDt(active.getApprDt())
                .suggestions(active.getSuggestions())
                .svNotes(active.getSvNotes())
                .rChkId(active.getRChkId())
                .chkYn(active.getChkYn())
                .build();
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

    /** 최초 상신(PENDING) 전환 시에만 결재자에게 알림을 남긴다 */
    private void maybeNotifyPendingApprovers(Active saved, java.util.List<String> apprUserIdsFromDto,
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
        java.util.List<String> ids = apprUserIdsFromDto;
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

    /**
     * 체크리스트 결과 저장
     */
    private Integer saveChecklistResults(Integer actIdx, List<com.yeokjeon.erp.activity.dto.ChecklistResultDto> results) {
        String sql = """
                INSERT INTO chk_result_dtl (act_idx, chk_idx, answer_val, answer_score)
                VALUES (?, ?, ?, ?)
                """;
        
        for (com.yeokjeon.erp.activity.dto.ChecklistResultDto result : results) {
            jdbcTemplate.update(sql, 
                actIdx, 
                result.getChkIdx(), 
                result.getAnswerVal(), 
                result.getAnswerScore() != null ? result.getAnswerScore() : 0
            );
        }
        
        log.info("체크리스트 결과 저장 완료: actIdx={}, 항목수={}", actIdx, results.size());
        return actIdx;
    }

    /**
     * 체크리스트 결과 삭제
     */
    private void deleteChecklistResults(Integer actIdx) {
        String sql = "DELETE FROM chk_result_dtl WHERE act_idx = ?";
        int deleted = jdbcTemplate.update(sql, actIdx);
        log.info("체크리스트 결과 삭제 완료: actIdx={}, 삭제된 항목수={}", actIdx, deleted);
    }

    /**
     * 사용자 이름 일괄 조회
     */
    private Map<String, String> loadUserNames(List<Active> activities) {
        List<String> userIds = activities.stream()
                .map(Active::getSvId)
                .filter(svId -> svId != null && !svId.isBlank())
                .distinct()
                .collect(Collectors.toList());
        
        if (userIds.isEmpty()) {
            return Map.of();
        }
        
        String placeholders = userIds.stream().map(id -> "?").collect(Collectors.joining(","));
        String sql = "SELECT user_id, user_name FROM user_mst WHERE user_id IN (" + placeholders + ")";
        
        Map<String, String> result = new java.util.HashMap<>();
        jdbcTemplate.query(sql, rs -> {
            result.put(rs.getString("user_id"), rs.getString("user_name"));
        }, userIds.toArray());
        
        return result;
    }

    /** 작성자(sv_id)의 이름·부서명 — 상세 결재 정보 표시용 */
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

    /**
     * 단일 사용자 이름 조회
     */
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

    /**
     * 활동별 체크리스트 결과 조회
     */
    public List<Map<String, Object>> getChecklistResults(Integer actIdx) {
        String sql = """
                SELECT 
                    CM.chk_idx,
                    CM.brand_cd,
                    CM.chk_type,
                    COD.code_nm AS chk_type_nm,
                    CM.chk_content,
                    CM.base_score,
                    CM.display_order,
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
            Map<String, Object> result = new java.util.HashMap<>();
            result.put("chkIdx", rs.getInt("chk_idx"));
            result.put("brandCd", rs.getString("brand_cd"));
            result.put("chkType", rs.getString("chk_type"));
            result.put("chkTypeNm", rs.getString("chk_type_nm"));
            result.put("chkContent", rs.getString("chk_content"));
            result.put("baseScore", rs.getInt("base_score"));
            result.put("displayOrder", rs.getObject("display_order", Integer.class));
            result.put("answerVal", rs.getString("answer_val"));
            result.put("answerScore", rs.getInt("answer_score"));
            return result;
        }, actIdx, actIdx);
    }
}
