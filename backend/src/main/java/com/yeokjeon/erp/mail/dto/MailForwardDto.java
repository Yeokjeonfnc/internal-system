package com.yeokjeon.erp.mail.dto;

import java.util.List;

/**
 * 자동전달 설정 전체(화면 응답용) — 전체 설정 + 예외 규칙 목록.
 *
 * <p>둘을 한 응답에 담는 이유: 설정 화면이 언제나 같이 그린다. 나눠 주면 화면이
 * 왕복을 두 번 하고, 그 사이 한쪽만 저장된 상태가 화면에 보일 수 있다.
 *
 * <p>{@code maxRules} 를 함께 내려 준다. 상한(다우오피스와 같은 10개)을 화면이 상수로
 * 복사해 두면 서버와 어긋나는 날이 온다 — 서버가 알려 주는 값을 쓰면 "더 만들 수 있는가"
 * 판정이 한 곳에만 남는다.
 *
 * @param use           전체 자동전달 사용 여부
 * @param forwardEmail  전체 자동전달 주소. 꺼져 있으면 ""
 * @param keepOriginal  전달 후 원본을 남길지. <b>false 면 받은메일함(공용)에서 사라진다</b>
 * @param rules         예외 규칙 목록(sortOrder 순)
 * @param maxRules      예외 규칙 상한
 */
public record MailForwardDto(
        boolean use,
        String forwardEmail,
        boolean keepOriginal,
        List<MailForwardRuleDto> rules,
        int maxRules) {

    /**
     * 설정 행이 아직 없으면(=한 번도 저장한 적이 없으면) 꺼진 기본값을 만든다.
     *
     * <p>서버가 행을 미리 만들어 두지 않는 이유는 사용자 72명분 빈 행이 생겨 봐야
     * 얻는 것이 없고, "설정한 적 없음"과 "꺼 둠"을 구분할 이유도 없어서다.
     */
    public static MailForwardDto of(MailForwardSettingJdbcRow setting,
                                    List<MailForwardRuleDto> rules,
                                    int maxRules) {
        if (setting == null) {
            return new MailForwardDto(false, "", true, rules, maxRules);
        }
        return new MailForwardDto(
                "Y".equals(setting.useYn()),
                setting.forwardEmail() == null ? "" : setting.forwardEmail(),
                // 저장된 적 없는 값은 "남긴다" 로 본다. 원본 삭제는 되돌릴 수 없는 쪽이라
                // 기본값이 안전한 방향이어야 한다.
                !"N".equals(setting.keepOriginalYn()),
                rules,
                maxRules);
    }
}
