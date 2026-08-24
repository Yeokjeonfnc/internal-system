package com.yeokjeon.erp.mail.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.Size;

/**
 * 서명 생성·수정 요청 (mal001-D).
 *
 * <p>{@link MailFolderSaveRequestDto} 와 같은 이유로 생성·수정이 한 DTO 를 공유하고,
 * 필수 여부는 서비스가 판단한다(PATCH 에서 null = 안 바꿈).
 *
 * <p>{@code signHtml} 에 길이 제한을 두지 않은 것은 컬럼이 {@code text} 라서다.
 * 다만 서명은 본문에 매번 딸려 나가므로 서비스에서 상한을 한 번 더 건다 —
 * 수십 KB 짜리 서명이 모든 메일에 붙으면 발송 용량이 그만큼 불어난다.
 *
 * @param defaultNew   새 메일 기본 서명으로 지정. true 로 바꾸면 같은 사용자의 다른
 *                     서명은 서비스가 전부 'N' 으로 내린다(사용자당 하나 보장).
 * @param defaultReply 답장 기본 서명으로 지정. 위와 같은 규칙.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record MailSignatureSaveRequestDto(
        @Size(max = 100, message = "서명 이름은 100자를 넘을 수 없습니다.")
        String signNm,

        String signHtml,

        Boolean defaultNew,

        Boolean defaultReply,

        Integer sortOrder) {
}
