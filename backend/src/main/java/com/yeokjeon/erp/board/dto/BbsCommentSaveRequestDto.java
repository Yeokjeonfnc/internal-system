package com.yeokjeon.erp.board.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record BbsCommentSaveRequestDto(@NotBlank @Size(max = 2000) String bodyTxt) {}
