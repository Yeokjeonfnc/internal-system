package com.yeokjeon.erp.board.dto;

public record BbsFolderJdbcRow(
        Integer folderIdx,
        String folderNm,
        Integer sortOrder,
        String useYn,
        String ownerViewYn,
        String staffViewYn) {}
