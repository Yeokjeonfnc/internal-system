package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;
import java.time.ZoneId;

/**
 * 메일 목록 한 줄. 목록 화면은 mail_mst 만 읽으므로 본문·첨부가 없다.
 *
 * <p>문자열/숫자 필드에 null 을 내보내지 않는다. Flutter 쪽 모델이 수동 fromJson 이라
 * null 이 섞이면 화면마다 널 체크를 흩뿌리게 되고, 한 군데만 빠뜨려도 목록 전체가
 * 흰 화면이 된다. 대신 {@code partnerIdx}/{@code mappingId} 는 null 을 유지한다 —
 * "연결된 거래처 없음"과 "0번 거래처"는 다른 뜻이라 0 으로 뭉갤 수 없다.
 */
public record MailListItemDto(
        long mailIdx,
        long threadIdx,
        String direction,
        String subject,
        String fromEmail,
        String fromNm,
        String toSummary,
        String snippet,
        int attCnt,
        String bodyStatus,
        String sendStatus,
        String lastStatus,
        boolean read,
        boolean spam,
        String userId,
        Integer partnerIdx,
        Long mappingId,
        OffsetDateTime mailAt,

        // ── 2차 확장 ────────────────────────────────────────────────────────
        /** 중요표시(별). 목록에서 바로 토글한다. */
        boolean star,
        /** 사용자 정의 메일함. null 이면 기본함. 0 으로 뭉개면 "0번 함"과 구분이 안 된다. */
        Long folderIdx,
        /** 예약발송 시각. 예약메일함 목록이 이 값을 그대로 보여 준다. */
        OffsetDateTime scheduledAt,
        /** 휴지통에 있는가. 목록 화면이 복구/완전삭제 버튼을 가르는 기준이다. */
        boolean deleted,
        /** 수신확인을 요청한 발송 메일인가. */
        boolean readReceipt,
        /** 수신확인이 처음 걸린 시각. null 이면 "확인되지 않음"(안 읽음이 아니다). */
        OffsetDateTime openedAt,
        /** 픽셀 호출 누적 횟수. */
        int openCnt,
        /** 중요도 H/N/L. */
        String importance) {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    /** 제목이 비어 있으면 목록에 빈 칸이 생겨 클릭 대상이 사라진다 */
    private static final String NO_SUBJECT = "(제목 없음)";

    public static MailListItemDto fromRow(MailMstJdbcRow row) {
        String subject = row.subject() == null || row.subject().isBlank()
                ? NO_SUBJECT
                : row.subject();
        return new MailListItemDto(
                row.mailIdx() == null ? 0L : row.mailIdx(),
                row.threadIdx() == null ? 0L : row.threadIdx(),
                row.direction() == null ? "" : row.direction(),
                subject,
                row.fromEmail() == null ? "" : row.fromEmail(),
                row.fromNm() == null ? "" : row.fromNm(),
                row.toSummary() == null ? "" : row.toSummary(),
                row.snippet() == null ? "" : row.snippet(),
                row.attCnt() == null ? 0 : row.attCnt(),
                row.bodyStatus() == null ? "" : row.bodyStatus(),
                row.sendStatus() == null ? "" : row.sendStatus(),
                row.lastStatus() == null ? "" : row.lastStatus(),
                "Y".equals(row.readYn()),
                "Y".equals(row.spamYn()),
                row.userId() == null ? "" : row.userId(),
                row.partnerIdx(),
                row.mappingId(),
                toSeoul(row.mailAt()),
                "Y".equals(row.starYn()),
                row.folderIdx(),
                toSeoul(row.scheduledAt()),
                Boolean.TRUE.equals(row.deletedYn()),
                "Y".equals(row.readReceiptYn()),
                toSeoul(row.openedAt()),
                row.openCnt() == null ? 0 : row.openCnt(),
                // 기본값 'N'(보통)을 채운다. 빈 문자열을 내보내면 화면이 중요도 아이콘을
                // 그릴지 말지 판단할 기준을 잃는다.
                row.importance() == null || row.importance().isBlank() ? "N" : row.importance());
    }

    /**
     * DB 는 timestamptz(UTC 기준)로 돌려주는데 화면은 한국 시각을 기대한다.
     * EAP 모듈과 같은 방식으로 DTO 경계에서 한 번만 변환한다.
     */
    static OffsetDateTime toSeoul(OffsetDateTime value) {
        if (value == null) {
            return null;
        }
        return value.atZoneSameInstant(SEOUL).toOffsetDateTime();
    }
}
