package com.yeokjeon.erp.activity.service;

import com.yeokjeon.erp.activity.dto.ActiveRequestDto;
import com.yeokjeon.erp.activity.dto.ActiveResponseDto;
import com.yeokjeon.erp.activity.dto.ActivityStatusRowDto;
import com.yeokjeon.erp.activity.entity.Active;
import com.yeokjeon.erp.activity.repository.ActiveRepository;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.store.entity.Store;
import com.yeokjeon.erp.store.repository.StoreRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
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

    private final ActiveRepository activeRepository;
    private final StoreRepository storeRepository;
    private final JdbcTemplate jdbcTemplate;

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
                select um.user_id as sv_id, am.act_dt, count(distinct am.store_idx) as cnt
                from user_mst um
                         left outer join active_mst am 
                            on um.user_id = coalesce(am.sv_id, (select sv_id from store_mst where store_idx = am.store_idx))
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
                group by um.user_id, am.act_dt
                order by um.user_id, am.act_dt
                """);
        
        return jdbcTemplate.query(
                sql.toString(),
                (rs, rowNum) -> ActivityStatusRowDto.builder()
                        .userId(rs.getString("sv_id"))
                        .actDt(rs.getObject("act_dt", LocalDate.class))
                        .count(rs.getLong("cnt"))
                        .build(),
                params.toArray());
    }

    public List<ActiveResponseDto> getAllActivities() {
        List<Active> rows = activeRepository.findAllActivities();
        Map<Integer, Store> stores = storesByIdx(rows);
        return rows.stream()
                .map(active -> toDto(active, stores.get(active.getStoreIdx())))
                .collect(Collectors.toList());
    }

    public List<ActiveResponseDto> getActivitiesByStatus(String apprStatus) {
        List<Active> rows = activeRepository.findByApprStatusOrderByCreatDtDescActIdxDesc(apprStatus);
        Map<Integer, Store> stores = storesByIdx(rows);
        return rows.stream()
                .map(active -> toDto(active, stores.get(active.getStoreIdx())))
                .collect(Collectors.toList());
    }

    public ActiveResponseDto getActivity(Integer actIdx) {
        Active active = activeRepository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));
        Store store = storeRepository.findByStoreIdx(active.getStoreIdx()).orElse(null);
        return toDto(active, store);
    }

    public List<ActiveResponseDto> getActivitiesByStore(Integer storeIdx) {
        storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        Store store = storeRepository.findByStoreIdx(storeIdx).orElse(null);
        return activeRepository.findByStoreIdxOrderByActDtDescActIdxDesc(storeIdx)
                .stream()
                .map(active -> toDto(active, store))
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
        
        log.info("활동관리 생성 완료: {}", saved.getActIdx());
        return toDto(saved, store);
    }

    @Transactional
    public ActiveResponseDto updateActivity(Integer actIdx, ActiveRequestDto dto) {
        Active active = activeRepository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));

        active.setStoreIdx(dto.getStoreIdx());
        active.setActType(dto.getActType());
        active.setActDt(dto.getActDt());
        active.setActNotes(dto.getActNotes());
        active.setSvId(dto.getSvId());
        active.setApprStatus(dto.getApprStatus());
        active.setApprDt(dto.getApprDt());
        active.setSuggestions(dto.getSuggestions());
        active.setSvNotes(dto.getSvNotes());
        
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
        log.info("활동관리 수정 완료: {}", saved.getActIdx());
        return toDto(saved, store);
    }

    @Transactional
    public void deleteActivity(Integer actIdx) {
        Active active = activeRepository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));
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
                .actNotes(active.getActNotes())
                .svId(active.getSvId())
                .apprStatus(active.getApprStatus())
                .apprDt(active.getApprDt())
                .suggestions(active.getSuggestions())
                .svNotes(active.getSvNotes())
                .rChkId(active.getRChkId())
                .chkYn(active.getChkYn())
                .build();
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
                WHERE CM.use_yn = 'Y'
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
        }, actIdx);
    }
}
