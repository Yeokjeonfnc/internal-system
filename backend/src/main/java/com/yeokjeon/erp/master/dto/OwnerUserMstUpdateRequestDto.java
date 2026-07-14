package com.yeokjeon.erp.master.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/** {@code PUT /owner-users/{userIdx}} 요청 본문 — setter가 호출된 필드만 갱신. */
@JsonIgnoreProperties(ignoreUnknown = true)
public class OwnerUserMstUpdateRequestDto {

    private String userName;
    private boolean userNamePresent;

    private String userId;
    private boolean userIdPresent;

    private String userPassword;

    private String userPhone;
    private boolean userPhonePresent;

    private String userEmail;
    private boolean userEmailPresent;

    private Integer storeIdx;
    private boolean storeIdxPresent;

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

    public void setStoreIdx(Integer storeIdx) {
        this.storeIdx = storeIdx;
        this.storeIdxPresent = true;
    }

    public boolean isStoreIdxPresent() {
        return storeIdxPresent;
    }

    public Integer getStoreIdx() {
        return storeIdx;
    }
}
