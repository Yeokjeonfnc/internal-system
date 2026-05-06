package com.yeokjeon.erp.store.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.store.dto.StoreCreateDto;
import com.yeokjeon.erp.store.dto.StoreHistoryResponseDto;
import com.yeokjeon.erp.store.dto.StoreResponseDto;
import com.yeokjeon.erp.store.entity.Store;
import com.yeokjeon.erp.store.repository.StoreRepository;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StoreService {

    private final StoreRepository storeRepository;
    private final EntityManager entityManager;
    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper;

    public List<StoreResponseDto> getAllStores() {
        return storeRepository.findAllStores()
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public StoreResponseDto getStoreByIdx(Integer storeIdx) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        return toDto(store);
    }

    public List<StoreHistoryResponseDto> getStoreHistories(Integer storeIdx) {
        storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        return jdbcTemplate.query(
                """
                select his_idx, store_idx, chg_type, chg_dt, chg_user_id, store_nm, chg_content::text as chg_content
                from store_history
                where store_idx = ?
                order by chg_dt desc, his_idx desc
                """,
                (rs, rowNum) -> StoreHistoryResponseDto.builder()
                        .historyIdx(rs.getLong("his_idx"))
                        .storeIdx(rs.getInt("store_idx"))
                        .chgType(rs.getString("chg_type"))
                        .storeNm(rs.getString("store_nm"))
                        .chgContent(toJsonNode(rs.getString("chg_content")))
                        .content(toHistoryContent(
                                rs.getString("chg_type"),
                                rs.getString("store_nm"),
                                rs.getString("chg_content")))
                        .chgUserId(rs.getString("chg_user_id"))
                        .chgDt(rs.getTimestamp("chg_dt").toLocalDateTime())
                        .build(),
                storeIdx);
    }
    
    private StoreResponseDto toDto(Store store) {
        log.debug("Converting store: {}, name: {}", store.getStoreIdx(), store.getStoreNm());
        
        return StoreResponseDto.builder()
                .storeIdx(store.getStoreIdx())
                .storeCd(store.getStoreCd())
                .storeNm(store.getStoreNm())
                .ownerNm(store.getOwnerNm())
                .regionCd(store.getRegionCd())
                .regionNm(toCodeName(store.getRegionCd(), store.getRegionNm()))
                .storeTel(store.getStoreTel())
                .address(store.getAddress())
                .latitude(store.getLatitude())
                .longitude(store.getLongitude())
                .storeStatus(store.getStoreStatus())
                .storeStatusNm(toCodeName(store.getStoreStatus(), store.getStoreStatusNm()))
                .contEndDt(store.getContEndDt())
                .autoRenewalYn(store.getAutoRenewalYn())
                .storeType(store.getStoreType())
                .storeTypeNm(toCodeName(store.getStoreType(), store.getStoreTypeNm()))
                .svId(store.getSvId())
                .createdAt(store.getCreatedAt())
                .updatedAt(store.getUpdatedAt())
                .adressDetail(store.getAdressDetail())
                .zipCd(store.getZipCd())
                .brandCd(store.getBrandCd())
                .brandNm(toCodeName(store.getBrandCd(), store.getBrandNm()))
                .contStartDt(store.getContStartDt())
                .businessNumber(store.getBusinessNumber())
                .firstContDt(store.getFirstContDt())
                .frFee(store.getFrFee())
                .eduFee(store.getEduFee())
                .insuDeposit(store.getInsuDeposit())
                .contDeposit(store.getContDeposit())
                .contManager(store.getContManager())
                .eduManager(store.getEduManager())
                .contArea(store.getContArea())
                .realArea(store.getRealArea())
                .floor(store.getFloor())
                .parkingCount(store.getParkingCount())
                .premiumFee(store.getPremiumFee())
                .monthlyRent(store.getMonthlyRent())
                .rentDeposit(store.getRentDeposit())
                .notes(store.getNotes())
                .build();
    }

    private String toCodeName(String code, String name) {
        return name != null ? name : code;
    }

    private String toHistoryContent(String chgType, String storeNm, String chgContent) {
        if ("INSERT".equals(chgType)) {
            return storeNm != null && !storeNm.isBlank() 
                    ? storeNm + ": 신규 생성"
                    : "가맹점 신규 생성";
        }
        
        if ("DELETE".equals(chgType)) {
            return storeNm != null && !storeNm.isBlank()
                    ? storeNm + ": 삭제"
                    : "가맹점 삭제";
        }
        
        // UPDATE의 경우 변경된 컬럼명들을 추출
        if ("UPDATE".equals(chgType) && chgContent != null && !chgContent.isBlank()) {
            try {
                JsonNode changes = objectMapper.readTree(chgContent);
                if (changes.isArray() && changes.size() > 0) {
                    StringBuilder columns = new StringBuilder();
                    for (int i = 0; i < changes.size(); i++) {
                        JsonNode change = changes.get(i);
                        if (change.has("column_desc")) {
                            if (i > 0) columns.append(", ");
                            columns.append("'").append(change.get("column_desc").asText()).append("'");
                        }
                    }
                    if (columns.length() > 0) {
                        String storeName = storeNm != null && !storeNm.isBlank() ? storeNm : "가맹점";
                        return storeName + ": " + columns.toString() + " 정보 수정";
                    }
                }
            } catch (JsonProcessingException e) {
                log.warn("히스토리 내용 파싱 실패: {}", chgContent, e);
            }
        }
        
        // 기본 처리
        String action = "가맹점 정보 수정";
        if (storeNm != null && !storeNm.isBlank()) {
            return storeNm + ": " + action;
        }
        return action;
    }

    private JsonNode toJsonNode(String rawJson) {
        if (rawJson == null || rawJson.isBlank()) {
            return objectMapper.createArrayNode();
        }
        try {
            return objectMapper.readTree(rawJson);
        } catch (JsonProcessingException e) {
            log.warn("히스토리 JSON 파싱 실패: {}", rawJson, e);
            return objectMapper.createArrayNode();
        }
    }

    @Transactional
    public StoreResponseDto createStore(StoreCreateDto dto) {
        if (dto.getStoreIdx() != null && storeRepository.findByStoreIdx(dto.getStoreIdx()).isPresent()) {
            throw new IllegalArgumentException("이미 존재하는 가맹점 인덱스입니다: " + dto.getStoreIdx());
        }

        Store store = dto.toEntity();
        Store savedStore = storeRepository.saveAndFlush(store);
        entityManager.refresh(savedStore);
        saveHistory(savedStore.getStoreIdx(), "INSERT", savedStore.getStoreNm(),
                String.format("가맹점 신규 생성: %s", savedStore.getStoreNm()));

        log.info("가맹점 생성 완료: {}", savedStore.getStoreIdx());
        return toDto(savedStore);
    }

    @Transactional
    public StoreResponseDto updateStore(Integer storeIdx, StoreCreateDto dto) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));

        // 변경 이력 추적을 위한 변경 내역 수집
        List<FieldChange> changes = new ArrayList<>();

        if (dto.getStoreNm() != null && !dto.getStoreNm().equals(store.getStoreNm())) {
            changes.add(new FieldChange("storeNm", "가맹점명", store.getStoreNm(), dto.getStoreNm()));
            store.setStoreNm(dto.getStoreNm());
        }
        if (dto.getOwnerNm() != null && !dto.getOwnerNm().equals(store.getOwnerNm())) {
            changes.add(new FieldChange("ownerNm", "점주명", store.getOwnerNm(), dto.getOwnerNm()));
            store.setOwnerNm(dto.getOwnerNm());
        }
        if (dto.getRegionCd() != null && !dto.getRegionCd().equals(store.getRegionCd())) {
            changes.add(new FieldChange("regionCd", "지역", store.getRegionCd(), dto.getRegionCd()));
            store.setRegionCd(dto.getRegionCd());
        }
        if (dto.getStoreTel() != null && !dto.getStoreTel().equals(store.getStoreTel())) {
            changes.add(new FieldChange("storeTel", "전화번호", store.getStoreTel(), dto.getStoreTel()));
            store.setStoreTel(dto.getStoreTel());
        }
        if (dto.getAddress() != null && !dto.getAddress().equals(store.getAddress())) {
            changes.add(new FieldChange("address", "주소", store.getAddress(), dto.getAddress()));
            store.setAddress(dto.getAddress());
        }
        if (dto.getLatitude() != null) {
            boolean changed = store.getLatitude() == null || 
                            dto.getLatitude().compareTo(store.getLatitude()) != 0;
            if (changed) {
                changes.add(new FieldChange("latitude", "위도", 
                        store.getLatitude() != null ? store.getLatitude().toPlainString() : null, 
                        dto.getLatitude().toPlainString()));
                store.setLatitude(dto.getLatitude());
            }
        }
        if (dto.getLongitude() != null) {
            boolean changed = store.getLongitude() == null || 
                            dto.getLongitude().compareTo(store.getLongitude()) != 0;
            if (changed) {
                changes.add(new FieldChange("longitude", "경도", 
                        store.getLongitude() != null ? store.getLongitude().toPlainString() : null, 
                        dto.getLongitude().toPlainString()));
                store.setLongitude(dto.getLongitude());
            }
        }
        if (dto.getStoreStatus() != null && !dto.getStoreStatus().equals(store.getStoreStatus())) {
            changes.add(new FieldChange("storeStatus", "계약상태", store.getStoreStatus(), dto.getStoreStatus()));
            store.setStoreStatus(dto.getStoreStatus());
        }
        if (dto.getContEndDt() != null && !dto.getContEndDt().equals(store.getContEndDt())) {
            changes.add(new FieldChange("contEndDt", "계약종료일", 
                    store.getContEndDt() != null ? store.getContEndDt().toString() : null, 
                    dto.getContEndDt().toString()));
            store.setContEndDt(dto.getContEndDt());
        }
        if (dto.getAutoRenewalYn() != null && !dto.getAutoRenewalYn().equals(store.getAutoRenewalYn())) {
            changes.add(new FieldChange("autoRenewalYn", "자동갱신여부", 
                    store.getAutoRenewalYn() != null ? store.getAutoRenewalYn().toString() : null, 
                    dto.getAutoRenewalYn().toString()));
            store.setAutoRenewalYn(dto.getAutoRenewalYn());
        }
        if (dto.getStoreType() != null && !dto.getStoreType().equals(store.getStoreType())) {
            changes.add(new FieldChange("storeType", "가맹점구분", store.getStoreType(), dto.getStoreType()));
            store.setStoreType(dto.getStoreType());
        }
        if (dto.getSvId() != null && !dto.getSvId().equals(store.getSvId())) {
            changes.add(new FieldChange("svId", "수퍼바이저", store.getSvId(), dto.getSvId()));
            store.setSvId(dto.getSvId());
        }
        if (dto.getAdressDetail() != null && !dto.getAdressDetail().equals(store.getAdressDetail())) {
            changes.add(new FieldChange("adressDetail", "상세주소", store.getAdressDetail(), dto.getAdressDetail()));
            store.setAdressDetail(dto.getAdressDetail());
        }
        if (dto.getZipCd() != null && !dto.getZipCd().equals(store.getZipCd())) {
            changes.add(new FieldChange("zipCd", "우편번호", store.getZipCd(), dto.getZipCd()));
            store.setZipCd(dto.getZipCd());
        }
        if (dto.getBrandCd() != null && !dto.getBrandCd().equals(store.getBrandCd())) {
            changes.add(new FieldChange("brandCd", "브랜드", store.getBrandCd(), dto.getBrandCd()));
            store.setBrandCd(dto.getBrandCd());
        }
        if (dto.getContStartDt() != null && !dto.getContStartDt().equals(store.getContStartDt())) {
            changes.add(new FieldChange("contStartDt", "계약시작일", 
                    store.getContStartDt() != null ? store.getContStartDt().toString() : null, 
                    dto.getContStartDt().toString()));
            store.setContStartDt(dto.getContStartDt());
        }
        if (dto.getBusinessNumber() != null && !dto.getBusinessNumber().equals(store.getBusinessNumber())) {
            changes.add(new FieldChange("businessNumber", "사업자번호", store.getBusinessNumber(), dto.getBusinessNumber()));
            store.setBusinessNumber(dto.getBusinessNumber());
        }
        if (dto.getNotes() != null && !dto.getNotes().equals(store.getNotes())) {
            changes.add(new FieldChange("notes", "비고", store.getNotes(), dto.getNotes()));
            store.setNotes(dto.getNotes());
        }
        if (dto.getFirstContDt() != null && !dto.getFirstContDt().equals(store.getFirstContDt())) {
            changes.add(new FieldChange("firstContDt", "최초계약일", 
                    store.getFirstContDt() != null ? store.getFirstContDt().toString() : null, 
                    dto.getFirstContDt().toString()));
            store.setFirstContDt(dto.getFirstContDt());
        }
        if (dto.getFrFee() != null) {
            boolean changed = store.getFrFee() == null || 
                            dto.getFrFee().compareTo(store.getFrFee()) != 0;
            if (changed) {
                changes.add(new FieldChange("frFee", "가맹비", 
                        store.getFrFee() != null ? store.getFrFee().toPlainString() : null, 
                        dto.getFrFee().toPlainString()));
                store.setFrFee(dto.getFrFee());
            }
        }
        if (dto.getEduFee() != null) {
            boolean changed = store.getEduFee() == null || 
                            dto.getEduFee().compareTo(store.getEduFee()) != 0;
            if (changed) {
                changes.add(new FieldChange("eduFee", "교육비", 
                        store.getEduFee() != null ? store.getEduFee().toPlainString() : null, 
                        dto.getEduFee().toPlainString()));
                store.setEduFee(dto.getEduFee());
            }
        }
        if (dto.getInsuDeposit() != null) {
            boolean changed = store.getInsuDeposit() == null || 
                            dto.getInsuDeposit().compareTo(store.getInsuDeposit()) != 0;
            if (changed) {
                changes.add(new FieldChange("insuDeposit", "보증보험료", 
                        store.getInsuDeposit() != null ? store.getInsuDeposit().toPlainString() : null, 
                        dto.getInsuDeposit().toPlainString()));
                store.setInsuDeposit(dto.getInsuDeposit());
            }
        }
        if (dto.getContDeposit() != null) {
            boolean changed = store.getContDeposit() == null || 
                            dto.getContDeposit().compareTo(store.getContDeposit()) != 0;
            if (changed) {
                changes.add(new FieldChange("contDeposit", "계약금", 
                        store.getContDeposit() != null ? store.getContDeposit().toPlainString() : null, 
                        dto.getContDeposit().toPlainString()));
                store.setContDeposit(dto.getContDeposit());
            }
        }
        if (dto.getContManager() != null && !dto.getContManager().equals(store.getContManager())) {
            changes.add(new FieldChange("contManager", "계약담당자", store.getContManager(), dto.getContManager()));
            store.setContManager(dto.getContManager());
        }
        if (dto.getEduManager() != null && !dto.getEduManager().equals(store.getEduManager())) {
            changes.add(new FieldChange("eduManager", "교육담당자", store.getEduManager(), dto.getEduManager()));
            store.setEduManager(dto.getEduManager());
        }
        if (dto.getContArea() != null) {
            boolean changed = store.getContArea() == null || 
                            dto.getContArea().compareTo(store.getContArea()) != 0;
            if (changed) {
                changes.add(new FieldChange("contArea", "계약면적", 
                        store.getContArea() != null ? store.getContArea().toPlainString() : null, 
                        dto.getContArea().toPlainString()));
                store.setContArea(dto.getContArea());
            }
        }
        if (dto.getRealArea() != null) {
            boolean changed = store.getRealArea() == null || 
                            dto.getRealArea().compareTo(store.getRealArea()) != 0;
            if (changed) {
                changes.add(new FieldChange("realArea", "실사용면적", 
                        store.getRealArea() != null ? store.getRealArea().toPlainString() : null, 
                        dto.getRealArea().toPlainString()));
                store.setRealArea(dto.getRealArea());
            }
        }
        if (dto.getFloor() != null && !dto.getFloor().equals(store.getFloor())) {
            changes.add(new FieldChange("floor", "층수", 
                    store.getFloor() != null ? store.getFloor().toString() : null, 
                    dto.getFloor().toString()));
            store.setFloor(dto.getFloor());
        }
        if (dto.getParkingCount() != null && !dto.getParkingCount().equals(store.getParkingCount())) {
            changes.add(new FieldChange("parkingCount", "주차대수", 
                    store.getParkingCount() != null ? store.getParkingCount().toString() : null, 
                    dto.getParkingCount().toString()));
            store.setParkingCount(dto.getParkingCount());
        }
        if (dto.getPremiumFee() != null && !dto.getPremiumFee().equals(store.getPremiumFee())) {
            changes.add(new FieldChange("premiumFee", "권리금", 
                    store.getPremiumFee() != null ? store.getPremiumFee().toString() : null, 
                    dto.getPremiumFee().toString()));
            store.setPremiumFee(dto.getPremiumFee());
        }
        if (dto.getMonthlyRent() != null && !dto.getMonthlyRent().equals(store.getMonthlyRent())) {
            changes.add(new FieldChange("monthlyRent", "월세", 
                    store.getMonthlyRent() != null ? store.getMonthlyRent().toString() : null, 
                    dto.getMonthlyRent().toString()));
            store.setMonthlyRent(dto.getMonthlyRent());
        }
        if (dto.getRentDeposit() != null && !dto.getRentDeposit().equals(store.getRentDeposit())) {
            changes.add(new FieldChange("rentDeposit", "보증금", 
                    store.getRentDeposit() != null ? store.getRentDeposit().toString() : null, 
                    dto.getRentDeposit().toString()));
            store.setRentDeposit(dto.getRentDeposit());
        }

        Store updatedStore = storeRepository.save(store);
        
        // 변경 사항이 있을 때만 히스토리 저장
        if (!changes.isEmpty()) {
            saveHistoryWithChanges(updatedStore.getStoreIdx(), updatedStore.getStoreNm(), changes);
        }
        
        log.info("가맹점 수정 완료: {}", updatedStore.getStoreCd());
        return toDto(updatedStore);
    }

    @Transactional
    public void deleteStore(Integer storeIdx) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));

        dropStoreHistoryForeignKeyIfExists();
        saveHistory(store.getStoreIdx(), "DELETE", store.getStoreNm(),
                String.format("가맹점 삭제: %s", store.getStoreNm()));
        storeRepository.delete(store);
        log.info("가맹점 삭제 완료: {}", storeIdx);
    }

    private void dropStoreHistoryForeignKeyIfExists() {
        jdbcTemplate.execute("alter table store_history drop constraint if exists fk_his_store_idx");
    }

    private void saveHistoryWithChanges(Integer storeIdx, String storeNm, List<FieldChange> changes) {
        if (storeIdx == null || changes.isEmpty()) {
            return;
        }

        StringBuilder jsonBuilder = new StringBuilder("[");
        for (int i = 0; i < changes.size(); i++) {
            FieldChange change = changes.get(i);
            if (i > 0) jsonBuilder.append(",");
            jsonBuilder.append("{");
            jsonBuilder.append("\"storeIdx\":").append(storeIdx).append(",");
            jsonBuilder.append("\"storeNm\":").append(escapeJson(storeNm)).append(",");
            jsonBuilder.append("\"column_nm\":").append(escapeJson(change.columnNm)).append(",");
            jsonBuilder.append("\"column_desc\":").append(escapeJson(change.columnDesc)).append(",");
            jsonBuilder.append("\"before_value\":").append(escapeJson(change.beforeValue)).append(",");
            jsonBuilder.append("\"after_value\":").append(escapeJson(change.afterValue));
            jsonBuilder.append("}");
        }
        jsonBuilder.append("]");

        jdbcTemplate.update(
                """
                insert into store_history (store_idx, chg_type, chg_user_id, store_nm, chg_content)
                values (?, 'UPDATE', 'system', ?, ?::jsonb)
                """,
                storeIdx,
                storeNm,
                jsonBuilder.toString());
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "null";
        }
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException e) {
            return "\"\"";
        }
    }

    private static class FieldChange {
        final String columnNm;
        final String columnDesc;
        final String beforeValue;
        final String afterValue;

        FieldChange(String columnNm, String columnDesc, String beforeValue, String afterValue) {
            this.columnNm = columnNm;
            this.columnDesc = columnDesc;
            this.beforeValue = beforeValue;
            this.afterValue = afterValue;
        }
    }

    private void saveHistory(Integer storeIdx, String chgType, String storeNm, String content) {
        if (storeIdx == null) {
            log.warn("가맹점 히스토리 저장 건너뜀: storeIdx 없음, chgType={}, content={}", chgType, content);
            return;
        }
        jdbcTemplate.update(
                """
                insert into store_history (store_idx, chg_type, chg_user_id, store_nm, chg_content)
                values (?, ?, ?, ?, jsonb_build_array(jsonb_build_object(
                    'column_nm', 'store',
                    'column_desc', '가맹점',
                    'before_value', null,
                    'after_value', ?
                )))
                """,
                storeIdx,
                chgType,
                "system",
                storeNm,
                content);
    }

    public List<StoreResponseDto> searchStoresByName(String storeNm) {
        return storeRepository.findByStoreNmContaining(storeNm)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }
}
