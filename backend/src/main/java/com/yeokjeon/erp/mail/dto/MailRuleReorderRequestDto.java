package com.yeokjeon.erp.mail.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * 규칙 순서 변경 요청 (mal001-K).
 *
 * <p><b>보낸 순서가 곧 새 순서다.</b> 규칙마다 sortOrder 숫자를 실어 보내는 방식이 아니라
 * idx 목록의 배열 순서를 그대로 0,1,2… 로 다시 매긴다. 화면이 드래그로 목록을 재배열한 뒤
 * 그 배열을 그대로 보내면 되고, 숫자가 어긋나 두 규칙이 같은 순서를 갖는 상태가 생길 수 없다.
 *
 * <p>목록에 <b>내 규칙 전부</b>를 담아 보내야 한다. 일부만 보내면 빠진 규칙이 맨 뒤로
 * 밀리는데, 서비스가 그 사실을 응답으로 알려 주지 못한다. 서비스는 남의 규칙 idx 가
 * 섞여 있으면 조용히 무시한다(소유자 조건이 SQL 에 있다).
 *
 * @param ruleIdxes 새 순서대로 나열한 mail_rule_idx
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record MailRuleReorderRequestDto(
        @NotEmpty(message = "순서를 정할 규칙이 없습니다.")
        @Size(max = 100, message = "한 번에 최대 100개까지 정렬할 수 있습니다.")
        List<Long> ruleIdxes) {
}
