package com.yeokjeon.erp.development.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * {@code POST /properties}·{@code PUT /properties/{propIdx}} 공통 요청 — 수정 시 {@code present}로 기존 {@code containsKey}와 동일.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class PropertyMstWriteRequestDto {

    private String propNm;
    private boolean propNmPresent;

    private String zipCd;
    private boolean zipCdPresent;

    private String address;
    private boolean addressPresent;

    private String addressDetail;
    private boolean addressDetailPresent;

    private BigDecimal latitude;
    private boolean latitudePresent;

    private BigDecimal longitude;
    private boolean longitudePresent;

    private String region;
    private boolean regionPresent;

    private String propStatus;
    private boolean propStatusPresent;

    private String propType;
    private boolean propTypePresent;

    private Integer floor;
    private boolean floorPresent;

    private BigDecimal contArea;
    private boolean contAreaPresent;

    private BigDecimal realArea;
    private boolean realAreaPresent;

    private Long rentDeposit;
    private boolean rentDepositPresent;

    private Long monthlyRent;
    private boolean monthlyRentPresent;

    private Long premiumFee;
    private boolean premiumFeePresent;

    private Long maintFee;
    private boolean maintFeePresent;

    private String propNotes;
    private boolean propNotesPresent;

    private LocalDate surveyDt;
    private boolean surveyDtPresent;

    private String surveyor;
    private boolean surveyorPresent;

    public void setPropNm(String propNm) {
        this.propNm = propNm;
        this.propNmPresent = true;
    }

    public boolean isPropNmPresent() {
        return propNmPresent;
    }

    public String getPropNm() {
        return propNm;
    }

    public void setZipCd(String zipCd) {
        this.zipCd = zipCd;
        this.zipCdPresent = true;
    }

    public boolean isZipCdPresent() {
        return zipCdPresent;
    }

    public String getZipCd() {
        return zipCd;
    }

    public void setAddress(String address) {
        this.address = address;
        this.addressPresent = true;
    }

    public boolean isAddressPresent() {
        return addressPresent;
    }

    public String getAddress() {
        return address;
    }

    public void setAddressDetail(String addressDetail) {
        this.addressDetail = addressDetail;
        this.addressDetailPresent = true;
    }

    public boolean isAddressDetailPresent() {
        return addressDetailPresent;
    }

    public String getAddressDetail() {
        return addressDetail;
    }

    public void setLatitude(BigDecimal latitude) {
        this.latitude = latitude;
        this.latitudePresent = true;
    }

    public boolean isLatitudePresent() {
        return latitudePresent;
    }

    public BigDecimal getLatitude() {
        return latitude;
    }

    public void setLongitude(BigDecimal longitude) {
        this.longitude = longitude;
        this.longitudePresent = true;
    }

    public boolean isLongitudePresent() {
        return longitudePresent;
    }

    public BigDecimal getLongitude() {
        return longitude;
    }

    public void setRegion(String region) {
        this.region = region;
        this.regionPresent = true;
    }

    public boolean isRegionPresent() {
        return regionPresent;
    }

    public String getRegion() {
        return region;
    }

    public void setPropStatus(String propStatus) {
        this.propStatus = propStatus;
        this.propStatusPresent = true;
    }

    public boolean isPropStatusPresent() {
        return propStatusPresent;
    }

    public String getPropStatus() {
        return propStatus;
    }

    public void setPropType(String propType) {
        this.propType = propType;
        this.propTypePresent = true;
    }

    public boolean isPropTypePresent() {
        return propTypePresent;
    }

    public String getPropType() {
        return propType;
    }

    public void setFloor(Integer floor) {
        this.floor = floor;
        this.floorPresent = true;
    }

    public boolean isFloorPresent() {
        return floorPresent;
    }

    public Integer getFloor() {
        return floor;
    }

    public void setContArea(BigDecimal contArea) {
        this.contArea = contArea;
        this.contAreaPresent = true;
    }

    public boolean isContAreaPresent() {
        return contAreaPresent;
    }

    public BigDecimal getContArea() {
        return contArea;
    }

    public void setRealArea(BigDecimal realArea) {
        this.realArea = realArea;
        this.realAreaPresent = true;
    }

    public boolean isRealAreaPresent() {
        return realAreaPresent;
    }

    public BigDecimal getRealArea() {
        return realArea;
    }

    public void setRentDeposit(Long rentDeposit) {
        this.rentDeposit = rentDeposit;
        this.rentDepositPresent = true;
    }

    public boolean isRentDepositPresent() {
        return rentDepositPresent;
    }

    public Long getRentDeposit() {
        return rentDeposit;
    }

    public void setMonthlyRent(Long monthlyRent) {
        this.monthlyRent = monthlyRent;
        this.monthlyRentPresent = true;
    }

    public boolean isMonthlyRentPresent() {
        return monthlyRentPresent;
    }

    public Long getMonthlyRent() {
        return monthlyRent;
    }

    public void setPremiumFee(Long premiumFee) {
        this.premiumFee = premiumFee;
        this.premiumFeePresent = true;
    }

    public boolean isPremiumFeePresent() {
        return premiumFeePresent;
    }

    public Long getPremiumFee() {
        return premiumFee;
    }

    public void setMaintFee(Long maintFee) {
        this.maintFee = maintFee;
        this.maintFeePresent = true;
    }

    public boolean isMaintFeePresent() {
        return maintFeePresent;
    }

    public Long getMaintFee() {
        return maintFee;
    }

    public void setPropNotes(String propNotes) {
        this.propNotes = propNotes;
        this.propNotesPresent = true;
    }

    public boolean isPropNotesPresent() {
        return propNotesPresent;
    }

    public String getPropNotes() {
        return propNotes;
    }

    public void setSurveyDt(LocalDate surveyDt) {
        this.surveyDt = surveyDt;
        this.surveyDtPresent = true;
    }

    public boolean isSurveyDtPresent() {
        return surveyDtPresent;
    }

    public LocalDate getSurveyDt() {
        return surveyDt;
    }

    public void setSurveyor(String surveyor) {
        this.surveyor = surveyor;
        this.surveyorPresent = true;
    }

    public boolean isSurveyorPresent() {
        return surveyorPresent;
    }

    public String getSurveyor() {
        return surveyor;
    }
}
