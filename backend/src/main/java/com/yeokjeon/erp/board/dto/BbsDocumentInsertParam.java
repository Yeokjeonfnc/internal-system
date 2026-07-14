package com.yeokjeon.erp.board.dto;

public class BbsDocumentInsertParam {
    private int postIdx;
    private String fileName;
    private String storedName;
    private long fileSize;
    private String contentType;
    private String modifiedBy;
    private int bbsDocIdx;

    public int getPostIdx() {
        return postIdx;
    }

    public void setPostIdx(int postIdx) {
        this.postIdx = postIdx;
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

    public String getModifiedBy() {
        return modifiedBy;
    }

    public void setModifiedBy(String modifiedBy) {
        this.modifiedBy = modifiedBy;
    }

    public int getBbsDocIdx() {
        return bbsDocIdx;
    }

    public void setBbsDocIdx(int bbsDocIdx) {
        this.bbsDocIdx = bbsDocIdx;
    }
}
