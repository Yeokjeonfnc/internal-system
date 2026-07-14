package com.yeokjeon.erp.franchise.dto;

import java.time.LocalDate;

/** {@code store_doc} INSERT 파라미터 — 생성 키 {@link #storeDocIdx} 반환. */
public class StoreDocumentInsertParam {

    private Integer storeDocIdx;
    private int storeIdx;
    private String fileName;
    private String storedName;
    private long fileSize;
    private String contentType;
    private LocalDate attachmentBaseDate;
    private String modifiedBy;

    public Integer getStoreDocIdx() {
        return storeDocIdx;
    }

    public void setStoreDocIdx(Integer storeDocIdx) {
        this.storeDocIdx = storeDocIdx;
    }

    public int getStoreIdx() {
        return storeIdx;
    }

    public void setStoreIdx(int storeIdx) {
        this.storeIdx = storeIdx;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public String getStoredName() {
        return storedName;
    }

    public void setStoredName(String storedName) {
        this.storedName = storedName;
    }

    public long getFileSize() {
        return fileSize;
    }

    public void setFileSize(long fileSize) {
        this.fileSize = fileSize;
    }

    public String getContentType() {
        return contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }

    public LocalDate getAttachmentBaseDate() {
        return attachmentBaseDate;
    }

    public void setAttachmentBaseDate(LocalDate attachmentBaseDate) {
        this.attachmentBaseDate = attachmentBaseDate;
    }

    public String getModifiedBy() {
        return modifiedBy;
    }

    public void setModifiedBy(String modifiedBy) {
        this.modifiedBy = modifiedBy;
    }
}
