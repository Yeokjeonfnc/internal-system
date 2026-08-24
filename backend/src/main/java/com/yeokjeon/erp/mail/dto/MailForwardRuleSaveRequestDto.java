package com.yeokjeon.erp.mail.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * 자동전달 예외 규칙 생성·수정 요청 (mal001-L).
 *
 * <p>생성(POST)과 수정(PATCH)이 한 DTO 를 공유하고, 필수 여부는 서비스가 판단한다
 * ({@link MailFolderSaveRequestDto} 와 같은 방식). 수정에서는 null 이 "안 바꿈"이라
 * {@code @NotBlank} 를 달면 PATCH 가 불가능해진다.
 *
 * <p>쓰임새는 세금계산서·고지서다. 발신 도메인이 고정된 시스템 메일을 회계 담당에게
 * 바로 넘기려고 만든 기능이라, {@code DOMAIN} 매칭이 실사용의 대부분이다.
 *
 * @param matchType    EMAIL(주소 완전일치) / DOMAIN(도메인 일치)
 * @param matchVal     비교값. DOMAIN 이면 {@code @} 를 빼고 도메인만 적는다
 *                     (예: {@code hometax.go.kr}). 서비스가 {@code @} 를 붙여 보내도 떼어 낸다
 * @param forwardEmail 이 발신자의 메일을 보낼 주소
 * @param use          사용 여부. null 이면 생성 시 true
 * @param sortOrder    적용 순서. 비우면 맨 뒤
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record MailForwardRuleSaveRequestDto(
        @Pattern(regexp = "EMAIL|DOMAIN", message = "매칭 방식은 EMAIL 또는 DOMAIN 이어야 합니다.")
        String matchType,

        @Size(max = 320, message = "비교값은 320자를 넘을 수 없습니다.")
        String matchVal,

        @Email(message = "전달 주소 형식이 올바르지 않습니다.")
        @Size(max = 320, message = "전달 주소는 320자를 넘을 수 없습니다.")
        String forwardEmail,

        Boolean use,

        Integer sortOrder) {
}
