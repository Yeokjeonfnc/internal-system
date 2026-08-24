package com.yeokjeon.erp.mail.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * 목록 일괄 동작 요청 (mal001-B).
 *
 * <p>상한 500건은 화면 한 페이지 최대치({@code MailController.MAX_LIMIT})와 맞춘 값이다.
 * "전체 선택"이 화면에 보이는 것보다 많은 메일을 건드릴 수 없어야 하고, 무엇보다
 * 한 트랜잭션에서 갱신하는 행 수를 예측 가능한 범위로 묶어 둬야 잠금이 오래 걸리지 않는다.
 *
 * @param mailIdxes 대상 메일. 서비스가 <b>본인 소유(user_id) 인 것만</b> 다시 걸러낸다 —
 *                  여기 목록은 화면이 준 값이라 그대로 믿을 수 없다.
 * @param action    {@link MailBulkAction} 이름(대소문자 무관)
 * @param folderIdx {@code MOVE} 일 때 목적지 메일함. null 이면 기본함으로 되돌린다
 *                  (folder_idx = NULL). 다른 action 에서는 무시한다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record MailBulkActionRequestDto(
        @NotEmpty(message = "대상 메일을 선택해 주세요.")
        @Size(max = 500, message = "한 번에 최대 500건까지 처리할 수 있습니다.")
        List<Long> mailIdxes,

        @NotBlank(message = "수행할 동작(action)을 지정해 주세요.")
        @Size(max = 20)
        String action,

        Long folderIdx) {
}
