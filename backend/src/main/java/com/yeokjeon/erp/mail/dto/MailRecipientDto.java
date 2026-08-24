package com.yeokjeon.erp.mail.dto;

/**
 * 조직도 수신자 검색 결과 한 줄 (mal001-J).
 *
 * <p>세 출처(사원·거래처·부서)를 한 목록으로 합쳐 내려보낸다. 화면이 탭을 나눠 세 번
 * 호출하게 하면 "이름 일부만 아는" 흔한 검색에서 사용자가 어느 탭을 볼지 먼저 정해야 한다.
 *
 * @param type    USER(사원) | PARTNER(거래처) | DEPT(부서)
 * @param refIdx  원본 키. USER=user_idx, PARTNER=partner_idx, DEPT=dept_idx.
 *                화면이 부서를 고르면 이 값으로 {@code /mail/recipients/dept/{deptIdx}} 를 부른다.
 * @param name    표시 이름(사원명·거래처명·부서명)
 * @param email   DEPT 는 항상 빈 문자열이다 — 부서 자체에는 주소가 없고, 고르면
 *                부서원 주소를 펼쳐 받아야 한다({@code memberCnt} 로 몇 명인지 미리 알린다).
 * @param deptNm  소속 부서명. PARTNER 는 부서가 없어 빈 문자열.
 * @param memberCnt DEPT 일 때 메일주소를 가진 부서원 수. 나머지는 0.
 *                  Resend 의 to 상한(50명)을 화면이 미리 경고할 수 있게 함께 준다.
 */
public record MailRecipientDto(
        String type,
        long refIdx,
        String name,
        String email,
        String deptNm,
        int memberCnt) {

    public static final String TYPE_USER = "USER";
    public static final String TYPE_PARTNER = "PARTNER";
    public static final String TYPE_DEPT = "DEPT";

    /**
     * 조회 행 → 응답 DTO.
     *
     * <p>null 을 빈 문자열로 바꾸는 것은 {@code MailListItemDto} 와 같은 이유다 —
     * Flutter 모델이 수동 fromJson 이라 null 하나에 목록 전체가 흰 화면이 된다.
     */
    public static MailRecipientDto fromRow(MailRecipientJdbcRow row) {
        return new MailRecipientDto(
                row.type() == null ? "" : row.type(),
                row.refIdx() == null ? 0L : row.refIdx(),
                row.name() == null ? "" : row.name(),
                row.email() == null ? "" : row.email(),
                row.deptNm() == null ? "" : row.deptNm(),
                row.memberCnt() == null ? 0 : row.memberCnt());
    }
}
