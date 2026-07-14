package com.yeokjeon.erp.board.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record BbsFolderSaveRequestDto(
        @NotBlank @Size(max = 100) String folderNm,
        Integer sortOrder,
        String useYn,
        String ownerViewYn,
        String staffViewYn) {}
