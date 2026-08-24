package com.yeokjeon.erp.mail.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.Size;

/**
 * 사용자 정의 메일함 생성·수정 요청 (mal001-C).
 *
 * <p>생성(POST)과 수정(PATCH)이 같은 DTO 를 쓴다. 필드가 셋뿐이고 의미도 같은데
 * 타입을 둘로 나누면 검증 규칙이 두 곳으로 갈라져 언젠가 한쪽만 고쳐진다.
 * 대신 <b>필수 여부는 서비스가 판단한다</b> — 생성일 때만 이름이 필수고, 수정에서는
 * null 이 "안 바꿈"이라 {@code @NotBlank} 를 여기 달면 PATCH 가 불가능해진다.
 *
 * @param folderNm        메일함 이름. 같은 부모 아래 중복 불가(uq_mail_folder_owner_name).
 * @param parentFolderIdx 상위 메일함. null 이면 최상위.
 *                        DB 는 계층 깊이를 막지 않지만 화면에서 2단계까지만 만들게 한다.
 * @param sortOrder       사이드바 정렬 순서. null 이면 생성 시 맨 뒤로 붙인다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record MailFolderSaveRequestDto(
        @Size(max = 100, message = "메일함 이름은 100자를 넘을 수 없습니다.")
        String folderNm,

        Long parentFolderIdx,

        Integer sortOrder) {
}
