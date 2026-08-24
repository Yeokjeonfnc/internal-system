package com.yeokjeon.erp.mail.support;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * HTML 본문 → 평문 변환.
 *
 * <p>수신 메일의 {@code text} 파트가 비어 있는 경우가 흔하다(HTML 전용 발송 시스템).
 * 그런 메일은 목록 미리보기({@code snippet})와 본문 검색({@code search_txt}) 을
 * 만들 재료가 없어진다. 그래서 수집 시점에 딱 한 번 변환해 {@code mail_body.body_text} 에
 * 저장한다 — 조회할 때마다 변환하면 목록 한 화면에 100번씩 정규식을 돌리게 된다.
 *
 * <p>Jsoup 같은 파서를 쓰지 않는 이유: 새 의존성을 추가하지 않는다는 제약이 있고,
 * 여기서 만드는 값은 화면에 그대로 렌더링되는 HTML 이 아니라 "검색·미리보기용 평문"이라
 * 태그를 정확히 해석할 필요가 없다. 실제 본문 렌더링은 프런트가
 * {@code body_html} 을 따로 받아 처리한다.
 */
public final class MailHtmlToText {

    /** 내용 자체가 화면에 보이지 않는 블록. 태그만 지우면 CSS·JS 코드가 본문으로 남는다. */
    private static final Pattern INVISIBLE_BLOCK = Pattern.compile(
            "(?is)<(script|style|head|title)[^>]*>.*?</\\1>");
    /** 줄바꿈으로 바꿔야 문단이 붙어 버리지 않는 태그들. */
    private static final Pattern LINE_BREAK_TAG = Pattern.compile(
            "(?i)<\\s*/?\\s*(br|p|div|tr|li|h[1-6]|table|blockquote|hr)\\b[^>]*>");
    private static final Pattern ANY_TAG = Pattern.compile("(?s)<[^>]*>");
    private static final Pattern HTML_COMMENT = Pattern.compile("(?s)<!--.*?-->");
    private static final Pattern NUMERIC_ENTITY = Pattern.compile("&#(x?)([0-9a-fA-F]+);");
    private static final Pattern MULTI_BLANK_LINE = Pattern.compile("\\n{3,}");
    private static final Pattern TRAILING_SPACE = Pattern.compile("[ \\t]+\\n");

    private MailHtmlToText() {
    }

    /** HTML 을 평문으로. null/빈 값이면 빈 문자열. */
    public static String toPlainText(String html) {
        if (html == null || html.isBlank()) {
            return "";
        }
        String text = html;
        text = HTML_COMMENT.matcher(text).replaceAll(" ");
        text = INVISIBLE_BLOCK.matcher(text).replaceAll("\n");
        text = LINE_BREAK_TAG.matcher(text).replaceAll("\n");
        text = ANY_TAG.matcher(text).replaceAll(" ");
        text = unescape(text);
        text = text.replace('\r', '\n')
                .replace((char) 0x00A0, ' ')
                .replace((char) 0x200B, ' ');
        // 줄 안의 연속 공백만 압축한다. 줄바꿈까지 없애면 문단 구분이 사라져
        // 미리보기가 한 덩어리로 뭉개진다.
        text = text.replaceAll("[ \\t\\x0B\\f]+", " ");
        text = TRAILING_SPACE.matcher(text).replaceAll("\n");
        text = MULTI_BLANK_LINE.matcher(text).replaceAll("\n\n");
        return text.trim();
    }

    /**
     * 목록 미리보기용 한 줄 요약({@code mail_mst.snippet}).
     * 줄바꿈을 공백으로 눕히고 maxChars 로 자른다.
     */
    public static String snippet(String text, int maxChars) {
        if (text == null || text.isBlank() || maxChars <= 0) {
            return "";
        }
        String flat = text.replaceAll("\\s+", " ").trim();
        if (flat.length() <= maxChars) {
            return flat;
        }
        return flat.substring(0, maxChars).trim() + "…";
    }

    /** 평문/HTML 중 쓸 수 있는 쪽으로 미리보기를 만든다. */
    public static String snippetOf(String bodyText, String bodyHtml, int maxChars) {
        String source = bodyText != null && !bodyText.isBlank() ? bodyText : toPlainText(bodyHtml);
        return snippet(source, maxChars);
    }

    /**
     * HTML 엔티티 복원.
     *
     * <p>전부 처리하지 않고 메일 본문에 실제로 나오는 것만 다룬다. 목적이 검색·미리보기라
     * 못 푼 엔티티가 몇 개 남아도 기능이 깨지지 않는다.
     */
    public static String unescape(String value) {
        if (value == null || value.indexOf('&') < 0) {
            return value == null ? "" : value;
        }
        String text = value
                .replace("&nbsp;", " ")
                .replace("&ensp;", " ")
                .replace("&emsp;", " ")
                .replace("&lt;", "<")
                .replace("&gt;", ">")
                .replace("&quot;", "\"")
                .replace("&apos;", "'")
                .replace("&#39;", "'")
                .replace("&hellip;", "…")
                .replace("&mdash;", "—")
                .replace("&ndash;", "–");

        Matcher matcher = NUMERIC_ENTITY.matcher(text);
        StringBuilder out = new StringBuilder(text.length());
        while (matcher.find()) {
            String replacement;
            try {
                int radix = matcher.group(1).isEmpty() ? 10 : 16;
                int codePoint = Integer.parseInt(matcher.group(2), radix);
                replacement = Character.isValidCodePoint(codePoint)
                        ? new String(Character.toChars(codePoint))
                        : matcher.group();
            } catch (RuntimeException e) {
                // 숫자가 아니거나 범위를 벗어난 엔티티는 원문 그대로 둔다.
                replacement = matcher.group();
            }
            matcher.appendReplacement(out, Matcher.quoteReplacement(replacement));
        }
        matcher.appendTail(out);

        // &amp; 는 맨 마지막에 푼다. 먼저 풀면 &amp;lt; 가 < 로 두 번 풀려 버린다.
        return out.toString().replace("&amp;", "&");
    }
}
