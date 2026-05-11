package com.yeokjeon.erp.active.dto;

import java.time.LocalDate;

/**
 * 활동 결재 알림({@code notif_mst})에서 사용자별 확인일(표시용)을 만들 때 사용하는 조회 행.
 */
public record ActNotifAckDateRow(String userId, LocalDate createDay) {}
