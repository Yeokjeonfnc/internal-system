package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;
import java.util.List;

/**
 * 수신확인 조회 응답 (mal001-G) — {@code GET /mail/messages/{mailIdx}/receipt}.
 *
 * <p>보낸메일함의 "확인/미확인" 컬럼은 목록({@link MailListItemDto#openedAt()})만으로도
 * 그릴 수 있다. 이 API 는 그 옆의 <b>상세 팝업</b>용이다 — 누가 언제 열었고 누구에게
 * 반송됐는지를 수신자별로 보여 준다.
 *
 * <p>{@code trackingConfigured} 를 함께 내려 주는 이유: 추적 설정
 * ({@code RESEND_TRACKING_BASE_URL})이 없으면 픽셀이 아예 안 심겨 <b>영원히 미확인</b>이다.
 * 이 값이 false 인데 화면이 "미확인"이라고만 표시하면 사용자는 상대가 안 읽었다고 오해한다.
 * "수신확인 기능이 꺼져 있습니다" 로 안내해야 한다.
 *
 * @param mailIdx            메일 번호
 * @param subject            제목(팝업 헤더용)
 * @param readReceipt        발송 시 수신확인을 요청했는가. false 면 픽셀 자체가 없다
 * @param opened             한 명이라도 확인했는가(메일 단위)
 * @param openedAt           처음 확인된 시각(메일 단위). null 이면 확인되지 않음
 * @param openCnt            픽셀 호출 누적 횟수. 이미지 프록시 때문에 실제 열람 수와 다를 수 있다
 * @param trackingConfigured 서버에 추적 설정이 되어 있는가
 * @param recipientCnt       수신자 수(TO+CC+BCC)
 * @param openedCnt          확인된 것으로 판정된 수신자 수
 * @param recipients         수신자별 상태
 */
public record MailReceiptDto(
        long mailIdx,
        String subject,
        boolean readReceipt,
        boolean opened,
        OffsetDateTime openedAt,
        int openCnt,
        boolean trackingConfigured,
        int recipientCnt,
        int openedCnt,
        List<MailReceiptRecipientDto> recipients) {
}
