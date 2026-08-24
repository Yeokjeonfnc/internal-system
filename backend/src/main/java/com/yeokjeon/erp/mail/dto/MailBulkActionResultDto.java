package com.yeokjeon.erp.mail.dto;

/**
 * 목록 일괄 동작 결과 (mal001-B).
 *
 * <p>{@code requested} 와 {@code affected} 를 <b>둘 다</b> 돌려주는 것이 핵심이다.
 * 남의 메일이 섞여 있었거나 이미 그 상태였던 메일은 갱신되지 않는데, 건수를 하나만
 * 주면 화면이 "20건 처리했습니다"라고 말한 뒤 목록에는 13건만 바뀌어 있는 상황이 된다.
 * 두 숫자가 다르면 화면이 그 차이를 사용자에게 설명할 수 있다.
 *
 * @param action    실제로 수행한 동작
 * @param requested 요청에 담겨 온 대상 건수(중복 제거 후)
 * @param affected  실제로 갱신된 건수
 * @param message   화면에 그대로 띄울 안내 문구
 */
public record MailBulkActionResultDto(
        String action,
        int requested,
        int affected,
        String message) {
}
