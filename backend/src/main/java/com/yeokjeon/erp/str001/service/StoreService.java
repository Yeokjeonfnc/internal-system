package com.yeokjeon.erp.str001.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yeokjeon.erp.common.RequestMapUtil;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.str001.entity.Store;
import com.yeokjeon.erp.str001.repository.StoreRepository;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
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

    public List<Map<String, Object>> getAllStores() {
        return storeRepository.findAllStores()
                .stream()
                .map(this::toStoreMap)
                .collect(Collectors.toList());
    }

    public Map<String, Object> getStoreByIdx(Integer storeIdx) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        return toStoreMap(store);
    }

    public List<Map<String, Object>> getStoreHistories(Integer storeIdx) {
        storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        return jdbcTemplate.query(
                """
                select his_idx, store_idx, chg_type, chg_dt, chg_user_id, store_nm, chg_content::text as chg_content
                from store_history
                where store_idx = ?
                order by chg_dt desc, his_idx desc
                """,
                (rs, rowNum) -> {
                    String chgContentRaw = rs.getString("chg_content");
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("historyIdx", rs.getLong("his_idx"));
                    m.put("storeIdx", rs.getInt("store_idx"));
                    m.put("chgType", rs.getString("chg_type"));
                    m.put("storeNm", rs.getString("store_nm"));
                    m.put("chgContent", toJsonNode(chgContentRaw));
                    m.put("content", toHistoryContent(
                            rs.getString("chg_type"),
                            rs.getString("store_nm"),
                            chgContentRaw));
                    m.put("chgUserId", rs.getString("chg_user_id"));
                    m.put("chgDt", rs.getTimestamp("chg_dt").toLocalDateTime());
                    return m;
                },
                storeIdx);
    }

    private Map<String, Object> toStoreMap(Store store) {
        log.debug("Converting store: {}, name: {}", store.getStoreIdx(), store.getStoreNm());

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("storeIdx", store.getStoreIdx());
        m.put("storeCd", store.getStoreCd());
        m.put("storeNm", store.getStoreNm());
        m.put("ownerNm", store.getOwnerNm());
        m.put("regionCd", store.getRegionCd());
        m.put("regionNm", toCodeName(store.getRegionCd(), store.getRegionNm()));
        m.put("storeTel", store.getStoreTel());
        m.put("address", store.getAddress());
        m.put("latitude", store.getLatitude());
        m.put("longitude", store.getLongitude());
        m.put("storeStatus", store.getStoreStatus());
        m.put("storeStatusNm", toCodeName(store.getStoreStatus(), store.getStoreStatusNm()));
        m.put("contEndDt", store.getContEndDt());
        m.put("autoRenewalYn", store.getAutoRenewalYn());
        m.put("storeType", store.getStoreType());
        m.put("storeTypeNm", toCodeName(store.getStoreType(), store.getStoreTypeNm()));
        m.put("svId", store.getSvId());
        m.put("createdAt", store.getCreatedAt());
        m.put("updatedAt", store.getUpdatedAt());
        m.put("adressDetail", store.getAdressDetail());
        m.put("zipCd", store.getZipCd());
        m.put("brandCd", store.getBrandCd());
        m.put("brandNm", toCodeName(store.getBrandCd(), store.getBrandNm()));
        m.put("contStartDt", store.getContStartDt());
        m.put("businessNumber", store.getBusinessNumber());
        m.put("firstContDt", store.getFirstContDt());
        m.put("frFee", store.getFrFee());
        m.put("eduFee", store.getEduFee());
        m.put("insuDeposit", store.getInsuDeposit());
        m.put("contDeposit", store.getContDeposit());
        m.put("contManager", store.getContManager());
        m.put("eduManager", store.getEduManager());
        m.put("contArea", store.getContArea());
        m.put("realArea", store.getRealArea());
        m.put("floor", store.getFloor());
        m.put("parkingCount", store.getParkingCount());
        m.put("premiumFee", store.getPremiumFee());
        m.put("monthlyRent", store.getMonthlyRent());
        m.put("rentDeposit", store.getRentDeposit());
        m.put("notes", store.getNotes());
        return m;
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
    public Map<String, Object> createStore(Map<String, Object> body) {
        Integer reqStoreIdx = RequestMapUtil.optInt(body, "storeIdx");
        if (reqStoreIdx != null && storeRepository.findByStoreIdx(reqStoreIdx).isPresent()) {
            throw new IllegalArgumentException("이미 존재하는 가맹점 인덱스입니다: " + reqStoreIdx);
        }

        Boolean autoRenewalYn = RequestMapUtil.optBool(body, "autoRenewalYn");
        Store store = Store.builder()
                .storeCd(RequestMapUtil.optStr(body, "storeCd"))
                .storeIdx(reqStoreIdx)
                .storeNm(RequestMapUtil.reqStr(body, "storeNm"))
                .ownerNm(RequestMapUtil.optStr(body, "ownerNm"))
                .regionCd(RequestMapUtil.optStr(body, "regionCd"))
                .storeTel(RequestMapUtil.optStr(body, "storeTel"))
                .address(RequestMapUtil.optStr(body, "address"))
                .latitude(RequestMapUtil.optBigDecimal(body, "latitude"))
                .longitude(RequestMapUtil.optBigDecimal(body, "longitude"))
                .storeStatus(RequestMapUtil.optStr(body, "storeStatus"))
                .contEndDt(RequestMapUtil.optLocalDate(body, "contEndDt"))
                .autoRenewalYn(autoRenewalYn != null ? autoRenewalYn : true)
                .storeType(RequestMapUtil.optStr(body, "storeType"))
                .svId(RequestMapUtil.optStr(body, "svId"))
                .adressDetail(RequestMapUtil.optStr(body, "adressDetail"))
                .zipCd(RequestMapUtil.optStr(body, "zipCd"))
                .brandCd(RequestMapUtil.optStr(body, "brandCd"))
                .contStartDt(RequestMapUtil.optLocalDate(body, "contStartDt"))
                .businessNumber(RequestMapUtil.optStr(body, "businessNumber"))
                .firstContDt(RequestMapUtil.optLocalDate(body, "firstContDt"))
                .frFee(RequestMapUtil.optBigDecimal(body, "frFee"))
                .eduFee(RequestMapUtil.optBigDecimal(body, "eduFee"))
                .insuDeposit(RequestMapUtil.optBigDecimal(body, "insuDeposit"))
                .contDeposit(RequestMapUtil.optBigDecimal(body, "contDeposit"))
                .contManager(RequestMapUtil.optStr(body, "contManager"))
                .eduManager(RequestMapUtil.optStr(body, "eduManager"))
                .contArea(RequestMapUtil.optBigDecimal(body, "contArea"))
                .realArea(RequestMapUtil.optBigDecimal(body, "realArea"))
                .floor(RequestMapUtil.optInt(body, "floor"))
                .parkingCount(RequestMapUtil.optInt(body, "parkingCount"))
                .premiumFee(RequestMapUtil.optInt(body, "premiumFee"))
                .monthlyRent(RequestMapUtil.optInt(body, "monthlyRent"))
                .rentDeposit(RequestMapUtil.optInt(body, "rentDeposit"))
                .notes(RequestMapUtil.optStr(body, "notes"))
                .build();
        Store savedStore = storeRepository.saveAndFlush(store);
        entityManager.refresh(savedStore);
        saveHistory(savedStore.getStoreIdx(), "INSERT", savedStore.getStoreNm(),
                String.format("가맹점 신규 생성: %s", savedStore.getStoreNm()));

        log.info("가맹점 생성 완료: {}", savedStore.getStoreIdx());
        return toStoreMap(savedStore);
    }

    @Transactional
    public Map<String, Object> updateStore(Integer storeIdx, Map<String, Object> body) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));

        // 변경 이력 추적을 위한 변경 내역 수집
        List<FieldChange> changes = new ArrayList<>();

        String storeNm = RequestMapUtil.optStr(body, "storeNm");
        if (storeNm != null && !storeNm.equals(store.getStoreNm())) {
            changes.add(new FieldChange("storeNm", "가맹점명", store.getStoreNm(), storeNm));
            store.setStoreNm(storeNm);
        }
        String ownerNm = RequestMapUtil.optStr(body, "ownerNm");
        if (ownerNm != null && !ownerNm.equals(store.getOwnerNm())) {
            changes.add(new FieldChange("ownerNm", "점주명", store.getOwnerNm(), ownerNm));
            store.setOwnerNm(ownerNm);
        }
        String regionCd = RequestMapUtil.optStr(body, "regionCd");
        if (regionCd != null && !regionCd.equals(store.getRegionCd())) {
            changes.add(new FieldChange("regionCd", "지역", store.getRegionCd(), regionCd));
            store.setRegionCd(regionCd);
        }
        String storeTel = RequestMapUtil.optStr(body, "storeTel");
        if (storeTel != null && !storeTel.equals(store.getStoreTel())) {
            changes.add(new FieldChange("storeTel", "전화번호", store.getStoreTel(), storeTel));
            store.setStoreTel(storeTel);
        }
        String address = RequestMapUtil.optStr(body, "address");
        if (address != null && !address.equals(store.getAddress())) {
            changes.add(new FieldChange("address", "주소", store.getAddress(), address));
            store.setAddress(address);
        }
        BigDecimal latitude = RequestMapUtil.optBigDecimal(body, "latitude");
        if (latitude != null) {
            boolean changed = store.getLatitude() == null ||
                    latitude.compareTo(store.getLatitude()) != 0;
            if (changed) {
                changes.add(new FieldChange("latitude", "위도",
                        store.getLatitude() != null ? store.getLatitude().toPlainString() : null,
                        latitude.toPlainString()));
                store.setLatitude(latitude);
            }
        }
        BigDecimal longitude = RequestMapUtil.optBigDecimal(body, "longitude");
        if (longitude != null) {
            boolean changed = store.getLongitude() == null ||
                    longitude.compareTo(store.getLongitude()) != 0;
            if (changed) {
                changes.add(new FieldChange("longitude", "경도",
                        store.getLongitude() != null ? store.getLongitude().toPlainString() : null,
                        longitude.toPlainString()));
                store.setLongitude(longitude);
            }
        }
        String storeStatus = RequestMapUtil.optStr(body, "storeStatus");
        if (storeStatus != null && !storeStatus.equals(store.getStoreStatus())) {
            changes.add(new FieldChange("storeStatus", "계약상태", store.getStoreStatus(), storeStatus));
            store.setStoreStatus(storeStatus);
        }
        var contEndDt = RequestMapUtil.optLocalDate(body, "contEndDt");
        if (contEndDt != null && !contEndDt.equals(store.getContEndDt())) {
            changes.add(new FieldChange("contEndDt", "계약종료일",
                    store.getContEndDt() != null ? store.getContEndDt().toString() : null,
                    contEndDt.toString()));
            store.setContEndDt(contEndDt);
        }
        Boolean autoRenewalYn = RequestMapUtil.optBool(body, "autoRenewalYn");
        if (autoRenewalYn != null && !autoRenewalYn.equals(store.getAutoRenewalYn())) {
            changes.add(new FieldChange("autoRenewalYn", "자동갱신여부",
                    store.getAutoRenewalYn() != null ? store.getAutoRenewalYn().toString() : null,
                    autoRenewalYn.toString()));
            store.setAutoRenewalYn(autoRenewalYn);
        }
        String storeType = RequestMapUtil.optStr(body, "storeType");
        if (storeType != null && !storeType.equals(store.getStoreType())) {
            changes.add(new FieldChange("storeType", "가맹점구분", store.getStoreType(), storeType));
            store.setStoreType(storeType);
        }
        String svId = RequestMapUtil.optStr(body, "svId");
        if (svId != null && !svId.equals(store.getSvId())) {
            changes.add(new FieldChange("svId", "수퍼바이저", store.getSvId(), svId));
            store.setSvId(svId);
        }
        String adressDetail = RequestMapUtil.optStr(body, "adressDetail");
        if (adressDetail != null && !adressDetail.equals(store.getAdressDetail())) {
            changes.add(new FieldChange("adressDetail", "상세주소", store.getAdressDetail(), adressDetail));
            store.setAdressDetail(adressDetail);
        }
        String zipCd = RequestMapUtil.optStr(body, "zipCd");
        if (zipCd != null && !zipCd.equals(store.getZipCd())) {
            changes.add(new FieldChange("zipCd", "우편번호", store.getZipCd(), zipCd));
            store.setZipCd(zipCd);
        }
        String brandCd = RequestMapUtil.optStr(body, "brandCd");
        if (brandCd != null && !brandCd.equals(store.getBrandCd())) {
            changes.add(new FieldChange("brandCd", "브랜드", store.getBrandCd(), brandCd));
            store.setBrandCd(brandCd);
        }
        var contStartDt = RequestMapUtil.optLocalDate(body, "contStartDt");
        if (contStartDt != null && !contStartDt.equals(store.getContStartDt())) {
            changes.add(new FieldChange("contStartDt", "계약시작일",
                    store.getContStartDt() != null ? store.getContStartDt().toString() : null,
                    contStartDt.toString()));
            store.setContStartDt(contStartDt);
        }
        String businessNumber = RequestMapUtil.optStr(body, "businessNumber");
        if (businessNumber != null && !businessNumber.equals(store.getBusinessNumber())) {
            changes.add(new FieldChange("businessNumber", "사업자번호", store.getBusinessNumber(), businessNumber));
            store.setBusinessNumber(businessNumber);
        }
        String notes = RequestMapUtil.optStr(body, "notes");
        if (notes != null && !notes.equals(store.getNotes())) {
            changes.add(new FieldChange("notes", "비고", store.getNotes(), notes));
            store.setNotes(notes);
        }
        var firstContDt = RequestMapUtil.optLocalDate(body, "firstContDt");
        if (firstContDt != null && !firstContDt.equals(store.getFirstContDt())) {
            changes.add(new FieldChange("firstContDt", "최초계약일",
                    store.getFirstContDt() != null ? store.getFirstContDt().toString() : null,
                    firstContDt.toString()));
            store.setFirstContDt(firstContDt);
        }
        BigDecimal frFee = RequestMapUtil.optBigDecimal(body, "frFee");
        if (frFee != null) {
            boolean changed = store.getFrFee() == null ||
                    frFee.compareTo(store.getFrFee()) != 0;
            if (changed) {
                changes.add(new FieldChange("frFee", "가맹비",
                        store.getFrFee() != null ? store.getFrFee().toPlainString() : null,
                        frFee.toPlainString()));
                store.setFrFee(frFee);
            }
        }
        BigDecimal eduFee = RequestMapUtil.optBigDecimal(body, "eduFee");
        if (eduFee != null) {
            boolean changed = store.getEduFee() == null ||
                    eduFee.compareTo(store.getEduFee()) != 0;
            if (changed) {
                changes.add(new FieldChange("eduFee", "교육비",
                        store.getEduFee() != null ? store.getEduFee().toPlainString() : null,
                        eduFee.toPlainString()));
                store.setEduFee(eduFee);
            }
        }
        BigDecimal insuDeposit = RequestMapUtil.optBigDecimal(body, "insuDeposit");
        if (insuDeposit != null) {
            boolean changed = store.getInsuDeposit() == null ||
                    insuDeposit.compareTo(store.getInsuDeposit()) != 0;
            if (changed) {
                changes.add(new FieldChange("insuDeposit", "보증보험료",
                        store.getInsuDeposit() != null ? store.getInsuDeposit().toPlainString() : null,
                        insuDeposit.toPlainString()));
                store.setInsuDeposit(insuDeposit);
            }
        }
        BigDecimal contDeposit = RequestMapUtil.optBigDecimal(body, "contDeposit");
        if (contDeposit != null) {
            boolean changed = store.getContDeposit() == null ||
                    contDeposit.compareTo(store.getContDeposit()) != 0;
            if (changed) {
                changes.add(new FieldChange("contDeposit", "계약금",
                        store.getContDeposit() != null ? store.getContDeposit().toPlainString() : null,
                        contDeposit.toPlainString()));
                store.setContDeposit(contDeposit);
            }
        }
        String contManager = RequestMapUtil.optStr(body, "contManager");
        if (contManager != null && !contManager.equals(store.getContManager())) {
            changes.add(new FieldChange("contManager", "계약담당자", store.getContManager(), contManager));
            store.setContManager(contManager);
        }
        String eduManager = RequestMapUtil.optStr(body, "eduManager");
        if (eduManager != null && !eduManager.equals(store.getEduManager())) {
            changes.add(new FieldChange("eduManager", "교육담당자", store.getEduManager(), eduManager));
            store.setEduManager(eduManager);
        }
        BigDecimal contArea = RequestMapUtil.optBigDecimal(body, "contArea");
        if (contArea != null) {
            boolean changed = store.getContArea() == null ||
                    contArea.compareTo(store.getContArea()) != 0;
            if (changed) {
                changes.add(new FieldChange("contArea", "계약면적",
                        store.getContArea() != null ? store.getContArea().toPlainString() : null,
                        contArea.toPlainString()));
                store.setContArea(contArea);
            }
        }
        BigDecimal realArea = RequestMapUtil.optBigDecimal(body, "realArea");
        if (realArea != null) {
            boolean changed = store.getRealArea() == null ||
                    realArea.compareTo(store.getRealArea()) != 0;
            if (changed) {
                changes.add(new FieldChange("realArea", "실사용면적",
                        store.getRealArea() != null ? store.getRealArea().toPlainString() : null,
                        realArea.toPlainString()));
                store.setRealArea(realArea);
            }
        }
        Integer floor = RequestMapUtil.optInt(body, "floor");
        if (floor != null && !floor.equals(store.getFloor())) {
            changes.add(new FieldChange("floor", "층수",
                    store.getFloor() != null ? store.getFloor().toString() : null,
                    floor.toString()));
            store.setFloor(floor);
        }
        Integer parkingCount = RequestMapUtil.optInt(body, "parkingCount");
        if (parkingCount != null && !parkingCount.equals(store.getParkingCount())) {
            changes.add(new FieldChange("parkingCount", "주차대수",
                    store.getParkingCount() != null ? store.getParkingCount().toString() : null,
                    parkingCount.toString()));
            store.setParkingCount(parkingCount);
        }
        Integer premiumFee = RequestMapUtil.optInt(body, "premiumFee");
        if (premiumFee != null && !premiumFee.equals(store.getPremiumFee())) {
            changes.add(new FieldChange("premiumFee", "권리금",
                    store.getPremiumFee() != null ? store.getPremiumFee().toString() : null,
                    premiumFee.toString()));
            store.setPremiumFee(premiumFee);
        }
        Integer monthlyRent = RequestMapUtil.optInt(body, "monthlyRent");
        if (monthlyRent != null && !monthlyRent.equals(store.getMonthlyRent())) {
            changes.add(new FieldChange("monthlyRent", "월세",
                    store.getMonthlyRent() != null ? store.getMonthlyRent().toString() : null,
                    monthlyRent.toString()));
            store.setMonthlyRent(monthlyRent);
        }
        Integer rentDeposit = RequestMapUtil.optInt(body, "rentDeposit");
        if (rentDeposit != null && !rentDeposit.equals(store.getRentDeposit())) {
            changes.add(new FieldChange("rentDeposit", "보증금",
                    store.getRentDeposit() != null ? store.getRentDeposit().toString() : null,
                    rentDeposit.toString()));
            store.setRentDeposit(rentDeposit);
        }

        Store updatedStore = storeRepository.save(store);
        
        // 변경 사항이 있을 때만 히스토리 저장
        if (!changes.isEmpty()) {
            saveHistoryWithChanges(updatedStore.getStoreIdx(), updatedStore.getStoreNm(), changes);
        }
        
        log.info("가맹점 수정 완료: {}", updatedStore.getStoreCd());
        return toStoreMap(updatedStore);
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

    public List<Map<String, Object>> searchStoresByName(String storeNm) {
        return storeRepository.findByStoreNmContaining(storeNm)
                .stream()
                .map(this::toStoreMap)
                .collect(Collectors.toList());
    }
}
