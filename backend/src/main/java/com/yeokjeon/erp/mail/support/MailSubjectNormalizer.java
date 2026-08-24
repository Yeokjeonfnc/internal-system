package com.yeokjeon.erp.mail.support;

import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 제목 정규화 — 스레드 폴백 매칭 기준값({@code subject_norm}) 을 만든다.
 *
 * <p>References/In-Reply-To 헤더가 아예 없는 메일이 실무에 많다(웹 메일 폼,
 * 자동 발송 시스템, 일부 모바일 클라이언트). 그런 메일을 대화로 묶는 마지막 수단이
 * 제목 일치이고, 그러려면 {@code Re:}, {@code RE:}, {@code 답장:}, {@code FW:} 같은
 * 접두어를 벗겨 낸 같은 값이 나와야 한다.
 *
 * <p>접두어를 한 번만 벗기지 않고 반복해서 벗기는 이유: 여러 클라이언트를 거치면
 * {@code Re: 답장: FW: 견적 문의} 처럼 쌓인다.
 */
public final class MailSubjectNormalizer {

    /** {@code mail_mst.subject_norm} / {@code mail_thread_mst.subject_norm} 은 varchar(500). */
    private static final int SUBJECT_NORM_MAX = 500;

    /**
     * non-breaking space(U+00A0). 아웃룩·웹메일이 제목에 자주 섞어 넣는데
     * {@code \s} 로 잡히지 않아 그냥 두면 같은 제목이 다른 값으로 정규화된다.
     * 소스에 원문자를 넣으면 편집기마다 깨지므로 코드포인트로 정의한다.
     */
    private static final char NBSP = (char) 0x00A0;

    /**
     * 답장·전달 접두어. {@code Re[2]:} 처럼 횟수가 붙은 형태와 전각 콜론(：)도 받는다.
     * 한국어 접두어는 국내 메일 클라이언트가 실제로 붙이는 값들이다.
     */
    private static final Pattern REPLY_PREFIX = Pattern.compile(
            "^\\s*(?:re|res|rep|aw|antw|sv|vs|fw|fwd|forward|답장|회신|답신|전달|전송)"
                    + "\\s*(?:\\[\\d+\\]|\\(\\d+\\))?\\s*[:：]\\s*",
            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);

    private MailSubjectNormalizer() {
    }

    /**
     * 접두어 제거 → 공백 압축 → 소문자화 → 500자 절단.
     *
     * <p>소문자화까지 하는 이유는 {@code 견적 문의} 와 {@code 견적 문의} 대소문자 차이로
     * 같은 대화가 두 스레드로 갈리는 것을 막기 위해서다. 화면 표시용 제목은
     * {@code mail_mst.subject} 에 원문 그대로 따로 남는다.
     */
    public static String normalize(String subject) {
        if (subject == null) {
            return "";
        }
        // 줄바꿈이 섞인 폴딩 헤더와 non-breaking space 를 먼저 평범한 공백으로 만든다.
        String value = subject.replace(NBSP, ' ')
                .replace('\r', ' ')
                .replace('\n', ' ')
                .replace('\t', ' ')
                .trim();

        while (!value.isEmpty()) {
            Matcher matcher = REPLY_PREFIX.matcher(value);
            if (!matcher.find() || matcher.end() == 0) {
                break;
            }
            value = value.substring(matcher.end()).trim();
        }

        value = value.replaceAll("\\s+", " ").trim().toLowerCase(Locale.ROOT);
        return value.length() <= SUBJECT_NORM_MAX ? value : value.substring(0, SUBJECT_NORM_MAX);
    }

    /**
     * 원문 제목을 컬럼 길이에 맞게 자른다.
     * (제목이 500자를 넘는 스팸이 실제로 들어와 INSERT 가 터진 사례가 흔하다.)
     */
    public static String clipSubject(String subject) {
        if (subject == null) {
            return "";
        }
        String value = subject.replace('\r', ' ').replace('\n', ' ').trim();
        return value.length() <= SUBJECT_NORM_MAX ? value : value.substring(0, SUBJECT_NORM_MAX);
    }

    /** 답장 제목 만들기. 이미 {@code Re:} 가 붙어 있으면 또 붙이지 않는다. */
    public static String toReplySubject(String subject) {
        String value = subject == null ? "" : subject.trim();
        if (value.isEmpty()) {
            return "Re:";
        }
        if (REPLY_PREFIX.matcher(value).find()) {
            return clipSubject(value);
        }
        return clipSubject("Re: " + value);
    }
}
