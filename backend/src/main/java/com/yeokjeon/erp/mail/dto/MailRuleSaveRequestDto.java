package com.yeokjeon.erp.mail.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * 자동분류 규칙 생성·수정 요청 (mal001-K).
 *
 * <p>{@link MailFolderSaveRequestDto} 와 같은 방식으로 생성(POST)과 수정(PATCH)이 한 DTO 를
 * 공유한다. <b>필수 여부는 서비스가 판단한다</b> — 수정에서는 null 이 "안 바꿈"이라
 * {@code @NotBlank} 를 여기 달면 PATCH 가 불가능해진다.
 *
 * <p><b>조건을 지우는 방법.</b> record 로는 "필드를 안 보냄"과 "null 을 보냄"을 구분할 수
 * 없다. 그래서 조건 값에 <b>빈 문자열</b>을 보내면 "이 조건을 지운다"는 뜻으로 약속한다
 * (null = 안 바꿈). 화면에서 보낸사람 조건 체크를 해제하면 {@code fromVal: ""} 을 보내면 된다.
 *
 * <p>조건은 셋 다 AND 로 묶인다. 다우오피스에 OR 이 없어서 우리도 넣지 않았다 —
 * OR 이 필요하면 규칙을 두 개 만드는 것이 화면상으로도 더 분명하다.
 *
 * @param ruleNm          규칙 이름(목록 표시용)
 * @param use             사용 여부. false 면 수신 시 건너뛴다
 * @param fromOp          보낸사람 연산자 CONTAINS/EQUALS/STARTS
 * @param fromVal         보낸사람 비교값. ""(빈 문자열)이면 이 조건을 지운다
 * @param toOp            수신자 연산자
 * @param toVal           수신자 비교값. TO 뿐 아니라 CC(참조)까지 본다
 * @param subjOp          제목 연산자
 * @param subjVal         제목 비교값
 * @param actionType      MOVE(메일함 이동) 또는 READ(읽음처리). 규칙당 하나
 * @param actionFolderIdx MOVE 일 때 필수. 본인 소유 메일함이어야 한다
 * @param sortOrder       적용 순서. 생성 시 비우면 맨 뒤로 붙는다
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record MailRuleSaveRequestDto(
        @Size(max = 100, message = "규칙 이름은 100자를 넘을 수 없습니다.")
        String ruleNm,

        Boolean use,

        @Pattern(regexp = "CONTAINS|EQUALS|STARTS",
                message = "연산자는 CONTAINS, EQUALS, STARTS 중 하나여야 합니다.")
        String fromOp,
        @Size(max = 320, message = "보낸사람 조건은 320자를 넘을 수 없습니다.")
        String fromVal,

        @Pattern(regexp = "CONTAINS|EQUALS|STARTS",
                message = "연산자는 CONTAINS, EQUALS, STARTS 중 하나여야 합니다.")
        String toOp,
        @Size(max = 320, message = "수신자 조건은 320자를 넘을 수 없습니다.")
        String toVal,

        @Pattern(regexp = "CONTAINS|EQUALS|STARTS",
                message = "연산자는 CONTAINS, EQUALS, STARTS 중 하나여야 합니다.")
        String subjOp,
        @Size(max = 500, message = "제목 조건은 500자를 넘을 수 없습니다.")
        String subjVal,

        @Pattern(regexp = "MOVE|READ", message = "처리는 MOVE 또는 READ 여야 합니다.")
        String actionType,

        Long actionFolderIdx,

        Integer sortOrder) {
}
