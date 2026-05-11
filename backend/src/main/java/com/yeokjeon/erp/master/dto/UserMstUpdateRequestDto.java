package com.yeokjeon.erp.master.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.time.LocalDate;

/**
 * {@code PUT /users/{userIdx}} 요청 본문 — 기존 {@code Map} + {@code containsKey}와 동일하게
 * setter가 호출된 필드만 갱신한다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class UserMstUpdateRequestDto {

    private String userName;
    private boolean userNamePresent;

    private String userId;
    private boolean userIdPresent;

    private String userPassword;

    private Integer deptIdx;
    private boolean deptIdxPresent;

    private String userPhone;
    private boolean userPhonePresent;

    private String userEmail;
    private boolean userEmailPresent;

    private String svYn;
    private boolean svYnPresent;

    private String positionCd;
    private boolean positionCdPresent;

    private String tagYn;
    private boolean tagYnPresent;

    private LocalDate joinDt;
    private boolean joinDtPresent;

    public void setUserName(String userName) {
        this.userName = userName;
        this.userNamePresent = true;
    }

    public boolean isUserNamePresent() {
        return userNamePresent;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserId(String userId) {
        this.userId = userId;
        this.userIdPresent = true;
    }

    public boolean isUserIdPresent() {
        return userIdPresent;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserPassword(String userPassword) {
        this.userPassword = userPassword;
    }

    public String getUserPassword() {
        return userPassword;
    }

    public void setDeptIdx(Integer deptIdx) {
        this.deptIdx = deptIdx;
        this.deptIdxPresent = true;
    }

    public boolean isDeptIdxPresent() {
        return deptIdxPresent;
    }

    public Integer getDeptIdx() {
        return deptIdx;
    }

    public void setUserPhone(String userPhone) {
        this.userPhone = userPhone;
        this.userPhonePresent = true;
    }

    public boolean isUserPhonePresent() {
        return userPhonePresent;
    }

    public String getUserPhone() {
        return userPhone;
    }

    public void setUserEmail(String userEmail) {
        this.userEmail = userEmail;
        this.userEmailPresent = true;
    }

    public boolean isUserEmailPresent() {
        return userEmailPresent;
    }

    public String getUserEmail() {
        return userEmail;
    }

    public void setSvYn(String svYn) {
        this.svYn = svYn;
        this.svYnPresent = true;
    }

    public boolean isSvYnPresent() {
        return svYnPresent;
    }

    public String getSvYn() {
        return svYn;
    }

    public void setPositionCd(String positionCd) {
        this.positionCd = positionCd;
        this.positionCdPresent = true;
    }

    public boolean isPositionCdPresent() {
        return positionCdPresent;
    }

    public String getPositionCd() {
        return positionCd;
    }

    public void setTagYn(String tagYn) {
        this.tagYn = tagYn;
        this.tagYnPresent = true;
    }

    public boolean isTagYnPresent() {
        return tagYnPresent;
    }

    public String getTagYn() {
        return tagYn;
    }

    public void setJoinDt(LocalDate joinDt) {
        this.joinDt = joinDt;
        this.joinDtPresent = true;
    }

    public boolean isJoinDtPresent() {
        return joinDtPresent;
    }

    public LocalDate getJoinDt() {
        return joinDt;
    }
}
