package com.yeokjeon.erp.mail.dto;

/**
 * 발송 요청 결과.
 *
 * <p>{@code resendEmailId} 는 즉시 발송이 성공했을 때만 채워진다. QUEUED 로만 넣고
 * 워커가 나중에 보내는 경로에서는 빈 문자열이다 — 화면이 이 값의 유무로
 * "정말 나갔는지"를 판단할 수 있어야 해서 null 대신 빈 문자열로 통일했다.
 */
public record MailSendResultDto(
        long mailIdx,
        String sendStatus,
        String resendEmailId,
        String message) {

    public static MailSendResultDto of(long mailIdx, String sendStatus, String resendEmailId, String message) {
        return new MailSendResultDto(
                mailIdx,
                sendStatus == null ? "" : sendStatus,
                resendEmailId == null ? "" : resendEmailId,
                message == null ? "" : message);
    }
}
