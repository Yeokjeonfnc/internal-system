package com.yeokjeon.erp.development.service;

import com.yeokjeon.erp.development.dto.PartnerMstDto;
import com.yeokjeon.erp.development.dto.PartnerMstWriteRequestDto;
import com.yeokjeon.erp.development.dto.PropertyMstDto;
import com.yeokjeon.erp.development.dto.PropertyMstWriteRequestDto;
import com.yeokjeon.erp.development.dto.SalesAreaDto;
import com.yeokjeon.erp.development.dto.SalesAreaMapPointDto;
import com.yeokjeon.erp.development.dto.SalesAreaSaveRequest;
import com.yeokjeon.erp.development.dto.SalesAreaZoneInfoSaveRequest;
import com.yeokjeon.erp.development.util.GeometryJson;
import com.yeokjeon.erp.development.entity.Partner;
import com.yeokjeon.erp.development.entity.Property;
import com.yeokjeon.erp.development.mapper.DevMstMapper;
import com.yeokjeon.erp.development.repository.PartnerRepository;
import com.yeokjeon.erp.development.repository.PropertyRepository;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DevService {

    /** DB/API 문자열 — 앱 [PartnerStatus.franchisee]·한글 라벨 `가맹점사업자`와 동일. */
    public static final String PARTNER_STATUS_FRANCHISEE = "가맹점사업자";

    private final PartnerRepository partnerRepository;
    private final PropertyRepository propertyRepository;
    private final DevMstMapper devMstMapper;
    private final AddressGeocodingService addressGeocodingService;

    public List<PartnerMstDto> listPartners() {
        return devMstMapper.selectPartnersOrdered();
    }

    public PartnerMstDto onePartner(Integer partnerIdx) {
        Partner partner = partnerRepository.findById(partnerIdx)
                .orElseThrow(() -> new ResourceNotFoundException("예비창업자", "partnerIdx", partnerIdx));
        return PartnerMstDto.fromEntity(partner);
    }

    /**
     * 이메일 사용 가능 여부. 비어 있으면 false.
     * {@code excludePartnerIdx} 는 수정 화면에서 본인 제외용.
     */
    public boolean isPartnerEmailAvailable(String email, Integer excludePartnerIdx) {
        if (!StringUtils.hasText(email)) {
            return false;
        }
        return !partnerRepository.existsDuplicateEmail(email.trim(), excludePartnerIdx);
    }

    @Transactional
    public PartnerMstDto createPartner(PartnerMstWriteRequestDto body) {
        if (body.getPartnerNm() == null || body.getPartnerNm().isBlank()) {
            throw new IllegalArgumentException("partnerNm은(는) 필수입니다.");
        }
        if (body.getPartnerTel() == null || body.getPartnerTel().isBlank()) {
            throw new IllegalArgumentException("partnerTel은(는) 필수입니다.");
        }
        String partnerNm = body.getPartnerNm().trim();
        String partnerTel = body.getPartnerTel().trim();
        String partnerEmail = trimToNull(body.getPartnerEmail());
        assertPartnerEmailUnique(partnerEmail, null);
        Partner partner = Partner.builder()
                .partnerNm(partnerNm)
                .partnerStatus(trimToNull(body.getPartnerStatus()))
                .partnerTel(partnerTel)
                .partnerEmail(partnerEmail)
                .gender(trimToNull(body.getGender()))
                .partnerBirth(body.getPartnerBirth())
                .pZipCd(trimToNull(body.getPZipCd()))
                .pAddress(trimToNull(body.getPAddress()))
                .pAddressDetail(trimToNull(body.getPAddressDetail()))
                .pRegion(trimToNull(body.getPRegion()))
                .build();
        Partner saved = partnerRepository.save(partner);
        log.info("예비창업자 생성 완료: {}", saved.getPartnerIdx());
        return PartnerMstDto.fromEntity(saved);
    }

    /**
     * 예비창업자 상태만 SQL로 갱신 — 가맹점 생성 시 [PARTNER_STATUS_FRANCHISEE] 반영 등.
     *
     * @return 갱신된 행 수(0이면 해당 partner_idx 없음)
     */
    @Transactional
    public int updatePartnerStatus(Integer partnerIdx) {
        if (partnerIdx == null || partnerIdx <= 0) {
            return 0;
        }
        int n = devMstMapper.updatePartnerStatus(partnerIdx);
        if (n == 0) {
            throw new ResourceNotFoundException("예비창업자", "partnerIdx", partnerIdx);
        }
        log.info("예비창업자 partner_status 갱신: partnerIdx={}", partnerIdx);
        return n;
    }

    public int updatePropertyStatus(Integer propIdx) {
        if (propIdx == null || propIdx <= 0) {
            return 0;
        }
        int n = devMstMapper.updatePropertyStatus(propIdx);
        if (n == 0) {
            throw new ResourceNotFoundException("물건", "propIdx", propIdx);
        }
        log.info("물건 prop_status 갱신: propIdx={}", propIdx);
        return n;
    }

    @Transactional
    public PartnerMstDto updatePartner(Integer partnerIdx, PartnerMstWriteRequestDto body) {
        Partner partner = partnerRepository.findById(partnerIdx)
                .orElseThrow(() -> new ResourceNotFoundException("예비창업자", "partnerIdx", partnerIdx));

        if (body == null) {
            throw new IllegalArgumentException("요청 본문이 비어 있습니다.");
        }

        if (body.isPartnerEmailPresent()) {
            assertPartnerEmailUnique(trimToNull(body.getPartnerEmail()), partnerIdx);
        }

        applyPartnerWriteBody(partner, body);

        Partner saved = partnerRepository.save(partner);
        log.info(
                "예비창업자 수정 완료: partnerIdx={}, pRegion={}",
                saved.getPartnerIdx(),
                saved.getPRegion());
        return PartnerMstDto.fromEntity(saved);
    }

    /** 이메일 중복 — 비어 있으면 검사 생략. 수정 시 {@code excludePartnerIdx}로 본인 제외. */
    private void assertPartnerEmailUnique(String email, Integer excludePartnerIdx) {
        if (!StringUtils.hasText(email)) {
            return;
        }
        if (partnerRepository.existsDuplicateEmail(email.trim(), excludePartnerIdx)) {
            throw new IllegalArgumentException("이미 등록된 이메일주소입니다.");
        }
    }

    @Transactional
    public void removePartner(Integer partnerIdx) {
        Partner partner = partnerRepository.findById(partnerIdx)
                .orElseThrow(() -> new ResourceNotFoundException("예비창업자", "partnerIdx", partnerIdx));
        partnerRepository.delete(partner);
        log.info("예비창업자 삭제 완료: {}", partnerIdx);
    }

    public List<PropertyMstDto> listProperties() {
        return devMstMapper.selectPropertiesOrdered();
    }

    /**
     * 영업지역 관리(DEV003) — 가맹점·물건·코드마스터 기준 목록.
     *
     * @see DevMstMapper#selectSalesAreasForList()
     */
    public List<SalesAreaDto> listSalesAreas() {
        try {
            List<SalesAreaDto> rows = devMstMapper.selectSalesAreasForList();
            log.info("영업지역 목록(sale_zone_mst 연동): {}건", rows.size());
            return rows;
        } catch (Exception ex) {
            log.warn("영업지역 sale_zone_mst 조회 실패 — 가맹점 기준 fallback", ex);
            try {
                List<SalesAreaDto> rows = devMstMapper.selectSalesAreasStoresOnly();
                log.info("영업지역 목록(store_mst fallback): {}건", rows.size());
                return rows;
            } catch (Exception fallbackEx) {
                log.error("영업지역 목록 fallback 조회 실패", fallbackEx);
                throw fallbackEx;
            }
        }
    }

    public List<SalesAreaMapPointDto> listSalesAreaMapPoints() {
        return listSalesAreaMapPoints(false);
    }

    public List<SalesAreaMapPointDto> listSalesAreaMapPoints(boolean includeGeometry) {
        try {
            if (includeGeometry) {
                return devMstMapper.selectSalesAreaMapPointsWithGeometry();
            }
            return devMstMapper.selectSalesAreaMapPoints();
        } catch (Exception ex) {
            log.warn("영업지역 지도 포인트 조회 실패: {}", ex.toString());
            return List.of();
        }
    }

    public SalesAreaDto salesAreaDetailByStore(Integer storeIdx) {
        if (storeIdx == null || storeIdx <= 0) {
            throw new IllegalArgumentException("storeIdx는(는) 필수입니다.");
        }
        SalesAreaDto row = devMstMapper.selectSalesAreaDetailByStoreIdx(storeIdx);
        if (row == null) {
            throw new ResourceNotFoundException("가맹점", "storeIdx", storeIdx);
        }
        return row;
    }

    public SalesAreaDto salesAreaDetailByZone(Integer zoneIdx) {
        if (zoneIdx == null || zoneIdx <= 0) {
            throw new IllegalArgumentException("zoneIdx는(는) 필수입니다.");
        }
        SalesAreaDto row = devMstMapper.selectSalesAreaDetailByZoneIdx(zoneIdx);
        if (row == null) {
            throw new ResourceNotFoundException("영업지역", "zoneIdx", zoneIdx);
        }
        return row;
    }

    public SalesAreaDto salesAreaDetailByProperty(Integer propIdx) {
        if (propIdx == null || propIdx <= 0) {
            throw new IllegalArgumentException("propIdx는(는) 필수입니다.");
        }
        propertyRepository
                .findById(propIdx)
                .orElseThrow(() -> new ResourceNotFoundException("물건", "propIdx", propIdx));
        SalesAreaDto row = devMstMapper.selectSalesAreaDetailByPropIdx(propIdx);
        if (row == null) {
            throw new ResourceNotFoundException("물건", "propIdx", propIdx);
        }
        return row;
    }

    @Transactional
    public SalesAreaDto saveSalesArea(SalesAreaSaveRequest req) {
        if (req == null) {
            throw new IllegalArgumentException("요청 본문이 비어 있습니다.");
        }
        if (!StringUtils.hasText(req.zoneNm())) {
            throw new IllegalArgumentException("zoneNm은(는) 필수입니다.");
        }
        String geometryType = req.geometryType().trim().toUpperCase();
        GeometryJson.validate(geometryType, req.geometryData());
        String geometryJson = GeometryJson.toJson(req.geometryData());

        final Integer reqPropIdx = req.propIdx();
        Integer propIdx = reqPropIdx;
        Integer storeIdx = req.storeIdx();
        if (propIdx != null && propIdx > 0) {
            final Integer validatedPropIdx = propIdx;
            propertyRepository
                    .findById(validatedPropIdx)
                    .orElseThrow(() -> new ResourceNotFoundException("물건", "propIdx", validatedPropIdx));
            if (storeIdx == null || storeIdx <= 0) {
                storeIdx = devMstMapper.selectStoreIdxByPropIdx(propIdx);
            }
        } else {
            propIdx = null;
        }

        Integer zoneIdx = req.zoneIdx();
        if (zoneIdx == null || zoneIdx <= 0) {
            if (propIdx != null && propIdx > 0) {
                zoneIdx = devMstMapper.selectZoneIdxByPropIdx(propIdx);
            }
            if ((zoneIdx == null || zoneIdx <= 0) && storeIdx != null && storeIdx > 0) {
                zoneIdx = devMstMapper.selectZoneIdxByStoreIdx(storeIdx);
            }
        }
        String brandCd = StringUtils.hasText(req.brandCd()) ? req.brandCd().trim() : null;

        if (zoneIdx == null || zoneIdx <= 0) {
            Map<String, Object> ins = new HashMap<>();
            ins.put("zoneNm", req.zoneNm().trim());
            ins.put("brandCd", brandCd);
            ins.put("geometryType", geometryType);
            ins.put("geometryDataJson", geometryJson);
            ins.put("useYn", propIdx != null && propIdx > 0);
            devMstMapper.insertSaleZone(ins);
            zoneIdx = (Integer) ins.get("zoneIdx");
            if (zoneIdx == null) {
                throw new IllegalStateException("sale_zone_mst INSERT 후 zone_idx를 받지 못했습니다.");
            }
        } else {
            int updated = devMstMapper.updateSaleZone(
                    zoneIdx,
                    req.zoneNm().trim(),
                    brandCd,
                    geometryType,
                    geometryJson);
            if (updated == 0) {
                throw new IllegalStateException(
                        "sale_zone_mst UPDATE 실패: zoneIdx=" + zoneIdx);
            }
        }

        if (propIdx != null && propIdx > 0) {
            devMstMapper.clearPropertyZoneFromOtherProperties(zoneIdx, propIdx);
            devMstMapper.updatePropertyZoneIdx(propIdx, zoneIdx);
            devMstMapper.updateSaleZoneUseYn(zoneIdx, true);
        } else {
            devMstMapper.updateSaleZoneUseYn(zoneIdx, false);
        }

        log.info(
                "영업지역 저장: zoneIdx={}, storeIdx={}, propIdx={}, geometryType={}",
                zoneIdx,
                storeIdx,
                propIdx,
                geometryType);

        if (storeIdx != null && storeIdx > 0) {
            return salesAreaDetailByStore(storeIdx);
        }
        if (propIdx != null) {
            return salesAreaDetailByProperty(propIdx);
        }
        return salesAreaDetailByZone(zoneIdx);
    }

    @Transactional
    public SalesAreaDto saveSalesAreaZoneInfo(SalesAreaZoneInfoSaveRequest req) {
        if (req == null) {
            throw new IllegalArgumentException("요청 본문이 비어 있습니다.");
        }
        Integer zoneIdx = req.zoneIdx();
        final Integer reqPropIdx = req.propIdx();
        Integer propIdx = reqPropIdx;
        Integer storeIdx = req.storeIdx();

        if (propIdx != null && propIdx > 0) {
            final Integer validatedPropIdx = propIdx;
            propertyRepository
                    .findById(validatedPropIdx)
                    .orElseThrow(() -> new ResourceNotFoundException("물건", "propIdx", validatedPropIdx));
            if (storeIdx == null || storeIdx <= 0) {
                storeIdx = devMstMapper.selectStoreIdxByPropIdx(propIdx);
            }
        } else {
            propIdx = null;
        }

        if (zoneIdx == null || zoneIdx <= 0) {
            if (propIdx != null && propIdx > 0) {
                zoneIdx = devMstMapper.selectZoneIdxByPropIdx(propIdx);
            }
            if ((zoneIdx == null || zoneIdx <= 0) && storeIdx != null && storeIdx > 0) {
                zoneIdx = devMstMapper.selectZoneIdxByStoreIdx(storeIdx);
            }
        }

        if (zoneIdx == null || zoneIdx <= 0) {
            throw new IllegalArgumentException(
                    "영업지역이 아직 등록되지 않았습니다. 지도에서 영역을 저장한 후 비고를 입력할 수 있습니다.");
        }

        String zoneInfo = req.zoneInfo() != null ? req.zoneInfo().trim() : "";
        int updated = devMstMapper.updateSaleZoneInfo(zoneIdx, zoneInfo);
        if (updated == 0) {
            throw new IllegalStateException("sale_zone_mst UPDATE 실패: zoneIdx=" + zoneIdx);
        }

        log.info("영업지역정보 저장: zoneIdx={}", zoneIdx);

        if (storeIdx != null && storeIdx > 0) {
            return salesAreaDetailByStore(storeIdx);
        }
        if (propIdx != null) {
            return salesAreaDetailByProperty(propIdx);
        }
        return salesAreaDetailByZone(zoneIdx);
    }

    public PropertyMstDto oneProperty(Integer propIdx) {
        Property property = propertyRepository.findById(propIdx)
                .orElseThrow(() -> new ResourceNotFoundException("물건", "propIdx", propIdx));
        return PropertyMstDto.fromEntity(property);
    }

    @Transactional
    public PropertyMstDto createProperty(PropertyMstWriteRequestDto body) {
        if (!StringUtils.hasText(body.getPropNm())) {
            throw new IllegalArgumentException("propNm은(는) 필수입니다.");
        }
        if (devMstMapper.checkSurveyor(body.getSurveyor()) == 0) {
            throw new IllegalArgumentException("조사자 이름이 존재하지 않습니다. 조회 또는 등록된 이름을 입력하세요.");
        }
        if(devMstMapper.checkDuplicateProperty(body.getPropNm(), body.getAddress()) > 0) {
            throw new IllegalArgumentException("물건 이름과 주소가 중복됩니다. 확인 후 등록해주세요.");
        }
        BigDecimal lat = body.isLatitudePresent() ? body.getLatitude() : null;
        BigDecimal lon = body.isLongitudePresent() ? body.getLongitude() : null;
        Property property = Property.builder()
                .propNm(body.getPropNm().trim())
                .zipCd(body.isZipCdPresent() ? body.getZipCd() : null)
                .address(body.isAddressPresent() ? body.getAddress() : null)
                .addressDetail(body.isAddressDetailPresent() ? body.getAddressDetail() : null)
                .latitude(lat)
                .longitude(lon)
                .region(body.isRegionPresent() ? body.getRegion() : null)
                .propStatus(body.isPropStatusPresent() ? body.getPropStatus() : null)
                .propType(body.isPropTypePresent() ? body.getPropType() : null)
                .floor(body.isFloorPresent() ? body.getFloor() : null)
                .contArea(body.isContAreaPresent() ? body.getContArea() : null)
                .realArea(body.isRealAreaPresent() ? body.getRealArea() : null)
                .rentDeposit(body.isRentDepositPresent() ? body.getRentDeposit() : null)
                .monthlyRent(body.isMonthlyRentPresent() ? body.getMonthlyRent() : null)
                .premiumFee(body.isPremiumFeePresent() ? body.getPremiumFee() : null)
                .maintFee(body.isMaintFeePresent() ? body.getMaintFee() : null)
                .propNotes(body.isPropNotesPresent() ? body.getPropNotes() : null)
                .surveyDt(body.isSurveyDtPresent() ? body.getSurveyDt() : null)
                .surveyor(body.isSurveyorPresent() ? body.getSurveyor() : null)
                .build();
        applyCoordinates(property, body, true);
        Property saved = propertyRepository.save(property);
        syncLinkedStoreCoordinates(saved);
        log.info("물건 생성 완료: {}", saved.getPropIdx());
        return PropertyMstDto.fromEntity(saved);
    }

    @Transactional
    public PropertyMstDto updateProperty(Integer propIdx, PropertyMstWriteRequestDto body) {
        Property property = propertyRepository.findById(propIdx)
                .orElseThrow(() -> new ResourceNotFoundException("물건", "propIdx", propIdx));

        String newAddr = body.isAddressPresent() ? body.getAddress() : null;
        boolean addressChanged = newAddr != null && !newAddr.equals(property.getAddress());
        if (devMstMapper.checkSurveyor(body.getSurveyor()) == 0) {
            throw new IllegalArgumentException("조사자 이름이 존재하지 않습니다. 조회 또는 등록된 이름을 입력하세요.");
        }
        
        if(devMstMapper.checkDuplicateProperty2(body.getPropNm(), body.getAddress(), propIdx) > 0) {
            throw new IllegalArgumentException("물건 이름과 주소가 중복됩니다. 확인 후 등록해주세요.");
        }
        if (body.isPropNmPresent()) {
            property.setPropNm(body.getPropNm());
        }
        if (body.isZipCdPresent()) {
            property.setZipCd(body.getZipCd());
        }
        if (body.isAddressPresent()) {
            property.setAddress(body.getAddress());
        }
        if (body.isAddressDetailPresent()) {
            property.setAddressDetail(body.getAddressDetail());
        }
        if (body.isRegionPresent()) {
            property.setRegion(body.getRegion());
        }
        if (body.isPropStatusPresent()) {
            property.setPropStatus(body.getPropStatus());
        }
        if (body.isPropTypePresent()) {
            property.setPropType(body.getPropType());
        }
        if (body.isFloorPresent()) {
            property.setFloor(body.getFloor());
        }
        if (body.isContAreaPresent()) {
            property.setContArea(body.getContArea());
        }
        if (body.isRealAreaPresent()) {
            property.setRealArea(body.getRealArea());
        }
        if (body.isRentDepositPresent()) {
            property.setRentDeposit(body.getRentDeposit());
        }
        if (body.isMonthlyRentPresent()) {
            property.setMonthlyRent(body.getMonthlyRent());
        }
        if (body.isPremiumFeePresent()) {
            property.setPremiumFee(body.getPremiumFee());
        }
        if (body.isMaintFeePresent()) {
            property.setMaintFee(body.getMaintFee());
        }
        if (body.isPropNotesPresent()) {
            property.setPropNotes(body.getPropNotes());
        }
        if (body.isSurveyDtPresent()) {
            property.setSurveyDt(body.getSurveyDt());
        }
        if (body.isSurveyorPresent()) {
            property.setSurveyor(body.getSurveyor());
        }
        boolean needsCoordinates = property.getLatitude() == null || property.getLongitude() == null;
        applyCoordinates(property, body, addressChanged || needsCoordinates);

        Property saved = propertyRepository.save(property);
        syncLinkedStoreCoordinates(saved);
        log.info("물건 수정 완료: {}", saved.getPropIdx());
        return PropertyMstDto.fromEntity(saved);
    }

    @Transactional
    public void removeProperty(Integer propIdx) {
        Property property = propertyRepository.findById(propIdx)
                .orElseThrow(() -> new ResourceNotFoundException("물건", "propIdx", propIdx));
        propertyRepository.delete(property);
        log.info("물건 삭제 완료: {}", propIdx);
    }

    /** 물건 `property_mst` 좌표를 `prop_idx` 로 연결된 `store_mst` 에 반영. */
    private void syncLinkedStoreCoordinates(Property property) {
        Integer propIdx = property.getPropIdx();
        if (propIdx == null) {
            return;
        }
        int updated = devMstMapper.updateStoreCoordinatesByPropIdx(
                propIdx, property.getLatitude(), property.getLongitude());
        if (updated > 0) {
            log.info(
                    "물건 좌표 → 가맹점 연동: propIdx={}, 갱신 가맹점 {}건, lat={}, lon={}",
                    propIdx,
                    updated,
                    property.getLatitude(),
                    property.getLongitude());
        }
    }

    private void applyCoordinates(Property property, PropertyMstWriteRequestDto body, boolean shouldGeocode) {
        if (body.isLatitudePresent()) {
            property.setLatitude(body.getLatitude());
        }
        if (body.isLongitudePresent()) {
            property.setLongitude(body.getLongitude());
        }

        BigDecimal lat = property.getLatitude();
        BigDecimal lon = property.getLongitude();
        if (lat != null && lon != null) {
            return;
        }

        if (!shouldGeocode) {
            return;
        }

        String address = property.getAddress();
        if (!StringUtils.hasText(address)) {
            property.setLatitude(null);
            property.setLongitude(null);
            return;
        }

        addressGeocodingService.geocode(address)
                .ifPresent(coordinates -> {
                    property.setLatitude(coordinates.latitude());
                    property.setLongitude(coordinates.longitude());
                });
    }

    private static void applyPartnerWriteBody(Partner partner, PartnerMstWriteRequestDto body) {
        partner.setPartnerNm(requireNonBlank(body.getPartnerNm(), "partnerNm"));
        partner.setPartnerStatus(trimToNull(body.getPartnerStatus()));
        partner.setPartnerTel(requireNonBlank(body.getPartnerTel(), "partnerTel"));
        partner.setPartnerEmail(trimToNull(body.getPartnerEmail()));
        partner.setGender(trimToNull(body.getGender()));
        partner.setPartnerBirth(body.getPartnerBirth());
        partner.setPZipCd(trimToNull(body.getPZipCd()));
        partner.setPAddress(trimToNull(body.getPAddress()));
        partner.setPAddressDetail(trimToNull(body.getPAddressDetail()));
        partner.setPRegion(trimToNull(body.getPRegion()));
    }

    private static String requireNonBlank(String value, String fieldName) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(fieldName + "은(는) 필수입니다.");
        }
        return value.trim();
    }

    private static String trimToNull(String s) {
        if (s == null) {
            return null;
        }
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }

}
