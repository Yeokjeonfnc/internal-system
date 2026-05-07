package com.yeokjeon.erp.prp001.service;

import com.yeokjeon.erp.common.RequestMapUtil;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.prp001.entity.Property;
import com.yeokjeon.erp.prp001.repository.PropertyRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PropertyService {

    private final PropertyRepository propertyRepository;
    private final AddressGeocodingService addressGeocodingService;

    public List<Map<String, Object>> getAllProperties() {
        return propertyRepository.findAllProperties()
                .stream()
                .map(this::toRow)
                .collect(Collectors.toList());
    }

    public Map<String, Object> getProperty(Integer propIdx) {
        Property property = propertyRepository.findById(propIdx)
                .orElseThrow(() -> new ResourceNotFoundException("물건", "propIdx", propIdx));
        return toRow(property);
    }

    @Transactional
    public Map<String, Object> createProperty(Map<String, Object> body) {
        BigDecimal lat = RequestMapUtil.optBigDecimal(body, "latitude");
        BigDecimal lon = RequestMapUtil.optBigDecimal(body, "longitude");
        Property property = Property.builder()
                .propNm(RequestMapUtil.reqStr(body, "propNm"))
                .zipCd(RequestMapUtil.optStr(body, "zipCd"))
                .address(RequestMapUtil.optStr(body, "address"))
                .addressDetail(RequestMapUtil.optStr(body, "addressDetail"))
                .latitude(lat)
                .longitude(lon)
                .region(RequestMapUtil.optStr(body, "region"))
                .propStatus(RequestMapUtil.optStr(body, "propStatus"))
                .propType(RequestMapUtil.optStr(body, "propType"))
                .floor(RequestMapUtil.optInt(body, "floor"))
                .contArea(RequestMapUtil.optBigDecimal(body, "contArea"))
                .realArea(RequestMapUtil.optBigDecimal(body, "realArea"))
                .rentDeposit(RequestMapUtil.optLong(body, "rentDeposit"))
                .monthlyRent(RequestMapUtil.optLong(body, "monthlyRent"))
                .premiumFee(RequestMapUtil.optLong(body, "premiumFee"))
                .maintFee(RequestMapUtil.optLong(body, "maintFee"))
                .propNotes(RequestMapUtil.optStr(body, "propNotes"))
                .surveyDt(RequestMapUtil.optLocalDate(body, "surveyDt"))
                .surveyor(RequestMapUtil.optStr(body, "surveyor"))
                .build();
        applyCoordinates(property, body, true);
        Property saved = propertyRepository.save(property);
        log.info("물건 생성 완료: {}", saved.getPropIdx());
        return toRow(saved);
    }

    @Transactional
    public Map<String, Object> updateProperty(Integer propIdx, Map<String, Object> body) {
        Property property = propertyRepository.findById(propIdx)
                .orElseThrow(() -> new ResourceNotFoundException("물건", "propIdx", propIdx));

        String newAddr = RequestMapUtil.optStr(body, "address");
        boolean addressChanged = newAddr != null && !newAddr.equals(property.getAddress());

        if (body.containsKey("propNm")) {
            property.setPropNm(RequestMapUtil.optStr(body, "propNm"));
        }
        if (body.containsKey("zipCd")) {
            property.setZipCd(RequestMapUtil.optStr(body, "zipCd"));
        }
        if (body.containsKey("address")) {
            property.setAddress(RequestMapUtil.optStr(body, "address"));
        }
        if (body.containsKey("addressDetail")) {
            property.setAddressDetail(RequestMapUtil.optStr(body, "addressDetail"));
        }
        if (body.containsKey("region")) {
            property.setRegion(RequestMapUtil.optStr(body, "region"));
        }
        if (body.containsKey("propStatus")) {
            property.setPropStatus(RequestMapUtil.optStr(body, "propStatus"));
        }
        if (body.containsKey("propType")) {
            property.setPropType(RequestMapUtil.optStr(body, "propType"));
        }
        if (body.containsKey("floor")) {
            property.setFloor(RequestMapUtil.optInt(body, "floor"));
        }
        if (body.containsKey("contArea")) {
            property.setContArea(RequestMapUtil.optBigDecimal(body, "contArea"));
        }
        if (body.containsKey("realArea")) {
            property.setRealArea(RequestMapUtil.optBigDecimal(body, "realArea"));
        }
        if (body.containsKey("rentDeposit")) {
            property.setRentDeposit(RequestMapUtil.optLong(body, "rentDeposit"));
        }
        if (body.containsKey("monthlyRent")) {
            property.setMonthlyRent(RequestMapUtil.optLong(body, "monthlyRent"));
        }
        if (body.containsKey("premiumFee")) {
            property.setPremiumFee(RequestMapUtil.optLong(body, "premiumFee"));
        }
        if (body.containsKey("maintFee")) {
            property.setMaintFee(RequestMapUtil.optLong(body, "maintFee"));
        }
        if (body.containsKey("propNotes")) {
            property.setPropNotes(RequestMapUtil.optStr(body, "propNotes"));
        }
        if (body.containsKey("surveyDt")) {
            property.setSurveyDt(RequestMapUtil.optLocalDate(body, "surveyDt"));
        }
        if (body.containsKey("surveyor")) {
            property.setSurveyor(RequestMapUtil.optStr(body, "surveyor"));
        }
        boolean needsCoordinates = property.getLatitude() == null || property.getLongitude() == null;
        applyCoordinates(property, body, addressChanged || needsCoordinates);

        Property saved = propertyRepository.save(property);
        log.info("물건 수정 완료: {}", saved.getPropIdx());
        return toRow(saved);
    }

    @Transactional
    public void deleteProperty(Integer propIdx) {
        Property property = propertyRepository.findById(propIdx)
                .orElseThrow(() -> new ResourceNotFoundException("물건", "propIdx", propIdx));
        propertyRepository.delete(property);
        log.info("물건 삭제 완료: {}", propIdx);
    }

    private Map<String, Object> toRow(Property property) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("propIdx", property.getPropIdx());
        m.put("propNm", property.getPropNm());
        m.put("zipCd", property.getZipCd());
        m.put("address", property.getAddress());
        m.put("addressDetail", property.getAddressDetail());
        m.put("latitude", property.getLatitude());
        m.put("longitude", property.getLongitude());
        m.put("region", property.getRegion());
        m.put("propStatus", property.getPropStatus());
        m.put("propType", property.getPropType());
        m.put("floor", property.getFloor());
        m.put("contArea", property.getContArea());
        m.put("realArea", property.getRealArea());
        m.put("rentDeposit", property.getRentDeposit());
        m.put("monthlyRent", property.getMonthlyRent());
        m.put("premiumFee", property.getPremiumFee());
        m.put("maintFee", property.getMaintFee());
        m.put("propNotes", property.getPropNotes());
        m.put("surveyDt", property.getSurveyDt());
        m.put("createDt", property.getCreateDt());
        m.put("updateDt", property.getUpdateDt());
        m.put("surveyor", property.getSurveyor());
        return m;
    }

    private void applyCoordinates(Property property, Map<String, Object> body, boolean shouldGeocode) {
        if (body.containsKey("latitude")) {
            property.setLatitude(RequestMapUtil.optBigDecimal(body, "latitude"));
        }
        if (body.containsKey("longitude")) {
            property.setLongitude(RequestMapUtil.optBigDecimal(body, "longitude"));
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
}
