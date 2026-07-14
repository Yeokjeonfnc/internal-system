package com.yeokjeon.erp.active.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

/**
 * {@code POST /activities}·{@code PUT /activities/{actIdx}} 공통 요청 — 수정 시 {@code present}로 기존 {@code Map#containsKey}와 동일.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class ActiveMstWriteRequestDto {

    private Integer storeIdx;
    private boolean storeIdxPresent;

    private String actType;
    private boolean actTypePresent;

    private LocalDate actDt;
    private boolean actDtPresent;

    private String actNotes;
    private boolean actNotesPresent;

    private String memoTxt;
    private boolean memoTxtPresent;

    private String svId;
    private boolean svIdPresent;

    private String apprStatus;
    private boolean apprStatusPresent;

    private LocalDateTime apprDt;
    private boolean apprDtPresent;

    private String apprNotes;
    private boolean apprNotesPresent;

    private String suggestions;
    private boolean suggestionsPresent;

    private String svNotes;
    private boolean svNotesPresent;

    private List<String> apprUserIds;
    private boolean apprUserIdsPresent;

    private Character chkYn;

    private Long usageLogIdx;
    private boolean usageLogIdxPresent;

    private List<ChkResultDtlSaveDto> checklistResults;

    public List<ChkResultDtlSaveDto> checklistResultsOrEmpty() {
        return checklistResults == null ? Collections.emptyList() : checklistResults;
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

    public void setActType(String actType) {
        this.actType = actType;
        this.actTypePresent = true;
    }

    public boolean isActTypePresent() {
        return actTypePresent;
    }

    public String getActType() {
        return actType;
    }

    public void setActDt(LocalDate actDt) {
        this.actDt = actDt;
        this.actDtPresent = true;
    }

    public boolean isActDtPresent() {
        return actDtPresent;
    }

    public LocalDate getActDt() {
        return actDt;
    }

    public void setActNotes(String actNotes) {
        this.actNotes = actNotes;
        this.actNotesPresent = true;
    }

    public boolean isActNotesPresent() {
        return actNotesPresent;
    }

    public String getActNotes() {
        return actNotes;
    }

    public void setMemoTxt(String memoTxt) {
        this.memoTxt = memoTxt;
        this.memoTxtPresent = true;
    }

    public boolean isMemoTxtPresent() {
        return memoTxtPresent;
    }

    public String getMemoTxt() {
        return memoTxt;
    }

    public void setSvId(String svId) {
        this.svId = svId;
        this.svIdPresent = true;
    }

    public boolean isSvIdPresent() {
        return svIdPresent;
    }

    public String getSvId() {
        return svId;
    }

    public void setApprStatus(String apprStatus) {
        this.apprStatus = apprStatus;
        this.apprStatusPresent = true;
    }

    public boolean isApprStatusPresent() {
        return apprStatusPresent;
    }

    public String getApprStatus() {
        return apprStatus;
    }

    public void setApprDt(LocalDateTime apprDt) {
        this.apprDt = apprDt;
        this.apprDtPresent = true;
    }

    public boolean isApprDtPresent() {
        return apprDtPresent;
    }

    public LocalDateTime getApprDt() {
        return apprDt;
    }

    public void setApprNotes(String apprNotes) {
        this.apprNotes = apprNotes;
        this.apprNotesPresent = true;
    }

    public boolean isApprNotesPresent() {
        return apprNotesPresent;
    }

    public String getApprNotes() {
        return apprNotes;
    }

    public void setSuggestions(String suggestions) {
        this.suggestions = suggestions;
        this.suggestionsPresent = true;
    }

    public boolean isSuggestionsPresent() {
        return suggestionsPresent;
    }

    public String getSuggestions() {
        return suggestions;
    }

    public void setSvNotes(String svNotes) {
        this.svNotes = svNotes;
        this.svNotesPresent = true;
    }

    public boolean isSvNotesPresent() {
        return svNotesPresent;
    }

    public String getSvNotes() {
        return svNotes;
    }

    public void setApprUserIds(List<String> apprUserIds) {
        this.apprUserIds = apprUserIds;
        this.apprUserIdsPresent = true;
    }

    public boolean isApprUserIdsPresent() {
        return apprUserIdsPresent;
    }

    public List<String> getApprUserIds() {
        return apprUserIds;
    }

    public void setChkYn(Character chkYn) {
        this.chkYn = chkYn;
    }

    public Character getChkYn() {
        return chkYn;
    }

    public void setUsageLogIdx(Long usageLogIdx) {
        this.usageLogIdx = usageLogIdx;
        this.usageLogIdxPresent = true;
    }

    public boolean isUsageLogIdxPresent() {
        return usageLogIdxPresent;
    }

    public Long getUsageLogIdx() {
        return usageLogIdx;
    }

    public void setChecklistResults(List<ChkResultDtlSaveDto> checklistResults) {
        this.checklistResults = checklistResults;
    }
}
