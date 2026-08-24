package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * mail_forward_setting 한 행(전체 자동전달 설정, 사용자당 1행).
 *
 * <p>필드 순서를 XML resultMap 의 {@code <arg>} 순서 = 테이블 컬럼 순서와 맞춰 둘 것.
 */
public record MailForwardSettingJdbcRow(
        String userId,
        String useYn,
        String forwardEmail,
        /** 'N' 이면 전달 후 원본을 휴지통으로 보낸다. 공용 받은메일함이라 파급이 크다. */
        String keepOriginalYn,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {
}
