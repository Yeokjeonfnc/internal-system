package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * mail_att 한 행(첨부 메타). 실물 바이너리는 디스크에 있고 여기에는 메타만 있다.
 *
 * <p>{@code fetchedAt} 이 NULL 이면 "메타만 있고 파일은 아직 없다"는 뜻이다.
 * 수신 메일 첨부는 웹훅 시점에 실물이 오지 않아 반드시 이 상태를 거치므로,
 * 화면에서 다운로드 버튼을 열지 말지 판단하는 기준이 된다.
 */
public record MailAttJdbcRow(
        Long mailAttIdx,
        Long mailIdx,
        String resendAttId,
        String fileName,
        String storedName,
        Long fileSize,
        String contentType,
        String contentId,
        String inlineYn,
        OffsetDateTime fetchedAt,
        Integer fetchTryCnt,
        OffsetDateTime fetchTriedAt,
        String fetchErr,
        OffsetDateTime attachedAt,
        OffsetDateTime modifiedAt,
        String modifiedBy,
        Boolean deletedYn) {
}
