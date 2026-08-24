package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * mail_folder_mst 한 행.
 *
 * <p>필드 순서를 XML resultMap 의 {@code <arg>} 순서와 똑같이 맞춰 둘 것.
 * {@code MailMstJdbcRow} 와 같은 이유로, 한 칸 어긋나도 컴파일은 통과하고
 * 런타임에 값만 뒤섞인다.
 *
 * <p>{@code parentFolderIdx} 는 Long 이다 — 최상위 메일함은 부모가 NULL 이고
 * 원시 타입이면 그 "없음"이 0번 메일함으로 뭉개진다.
 */
public record MailFolderJdbcRow(
        Long mailFolderIdx,
        String userId,
        Long parentFolderIdx,
        String folderNm,
        Integer sortOrder,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {
}
