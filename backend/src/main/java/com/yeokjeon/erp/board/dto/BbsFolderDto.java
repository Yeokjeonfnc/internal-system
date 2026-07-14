package com.yeokjeon.erp.board.dto;

public record BbsFolderDto(
        Integer folderIdx,
        String folderNm,
        Integer sortOrder,
        String useYn,
        String ownerViewYn,
        String staffViewYn,
        long postCount) {

    public static BbsFolderDto fromRow(BbsFolderJdbcRow row, long postCount) {
        return new BbsFolderDto(
                row.folderIdx(),
                row.folderNm(),
                row.sortOrder(),
                row.useYn(),
                row.ownerViewYn(),
                row.staffViewYn(),
                postCount);
    }
}
