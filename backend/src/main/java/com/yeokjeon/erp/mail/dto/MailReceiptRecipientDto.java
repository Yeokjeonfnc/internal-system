package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * 수신확인 — 수신자 한 명의 상태 (mal001-G).
 *
 * <p><b>지금은 열람 추적이 메일 단위다.</b> 추적픽셀 URL 에는 mail_idx 만 들어 있어서
 * 누가 열었는지 구분할 수 없다. 그래도 응답을 수신자 배열로 열어 두는 이유는, 나중에
 * 픽셀 토큰에 수신자를 넣어 수신자별 추적으로 바꿀 때 <b>화면을 고치지 않아도 되게</b>
 * 하기 위해서다. 응답 형태가 바뀌면 Flutter 모델·목록 위젯이 전부 따라 바뀐다.
 *
 * <p>그래서 지금 채워지는 값의 출처가 둘이다.
 * <ul>
 *   <li>{@code lastStatus}/{@code lastStatusAt} — mail_event_log 에 <b>수신자별로</b>
 *       실제 기록되는 값이다(Resend 가 recipient 를 준다). 지금도 정확하다.</li>
 *   <li>{@code openedAt}/{@code openCnt} — 수신자별 opened 이벤트가 있으면 그 값,
 *       없으면 <b>수신자가 한 명일 때만</b> 메일 단위 값을 채운다. 여러 명일 때
 *       메일 단위 값을 전원에게 복사하면 한 명이 열었는데 전원 "확인"으로 보인다.</li>
 * </ul>
 *
 * @param addrType    TO / CC / BCC
 * @param email       수신자 주소(소문자)
 * @param dispNm      표시이름. 없으면 ""
 * @param opened      확인 여부. false 는 "안 읽음"이 아니라 "확인되지 않음"이다
 * @param openedAt    처음 확인된 시각. 모르면 null
 * @param openCnt     확인 횟수. 모르면 0
 * @param lastStatus  이 수신자에 대한 마지막 배달 이벤트(delivered/bounced/…). 없으면 ""
 * @param lastStatusAt 그 이벤트 시각
 */
public record MailReceiptRecipientDto(
        String addrType,
        String email,
        String dispNm,
        boolean opened,
        OffsetDateTime openedAt,
        int openCnt,
        String lastStatus,
        OffsetDateTime lastStatusAt) {
}
