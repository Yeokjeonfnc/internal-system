package com.yeokjeon.erp.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "yon.file")
public class FileStorageProperties {

    /** 서버 디스크 루트 — 환경변수 {@code FILE_STORAGE_ROOT} 로 덮어쓸 수 있음. */
    private String storageRoot = "./storage";

    /** 단일 파일 최대 크기(바이트). 기본 50MB. */
    private long maxSizeBytes = 52_428_800L;

    public String getStorageRoot() {
        return storageRoot;
    }

    public void setStorageRoot(String storageRoot) {
        this.storageRoot = storageRoot;
    }

    public long getMaxSizeBytes() {
        return maxSizeBytes;
    }

    public void setMaxSizeBytes(long maxSizeBytes) {
        this.maxSizeBytes = maxSizeBytes;
    }
}
