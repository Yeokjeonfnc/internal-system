package com.yeokjeon.erp.auth.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.time.LocalDate;

/**
 * {@code PUT /auth/profile} 요청 본문 — 부분 수정(키 생략 vs {@code null} 전달)을 기존 {@code Map} + {@code containsKey}와 동일하게 맞춘다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class AuthProfileUpdateRequestDto {

    private String userName;
    private String userPassword;

    private String userPhone;
    private boolean userPhonePresent;

    private String positionCd;
    private boolean positionCdPresent;

    private String svYn;
    private boolean svYnPresent;

    private Integer deptIdx;
    private boolean deptIdxPresent;

    private LocalDate joinDt;
    private boolean joinDtPresent;

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getUserPassword() {
        return userPassword;
    }

    public void setUserPassword(String userPassword) {
        this.userPassword = userPassword;
    }

    public String getUserPhone() {
        return userPhone;
    }

    public void setUserPhone(String userPhone) {
        this.userPhone = userPhone;
        this.userPhonePresent = true;
    }

    public boolean isUserPhonePresent() {
        return userPhonePresent;
    }

    public String getPositionCd() {
        return positionCd;
    }

    public void setPositionCd(String positionCd) {
        this.positionCd = positionCd;
        this.positionCdPresent = true;
    }

    public boolean isPositionCdPresent() {
        return positionCdPresent;
    }

    public String getSvYn() {
        return svYn;
    }

    public void setSvYn(String svYn) {
        this.svYn = svYn;
        this.svYnPresent = true;
    }

    public boolean isSvYnPresent() {
        return svYnPresent;
    }

    public Integer getDeptIdx() {
        return deptIdx;
    }

    public void setDeptIdx(Integer deptIdx) {
        this.deptIdx = deptIdx;
        this.deptIdxPresent = true;
    }

    public boolean isDeptIdxPresent() {
        return deptIdxPresent;
    }

    public LocalDate getJoinDt() {
        return joinDt;
    }

    public void setJoinDt(LocalDate joinDt) {
        this.joinDt = joinDt;
        this.joinDtPresent = true;
    }

    public boolean isJoinDtPresent() {
        return joinDtPresent;
    }
}
