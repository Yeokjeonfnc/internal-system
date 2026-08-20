package com.yeokjeon.erp.franchise.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.development.dto.PartnerMstWriteRequestDto;
import com.yeokjeon.erp.development.service.DevService;
import com.yeokjeon.erp.franchise.dto.StoreDeleteBlockerRow;
import com.yeokjeon.erp.franchise.dto.StoreHistoryRowDto;
import com.yeokjeon.erp.franchise.dto.StoreMstDto;
import com.yeokjeon.erp.franchise.dto.StoreMstWriteRequestDto;
import com.yeokjeon.erp.franchise.entity.Store;
import com.yeokjeon.erp.franchise.mapper.StoreHistoryMapper;
import com.yeokjeon.erp.franchise.mapper.StoreMstMapper;
import com.yeokjeon.erp.franchise.repository.StoreRepository;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StrService {

    private final StoreRepository storeRepository;
    private final StoreMstMapper storeMstMapper;
    private final EntityManager entityManager;
    private final StoreHistoryMapper storeHistoryMapper;
    private final ObjectMapper objectMapper;
    private final DevService devService;

    public List<StoreMstDto> list() {
        return storeMstMapper.selectStoreListOrdered();
    }

    public StoreMstDto one(Integer storeIdx) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        return StoreMstDto.fromEntity(store);
    }

    public List<StoreHistoryRowDto> listHistories(Integer storeIdx) {
        storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        return storeHistoryMapper.selectHistoriesByStoreIdx(storeIdx).stream()
                .map(row -> new StoreHistoryRowDto(
                        row.hisIdx(),
                        row.storeIdx(),
                        row.chgType(),
                        row.storeNm(),
                        toJsonNode(row.chgContentRaw()),
                        toHistoryContent(row.chgType(), row.storeNm(), row.chgContentRaw()),
                        row.chgUserId(),
                        row.chgDt()))
                .collect(Collectors.toList());
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

        if ("active".equalsIgnoreCase(chgType)) {
            return activeHistoryDisplayText(chgContent);
        }

        // UPDATE — API content 필드는 기존 문구 유지(화면 표시는 클라이언트에서 chg_content 파싱)
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
                        return storeName + ": " + columns + " 정보 수정";
                    }
                }
            } catch (JsonProcessingException e) {
                log.warn("히스토리 내용 파싱 실패: {}", chgContent, e);
            }
        }

        // 기본 처리
        String action = "가맹점";
        if (storeNm != null && !storeNm.isBlank()) {
            return storeNm + ": " + action;
        }
        return action;
    }

    private String activeHistoryDisplayText(String chgContent) {
        if (chgContent == null || chgContent.isBlank()) {
            return "";
        }
        try {
            JsonNode node = objectMapper.readTree(chgContent);
            if (node.isTextual()) {
                return node.asText();
            }
        } catch (JsonProcessingException e) {
            log.warn("활동 히스토리 내용 파싱 실패: {}", chgContent, e);
        }
        return chgContent.trim();
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
    public StoreMstDto create(StoreMstWriteRequestDto body, String callerId) {

        Integer reqStoreIdx = body.storeIdx();
        if (reqStoreIdx != null && storeRepository.findByStoreIdx(reqStoreIdx).isPresent()) {
            throw new IllegalArgumentException("이미 존재하는 가맹점 인덱스입니다: " + reqStoreIdx);
        }

        if (body.storeNm() == null || body.storeNm().isBlank()) {
            throw new IllegalArgumentException("가맹점명을 입력해주세요.");
        }
        if (body.svId() == null || body.svId().isBlank()) {
            throw new IllegalArgumentException("담당수퍼바이저를 입력해주세요.");
        }
        if (body.contManager() == null || body.contManager().isBlank()) {
            throw new IllegalArgumentException("가맹계약 담당자를 입력해주세요.");
        }

        String storeNmRequired = body.storeNm().trim();
        if (storeMstMapper.countStoreNmDuplicate(storeNmRequired) > 0) {
            throw new IllegalArgumentException("중복된 가맹점명입니다.");
        }

        Boolean autoRenewalYn = body.autoRenewalYn();
        String addressRaw = body.address();
        String zipRaw = body.zipCd();
        if (addressRaw != null && !addressRaw.isBlank()) {
            String addrNorm = addressRaw.trim();
            String zipNorm = zipRaw == null || zipRaw.isBlank() ? "" : zipRaw.trim();
            if (storeMstMapper.countAddressDuplicate(addrNorm, zipNorm) > 0) {
                throw new IllegalArgumentException("중복된 주소입니다. (동일한 우편번호·주소)");
            }
        }

        Store store = Store.builder()
                .storeCd(body.storeCd())
                .storeIdx(reqStoreIdx)
                .storeNm(storeNmRequired)
                .ownerNm(body.ownerNm())
                .regionCd(body.regionCd())
                .storeTel(body.storeTel())
                .address(body.address())
                .latitude(body.latitude())
                .longitude(body.longitude())
                .storeStatus(body.storeStatus())
                .closedYn(closedYnFromStatus(body.storeStatus()))
                .contEndDt(body.contEndDt())
                .autoRenewalYn(autoRenewalYn != null ? autoRenewalYn : true)
                .storeType(body.storeType())
                .svId(body.svId())
                .adressDetail(body.adressDetail())
                .zipCd(body.zipCd())
                .brandCd(body.brandCd())
                .contStartDt(body.contStartDt())
                .businessNumber(body.businessNumber())
                .firstContDt(body.firstContDt())
                .transferDate(body.transferDate())
                .frFee(body.frFee())
                .eduFee(body.eduFee())
                .insuDeposit(body.insuDeposit())
                .contDeposit(body.contDeposit())
                .contManager(body.contManager())
                .eduManager(body.eduManager())
                .contArea(body.contArea())
                .realArea(body.realArea())
                .floor(body.floor())
                .parkingCount(body.parkingCount())
                .premiumFee(body.premiumFee())
                .monthlyRent(body.monthlyRent())
                .rentDeposit(body.rentDeposit())
                .notes(body.notes())
                .propIdx(body.propIdx())
                .partnerIdx(body.partnerIdx())
                .build();
                
        Store savedStore = storeRepository.saveAndFlush(store);
        entityManager.refresh(savedStore);
        saveHistory(savedStore.getStoreIdx(), "INSERT", callerId, savedStore.getStoreNm(),
                String.format("가맹점 신규 생성: %s", savedStore.getStoreNm()));

        Integer partnerIdx = body.partnerIdx();
        if (partnerIdx != null && partnerIdx > 0) {
            devService.updatePartnerStatus(partnerIdx);
            log.info("예비창업자 {} 상태를 가맹점사업자로 반영", partnerIdx);
            devService.updatePropertyStatus(body.propIdx());
            log.info("물건 {} 상태를 가맹점으로 반영", body.propIdx());
            
        }

        log.info("가맹점 생성 완료: {}", savedStore.getStoreIdx());
        return StoreMstDto.fromEntity(savedStore);
    }

    @Transactional
    public StoreMstDto update(Integer storeIdx, StoreMstWriteRequestDto body, String callerId) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));

        // 수정 시 가맹점명·주소가 바뀌지 않았으면 중복 검사 생략(다른 필드만 저장 가능).
        final String originalStoreNmNorm = normalizeStoreNm(store.getStoreNm());
        final String originalAddressNorm = normalizeAddress(store.getAddress());
        final String originalZipNorm = normalizeZipCd(store.getZipCd());

        // 변경 이력 추적을 위한 변경 내역 수집
        List<FieldChange> changes = new ArrayList<>();

        String storeNm = body.storeNm();
        if (storeNm != null && !normalizeStoreNm(storeNm).equals(originalStoreNmNorm)) {
            changes.add(new FieldChange("storeNm", "가맹점명", store.getStoreNm(), storeNm));
            store.setStoreNm(storeNm);
        }
        String storeCd = body.storeCd();
        if (storeCd != null && !storeCd.equals(store.getStoreCd())) {
            changes.add(new FieldChange("storeCd", "가맹점코드", store.getStoreCd(), storeCd));
            store.setStoreCd(storeCd.trim().isEmpty() ? null : storeCd.trim());
        }
        String ownerNm = body.ownerNm();
        if (ownerNm != null && !ownerNm.equals(store.getOwnerNm())) {
            changes.add(new FieldChange("ownerNm", "점주명", store.getOwnerNm(), ownerNm));
            store.setOwnerNm(ownerNm);
        }
        String regionCd = body.regionCd();
        if (regionCd != null && !regionCd.equals(store.getRegionCd())) {
            changes.add(new FieldChange("regionCd", "지역", store.getRegionCd(), regionCd));
            store.setRegionCd(regionCd);
        }
        String storeTel = body.storeTel();
        if (storeTel != null && !storeTel.equals(store.getStoreTel())) {
            changes.add(new FieldChange("storeTel", "전화번호", store.getStoreTel(), storeTel));
            store.setStoreTel(storeTel);
        }
        String address = body.address();
        if (address != null && !address.equals(store.getAddress())) {
            changes.add(new FieldChange("address", "주소", store.getAddress(), address));
            store.setAddress(address);
        }
        BigDecimal latitude = body.latitude();
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
        BigDecimal longitude = body.longitude();
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
        String storeStatus = body.storeStatus();
        if (storeStatus != null && !storeStatus.equals(store.getStoreStatus())) {
            changes.add(new FieldChange("storeStatus", "계약상태", store.getStoreStatus(), storeStatus));
            store.setStoreStatus(storeStatus);
            String nextClosedYn = closedYnFromStatus(storeStatus);
            if (!Objects.equals(nextClosedYn, store.getClosedYn())) {
                changes.add(new FieldChange(
                        "closedYn",
                        "폐점여부",
                        store.getClosedYn(),
                        nextClosedYn));
                store.setClosedYn(nextClosedYn);
            }
        }
        var contEndDt = body.contEndDt();
        if (contEndDt != null && !contEndDt.equals(store.getContEndDt())) {
            changes.add(new FieldChange("contEndDt", "계약종료일",
                    store.getContEndDt() != null ? store.getContEndDt().toString() : null,
                    contEndDt.toString()));
            store.setContEndDt(contEndDt);
        }
        Boolean autoRenewalYn = body.autoRenewalYn();
        if (autoRenewalYn != null && !autoRenewalYn.equals(store.getAutoRenewalYn())) {
            changes.add(new FieldChange("autoRenewalYn", "자동갱신여부",
                    store.getAutoRenewalYn() != null ? store.getAutoRenewalYn().toString() : null,
                    autoRenewalYn.toString()));
            store.setAutoRenewalYn(autoRenewalYn);
        }
        String storeType = body.storeType();
        if (storeType != null && !storeType.equals(store.getStoreType())) {
            changes.add(new FieldChange("storeType", "가맹점구분", store.getStoreType(), storeType));
            store.setStoreType(storeType);
        }
        String svId = body.svId();
        if (svId != null && !svId.equals(store.getSvId())) {
            changes.add(new FieldChange("svId", "수퍼바이저", store.getSvId(), svId));
            store.setSvId(svId);
        }
        String adressDetail = body.adressDetail();
        if (adressDetail != null && !adressDetail.equals(store.getAdressDetail())) {
            changes.add(new FieldChange("adressDetail", "상세주소", store.getAdressDetail(), adressDetail));
            store.setAdressDetail(adressDetail);
        }
        String zipCd = body.zipCd();
        if (zipCd != null && !zipCd.equals(store.getZipCd())) {
            changes.add(new FieldChange("zipCd", "우편번호", store.getZipCd(), zipCd));
            store.setZipCd(zipCd);
        }
        String brandCd = body.brandCd();
        if (brandCd != null && !brandCd.equals(store.getBrandCd())) {
            changes.add(new FieldChange("brandCd", "브랜드", store.getBrandCd(), brandCd));
            store.setBrandCd(brandCd);
        }
        var contStartDt = body.contStartDt();
        if (contStartDt != null && !contStartDt.equals(store.getContStartDt())) {
            changes.add(new FieldChange("contStartDt", "계약시작일",
                    store.getContStartDt() != null ? store.getContStartDt().toString() : null,
                    contStartDt.toString()));
            store.setContStartDt(contStartDt);
        }
        var transferDate = body.transferDate();
        if (transferDate != null && !transferDate.equals(store.getTransferDate())) {
            changes.add(new FieldChange("transferDate", "양수도 계약일자",
                    store.getTransferDate() != null ? store.getTransferDate().toString() : null,
                    transferDate.toString()));
            store.setTransferDate(transferDate);
        }
        String businessNumber = body.businessNumber();
        if (businessNumber != null && !businessNumber.equals(store.getBusinessNumber())) {
            changes.add(new FieldChange("businessNumber", "사업자번호", store.getBusinessNumber(), businessNumber));
            store.setBusinessNumber(businessNumber);
        }
        String notes = body.notes();
        if (notes != null && !notes.equals(store.getNotes())) {
            changes.add(new FieldChange("notes", "비고", store.getNotes(), notes));
            store.setNotes(notes);
        }
        BigDecimal frFee = body.frFee();
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
        BigDecimal eduFee = body.eduFee();
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
        BigDecimal insuDeposit = body.insuDeposit();
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
        BigDecimal contDeposit = body.contDeposit();
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
        String contManager = body.contManager();
        if (contManager != null && !contManager.equals(store.getContManager())) {
            changes.add(new FieldChange("contManager", "계약담당자", store.getContManager(), contManager));
            store.setContManager(contManager);
        }
        String eduManager = body.eduManager();
        if (eduManager != null && !eduManager.equals(store.getEduManager())) {
            changes.add(new FieldChange("eduManager", "교육담당자", store.getEduManager(), eduManager));
            store.setEduManager(eduManager);
        }
        BigDecimal contArea = body.contArea();
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
        BigDecimal realArea = body.realArea();
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
        Integer floor = body.floor();
        if (floor != null && !floor.equals(store.getFloor())) {
            changes.add(new FieldChange("floor", "층수",
                    store.getFloor() != null ? store.getFloor().toString() : null,
                    floor.toString()));
            store.setFloor(floor);
        }
        Integer parkingCount = body.parkingCount();
        if (parkingCount != null && !parkingCount.equals(store.getParkingCount())) {
            changes.add(new FieldChange("parkingCount", "주차대수",
                    store.getParkingCount() != null ? store.getParkingCount().toString() : null,
                    parkingCount.toString()));
            store.setParkingCount(parkingCount);
        }
        Integer premiumFee = body.premiumFee();
        if (premiumFee != null && !premiumFee.equals(store.getPremiumFee())) {
            changes.add(new FieldChange("premiumFee", "권리금",
                    store.getPremiumFee() != null ? store.getPremiumFee().toString() : null,
                    premiumFee.toString()));
            store.setPremiumFee(premiumFee);
        }
        Integer monthlyRent = body.monthlyRent();
        if (monthlyRent != null && !monthlyRent.equals(store.getMonthlyRent())) {
            changes.add(new FieldChange("monthlyRent", "월세",
                    store.getMonthlyRent() != null ? store.getMonthlyRent().toString() : null,
                    monthlyRent.toString()));
            store.setMonthlyRent(monthlyRent);
        }
        Integer rentDeposit = body.rentDeposit();
        if (rentDeposit != null && !rentDeposit.equals(store.getRentDeposit())) {
            changes.add(new FieldChange("rentDeposit", "보증금",
                    store.getRentDeposit() != null ? store.getRentDeposit().toString() : null,
                    rentDeposit.toString()));
            store.setRentDeposit(rentDeposit);
        }
        Integer propIdx = body.propIdx();
        if (propIdx != null && !Objects.equals(propIdx, store.getPropIdx())) {
            changes.add(new FieldChange("propIdx", "물건",
                    store.getPropIdx() != null ? store.getPropIdx().toString() : null,
                    propIdx.toString()));
            store.setPropIdx(propIdx);
        }
        // partnerIdx는 등록(POST) 시에만 반영 — 수정 요청 본문의 partnerIdx는 무시한다.

        // 저장 직전 중복 검사 — 가맹점명·주소가 실제로 변경된 경우에만(현재 행 제외)
        final String effectiveStoreNmNorm = normalizeStoreNm(store.getStoreNm());
        if (!effectiveStoreNmNorm.isBlank()
                && !effectiveStoreNmNorm.equals(originalStoreNmNorm)
                && storeMstMapper.countStoreNmDuplicateExclude(store.getStoreNm().trim(), storeIdx) > 0) {
            throw new IllegalArgumentException("중복된 가맹점명입니다.");
        }
        String effAddr = store.getAddress() != null ? store.getAddress().trim() : "";
        String effZip = store.getZipCd() != null ? store.getZipCd().trim() : "";
        final boolean addressChanged = !normalizeAddress(effAddr).equals(originalAddressNorm)
                || !normalizeZipCd(effZip).equals(originalZipNorm);
        if (!effAddr.isBlank() && addressChanged
                && storeMstMapper.countAddressDuplicateExclude(effAddr, effZip, storeIdx) > 0) {
            throw new IllegalArgumentException("중복된 주소입니다. (동일한 우편번호·주소)");
        }

        Store updatedStore = storeRepository.save(store);
        
        // 변경 사항이 있을 때만 히스토리 저장
        if (!changes.isEmpty()) {
            saveHistoryWithChanges(
                    updatedStore.getStoreIdx(), updatedStore.getStoreNm(), changes, callerId);
        }
        
        log.info("가맹점 수정 완료: {}", updatedStore.getStoreCd());
        return StoreMstDto.fromEntity(updatedStore);
    }

    @Transactional
    public void remove(Integer storeIdx, String callerId) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));

        /*
         * store_mst 를 참조하는 FK 중 ON DELETE 절이 없는 것이 넷이라, 그냥 지우면
         * 23503 이 나고 화면에는 사유가 가려진 오류만 뜬다. 무엇이 막고 있는지
         * 미리 세어 사용자가 스스로 정리할 수 있게 알려준다.
         */
        String blocked = describeDeleteBlockers(storeIdx);
        if (blocked != null) {
            throw new IllegalStateException(blocked);
        }
        /*
         * store_history 는 가맹점이 사라져도 남아야 하는 감사 기록이라 FK 가 있으면
         * 안 된다. 예전에는 삭제할 때마다 ALTER TABLE 로 떼어냈지만 그건 사용자 조작이
         * 운영 스키마를 바꾸는 것이고, 앱 DB 계정이 테이블 소유자가 아니면 삭제 자체가
         * 실패했다. 이제는 마이그레이션으로 한 번만 정리하고, 여기서는 적용 여부만 본다.
         */
        if (storeHistoryFkStillPresent()) {
            throw new IllegalStateException(
                    "가맹점 삭제 준비가 되지 않았습니다. "
                            + "변경 이력 제약(store_history.fk_his_store_idx)이 남아 있어 "
                            + "삭제하면 이력까지 함께 막힙니다. 관리자에게 문의해 주세요.");
        }

        saveHistory(store.getStoreIdx(), "DELETE", callerId, store.getStoreNm(),
                String.format("가맹점 삭제: %s", store.getStoreNm()));
        storeRepository.delete(store);
        log.info("가맹점 삭제 완료: {} (요청자 {})", storeIdx, callerId);
    }

    /** 삭제를 막는 참조가 있으면 사용자에게 보여줄 사유, 없으면 null. */
    private String describeDeleteBlockers(Integer storeIdx) {
        StoreDeleteBlockerRow blockers = storeMstMapper.countDeleteBlockers(storeIdx);
        if (blockers == null) {
            return null;
        }
        List<String> reasons = new ArrayList<>();
        appendBlocker(reasons, "가맹점주 계정", blockers.ownerUserCnt());
        appendBlocker(reasons, "NFC 태그", blockers.nfcTagCnt());
        appendBlocker(reasons, "게시글", blockers.bbsPostCnt());
        appendBlocker(reasons, "활동계획", blockers.planStoreCnt());
        if (reasons.isEmpty()) {
            return null;
        }
        return "연결된 " + String.join(", ", reasons) + "이(가) 있어 삭제할 수 없습니다. "
                + "해당 항목을 먼저 정리한 뒤 다시 시도해 주세요.";
    }

    private static void appendBlocker(List<String> reasons, String label, Integer count) {
        if (count != null && count > 0) {
            reasons.add(label + " " + count + "건");
        }
    }

    /** 마이그레이션 미적용 DB 방어 — 메타데이터 조회가 막혀도 삭제를 멈추진 않는다. */
    private boolean storeHistoryFkStillPresent() {
        try {
            return storeHistoryMapper.existsStoreHistoryFk();
        } catch (RuntimeException e) {
            log.warn("store_history FK 확인 실패 — 삭제는 그대로 진행한다", e);
            return false;
        }
    }

    private void saveHistoryWithChanges(
            Integer storeIdx, String storeNm, List<FieldChange> changes, String callerId) {
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

        storeHistoryMapper.insertHistoryUpdateJson(
                storeIdx, historyUserId(callerId), storeNm, jsonBuilder.toString());
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

    /** DB 중복 검사와 동일 — TRIM + LOWER */
    private static String normalizeStoreNm(String nm) {
        if (nm == null) {
            return "";
        }
        return nm.trim().toLowerCase();
    }

    private static String normalizeAddress(String addr) {
        if (addr == null) {
            return "";
        }
        return addr.trim().toLowerCase();
    }

    private static String normalizeZipCd(String zip) {
        if (zip == null) {
            return "";
        }
        return zip.trim();
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

    private void saveHistory(
            Integer storeIdx, String chgType, String callerId, String storeNm, String content) {
        if (storeIdx == null) {
            log.warn("가맹점 히스토리 저장 건너뜀: storeIdx 없음, chgType={}, content={}", chgType, content);
            return;
        }
        storeHistoryMapper.insertHistorySimple(
                storeIdx, chgType, historyUserId(callerId), storeNm, content);
    }

    /**
     * 이력의 '수정자'. 호출자를 알 수 없을 때만 기존과 같이 'system' 으로 남긴다 —
     * 값이 비면 누가 고쳤는지 화면에 아예 안 나오고 감사 자료로 못 쓴다.
     */
    private static String historyUserId(String callerId) {
        return callerId == null || callerId.isBlank() ? "system" : callerId;
    }

    public List<StoreMstDto> listByStoreName(String storeNm) {
        if (storeNm == null || storeNm.isBlank()) {
            return List.of();
        }
        return storeMstMapper.selectStoresByStoreNmLike("%" + storeNm + "%");
    }

    /** 계약상태 `closed` 이면 폐점(Y), 그 외 N. */
    private static String closedYnFromStatus(String storeStatus) {
        if (storeStatus == null) {
            return "N";
        }
        return "closed".equalsIgnoreCase(storeStatus.trim()) ? "Y" : "N";
    }
}
