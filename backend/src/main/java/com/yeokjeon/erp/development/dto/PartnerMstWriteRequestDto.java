package com.yeokjeon.erp.development.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.time.LocalDate;

/**
 * {@code POST /partners}·{@code PUT /partners/{id}} 공통 요청 — 필드별 {@code present}는 수정 시에만 의미가 있고,
 * 생성({@code POST})은 필수값을 서비스에서 검증한다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class PartnerMstWriteRequestDto {

    private String partnerNm;
    private boolean partnerNmPresent;

    private String partnerStatus;
    private boolean partnerStatusPresent;

    private String partnerTel;
    private boolean partnerTelPresent;

    private String partnerEmail;
    private boolean partnerEmailPresent;

    private String gender;
    private boolean genderPresent;

    private LocalDate partnerBirth;
    private boolean partnerBirthPresent;

    private String pZipCd;
    private boolean pZipCdPresent;

    private String pAddress;
    private boolean pAddressPresent;

    private String pAddressDetail;
    private boolean pAddressDetailPresent;

    private String pRegion;
    private boolean pRegionPresent;

    public void setPartnerNm(String partnerNm) {
        this.partnerNm = partnerNm;
        this.partnerNmPresent = true;
    }

    public boolean isPartnerNmPresent() {
        return partnerNmPresent;
    }

    public String getPartnerNm() {
        return partnerNm;
    }

    public void setPartnerStatus(String partnerStatus) {
        this.partnerStatus = partnerStatus;
        this.partnerStatusPresent = true;
    }

    public boolean isPartnerStatusPresent() {
        return partnerStatusPresent;
    }

    public String getPartnerStatus() {
        return partnerStatus;
    }

    public void setPartnerTel(String partnerTel) {
        this.partnerTel = partnerTel;
        this.partnerTelPresent = true;
    }

    public boolean isPartnerTelPresent() {
        return partnerTelPresent;
    }

    public String getPartnerTel() {
        return partnerTel;
    }

    public void setPartnerEmail(String partnerEmail) {
        this.partnerEmail = partnerEmail;
        this.partnerEmailPresent = true;
    }

    public boolean isPartnerEmailPresent() {
        return partnerEmailPresent;
    }

    public String getPartnerEmail() {
        return partnerEmail;
    }

    public void setGender(String gender) {
        this.gender = gender;
        this.genderPresent = true;
    }

    public boolean isGenderPresent() {
        return genderPresent;
    }

    public String getGender() {
        return gender;
    }

    public void setPartnerBirth(LocalDate partnerBirth) {
        this.partnerBirth = partnerBirth;
        this.partnerBirthPresent = true;
    }

    public boolean isPartnerBirthPresent() {
        return partnerBirthPresent;
    }

    public LocalDate getPartnerBirth() {
        return partnerBirth;
    }

    public void setPZipCd(String pZipCd) {
        this.pZipCd = pZipCd;
        this.pZipCdPresent = true;
    }

    public boolean isPZipCdPresent() {
        return pZipCdPresent;
    }

    public String getPZipCd() {
        return pZipCd;
    }

    public void setPAddress(String pAddress) {
        this.pAddress = pAddress;
        this.pAddressPresent = true;
    }

    public boolean isPAddressPresent() {
        return pAddressPresent;
    }

    public String getPAddress() {
        return pAddress;
    }

    public void setPAddressDetail(String pAddressDetail) {
        this.pAddressDetail = pAddressDetail;
        this.pAddressDetailPresent = true;
    }

    public boolean isPAddressDetailPresent() {
        return pAddressDetailPresent;
    }

    public String getPAddressDetail() {
        return pAddressDetail;
    }

    public void setPRegion(String pRegion) {
        this.pRegion = pRegion;
        this.pRegionPresent = true;
    }

    public boolean isPRegionPresent() {
        return pRegionPresent;
    }

    public String getPRegion() {
        return pRegion;
    }
}
