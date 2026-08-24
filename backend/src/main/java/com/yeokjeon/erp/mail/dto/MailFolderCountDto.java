package com.yeokjeon.erp.mail.dto;

/**
 * 사용자 정의 메일함 한 개의 건수(사이드바 뱃지용).
 *
 * <p>메일이 한 통도 없는 메일함도 목록에 나와야 하므로 집계 쿼리는 mail_folder_mst 를
 * 기준으로 LEFT JOIN 한다. COUNT 를 mail_mst 기준으로 잡으면 빈 메일함이 사이드바에서
 * 통째로 사라져 사용자가 "내가 만든 함이 없어졌다"고 오해한다.
 */
public record MailFolderCountDto(
        long folderIdx,
        String folderNm,
        int total,
        int unread) {
}
