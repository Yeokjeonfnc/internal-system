package com.yeokjeon.erp.development.service;

import com.yeokjeon.erp.development.dto.PartnerMstDto;
import com.yeokjeon.erp.development.dto.PartnerMstWriteRequestDto;
import com.yeokjeon.erp.development.dto.PropertyMstDto;
import com.yeokjeon.erp.development.dto.PropertyMstWriteRequestDto;
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
import java.util.List;

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
        Partner partner = Partner.builder()
                .partnerNm(partnerNm)
                .partnerStatus(trimToNull(body.getPartnerStatus()))
                .partnerTel(partnerTel)
                .partnerEmail(trimToNull(body.getPartnerEmail()))
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

    @Transactional
    public PartnerMstDto updatePartner(Integer partnerIdx, PartnerMstWriteRequestDto body) {
        Partner partner = partnerRepository.findById(partnerIdx)
                .orElseThrow(() -> new ResourceNotFoundException("예비창업자", "partnerIdx", partnerIdx));

        if (body.isPartnerNmPresent()) {
            partner.setPartnerNm(trimToNull(body.getPartnerNm()));
        }
        if (body.isPartnerStatusPresent()) {
            partner.setPartnerStatus(trimToNull(body.getPartnerStatus()));
        }
        if (body.isPartnerTelPresent()) {
            partner.setPartnerTel(trimToNull(body.getPartnerTel()));
        }
        if (body.isPartnerEmailPresent()) {
            partner.setPartnerEmail(trimToNull(body.getPartnerEmail()));
        }
        if (body.isGenderPresent()) {
            partner.setGender(trimToNull(body.getGender()));
        }
        if (body.isPartnerBirthPresent()) {
            partner.setPartnerBirth(body.getPartnerBirth());
        }
        if (body.isPZipCdPresent()) {
            partner.setPZipCd(trimToNull(body.getPZipCd()));
        }
        if (body.isPAddressPresent()) {
            partner.setPAddress(trimToNull(body.getPAddress()));
        }
        if (body.isPAddressDetailPresent()) {
            partner.setPAddressDetail(trimToNull(body.getPAddressDetail()));
        }
        if (body.isPRegionPresent()) {
            partner.setPRegion(trimToNull(body.getPRegion()));
        }

        Partner saved = partnerRepository.save(partner);
        log.info("예비창업자 수정 완료: {}", saved.getPartnerIdx());
        return PartnerMstDto.fromEntity(saved);
    }

    public List<PropertyMstDto> listProperties() {
        return devMstMapper.selectPropertiesOrdered();
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
        log.info("물건 생성 완료: {}", saved.getPropIdx());
        return PropertyMstDto.fromEntity(saved);
    }

    @Transactional
    public PropertyMstDto updateProperty(Integer propIdx, PropertyMstWriteRequestDto body) {
        Property property = propertyRepository.findById(propIdx)
                .orElseThrow(() -> new ResourceNotFoundException("물건", "propIdx", propIdx));

        String newAddr = body.isAddressPresent() ? body.getAddress() : null;
        boolean addressChanged = newAddr != null && !newAddr.equals(property.getAddress());

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

    private static String trimToNull(String s) {
        if (s == null) {
            return null;
        }
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }
}
