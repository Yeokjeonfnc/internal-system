package com.yeokjeon.erp.active.dto;

public record ActivityPlanStoreItemDto(
        int storeIdx,
        String storeLabel,
        int assigneeUserIdx,
        String assigneeUserName,
        boolean planned,
        boolean completed) {}
