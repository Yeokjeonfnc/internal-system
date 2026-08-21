package com.yeokjeon.erp.master.dto;

import java.time.LocalDate;

/** 퇴사 처리 요청 — 퇴사일 미입력 시 서버가 당일로 처리한다. */
public record UserResignRequestDto(LocalDate leaveDt) {}
