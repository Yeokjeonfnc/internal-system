package com.yeokjeon.erp.mail.dto;

/**
 * 메일주소 → ERP 사용자 매핑 한 행.
 *
 * <p>수신 메일에는 "누구 앞으로 온 메일인가"가 주소로만 적혀 있다. 자동분류·자동전달은
 * <b>개인 설정</b>이라 적용하려면 그 주소의 주인을 먼저 찾아야 한다
 * ({@code MailAutoProcessService.resolveOwnerUserId}).
 *
 * <p>{@code mail_mst.user_id} 를 쓰지 않는 이유: 수신 메일은 담당자 미지정(NULL)으로
 * 저장되고, 배정은 사람이 화면에서 한다. 규칙 적용 시점에는 아직 비어 있다.
 */
public record MailUserRefJdbcRow(
        /** 소문자로 정규화된 사원 메일주소 */
        String email,
        /** user_mst.user_id */
        String userId) {
}
