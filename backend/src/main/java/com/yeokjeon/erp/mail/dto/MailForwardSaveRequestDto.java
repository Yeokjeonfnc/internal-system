package com.yeokjeon.erp.mail.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;

/**
 * 전체 자동전달 설정 저장 요청 (mal001-L).
 *
 * <p>PUT 이다 — 세 값이 한 덩어리라 부분 갱신할 이유가 없다. 화면도 토글 하나와
 * 입력칸 하나를 함께 저장한다.
 *
 * <p>{@code use=true} 면 {@code forwardEmail} 이 반드시 있어야 한다. 켜 놓고 주소가 비면
 * "전달 중"으로 보이는데 아무 데도 가지 않는 상태가 되고, 사용자는 메일이 왜 안 오는지
 * 알 방법이 없다(DB CHECK 도 같은 조건을 건다).
 *
 * @param use          전체 자동전달 사용 여부. null 이면 false 로 본다
 * @param forwardEmail 전달받을 주소
 * @param keepOriginal 전달 후 원본을 남길지. null 이면 true(남김).
 *                     <b>false 로 하면 원본이 휴지통으로 가고, 받은메일함이 공용이라
 *                     다른 사람 화면에서도 사라진다.</b> 화면에서 그 사실을 반드시 안내할 것.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record MailForwardSaveRequestDto(
        Boolean use,

        @Email(message = "전달 주소 형식이 올바르지 않습니다.")
        @Size(max = 320, message = "전달 주소는 320자를 넘을 수 없습니다.")
        String forwardEmail,

        Boolean keepOriginal) {
}
