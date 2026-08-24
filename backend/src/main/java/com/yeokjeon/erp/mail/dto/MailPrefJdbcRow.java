package com.yeokjeon.erp.mail.dto;

/**
 * mail_pref 한 행(키-값).
 *
 * <p>updated_at 은 읽지 않는다. 개인 설정은 "언제 바꿨는지"가 화면에 필요 없고,
 * 조회할 때마다 안 쓰는 컬럼을 실어 나를 이유가 없다.
 */
public record MailPrefJdbcRow(
        String prefKey,
        String prefVal) {
}
