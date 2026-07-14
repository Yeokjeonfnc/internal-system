package com.yeokjeon.erp.development.dto;

import java.time.LocalDate;

/** {@code property_doc} INSERT 파라미터 — 생성 키 {@link #propertyDocIdx} 반환. */
public class PropertyDocumentInsertParam {

    private Integer propertyDocIdx;
    private int propIdx;
    private String fileName;
    private String storedName;
    private long fileSize;
    private String contentType;
    private LocalDate attachmentBaseDate;
    private String modifiedBy;

    public Integer getPropertyDocIdx() {
        return propertyDocIdx;
    }

    public void setPropertyDocIdx(Integer propertyDocIdx) {
        this.propertyDocIdx = propertyDocIdx;
    }

    public int getPropIdx() {
        return propIdx;
    }

    public void setPropIdx(int propIdx) {
        this.propIdx = propIdx;
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
