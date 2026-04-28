package com.yeokjeon.erp.property.service;

import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.property.dto.PropertyRequestDto;
import com.yeokjeon.erp.property.dto.PropertyResponseDto;
import com.yeokjeon.erp.property.entity.Property;
import com.yeokjeon.erp.property.repository.PropertyRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PropertyService {

    private final PropertyRepository propertyRepository;
    private final AddressGeocodingService addressGeocodingService;

    public List<PropertyResponseDto> getAllProperties() {
        return propertyRepository.findAllProperties()
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public PropertyResponseDto getProperty(Integer propIdx) {
        Property property = propertyRepository.findById(propIdx)
                .orElseThrow(() -> new ResourceNotFoundException("물건", "propIdx", propIdx));
        return toDto(property);
    }

    @Transactional
    public PropertyResponseDto createProperty(PropertyRequestDto dto) {
        Property property = dto.toEntity();
        applyCoordinates(property, dto, true);
        Property saved = propertyRepository.save(property);
        log.info("물건 생성 완료: {}", saved.getPropIdx());
        return toDto(saved);
    }

    @Transactional
    public PropertyResponseDto updateProperty(Integer propIdx, PropertyRequestDto dto) {
        Property property = propertyRepository.findById(propIdx)
                .orElseThrow(() -> new ResourceNotFoundException("물건", "propIdx", propIdx));

        boolean addressChanged = dto.getAddress() != null && !dto.getAddress().equals(property.getAddress());

        if (dto.getPropNm() != null) property.setPropNm(dto.getPropNm());
        if (dto.getZipCd() != null) property.setZipCd(dto.getZipCd());
        if (dto.getAddress() != null) property.setAddress(dto.getAddress());
        if (dto.getAddressDetail() != null) property.setAddressDetail(dto.getAddressDetail());
        if (dto.getRegion() != null) property.setRegion(dto.getRegion());
        if (dto.getPropStatus() != null) property.setPropStatus(dto.getPropStatus());
        if (dto.getPropType() != null) property.setPropType(dto.getPropType());
        if (dto.getFloor() != null) property.setFloor(dto.getFloor());
        if (dto.getContArea() != null) property.setContArea(dto.getContArea());
        if (dto.getRealArea() != null) property.setRealArea(dto.getRealArea());
        if (dto.getRentDeposit() != null) property.setRentDeposit(dto.getRentDeposit());
        if (dto.getMonthlyRent() != null) property.setMonthlyRent(dto.getMonthlyRent());
        if (dto.getPremiumFee() != null) property.setPremiumFee(dto.getPremiumFee());
        if (dto.getMaintFee() != null) property.setMaintFee(dto.getMaintFee());
        if (dto.getPropNotes() != null) property.setPropNotes(dto.getPropNotes());
        if (dto.getSurveyDt() != null) property.setSurveyDt(dto.getSurveyDt());
        if (dto.getSurveyor() != null) property.setSurveyor(dto.getSurveyor());
        boolean needsCoordinates = property.getLatitude() == null || property.getLongitude() == null;
        applyCoordinates(property, dto, addressChanged || needsCoordinates);

        Property saved = propertyRepository.save(property);
        log.info("물건 수정 완료: {}", saved.getPropIdx());
        return toDto(saved);
    }

    @Transactional
    public void deleteProperty(Integer propIdx) {
        Property property = propertyRepository.findById(propIdx)
                .orElseThrow(() -> new ResourceNotFoundException("물건", "propIdx", propIdx));
        propertyRepository.delete(property);
        log.info("물건 삭제 완료: {}", propIdx);
    }

    private PropertyResponseDto toDto(Property property) {
        return PropertyResponseDto.builder()
                .propIdx(property.getPropIdx())
                .propNm(property.getPropNm())
                .zipCd(property.getZipCd())
                .address(property.getAddress())
                .addressDetail(property.getAddressDetail())
                .latitude(property.getLatitude())
                .longitude(property.getLongitude())
                .region(property.getRegion())
                .propStatus(property.getPropStatus())
                .propType(property.getPropType())
                .floor(property.getFloor())
                .contArea(property.getContArea())
                .realArea(property.getRealArea())
                .rentDeposit(property.getRentDeposit())
                .monthlyRent(property.getMonthlyRent())
                .premiumFee(property.getPremiumFee())
                .maintFee(property.getMaintFee())
                .propNotes(property.getPropNotes())
                .surveyDt(property.getSurveyDt())
                .createDt(property.getCreateDt())
                .updateDt(property.getUpdateDt())
                .surveyor(property.getSurveyor())
                .build();
    }

    private void applyCoordinates(Property property, PropertyRequestDto dto, boolean shouldGeocode) {
        if (dto.getLatitude() != null) property.setLatitude(dto.getLatitude());
        if (dto.getLongitude() != null) property.setLongitude(dto.getLongitude());

        if (dto.getLatitude() != null && dto.getLongitude() != null) {
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
}
