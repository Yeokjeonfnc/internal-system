package com.yeokjeon.erp.mail.support;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Locale;

/**
 * 수신확인 추적픽셀 HTML 조각 (mal001-G).
 *
 * <p><b>이 기능의 정확도에 대한 경고 — 반드시 화면에도 같은 취지를 안내할 것.</b>
 * 추적픽셀은 "수신자의 메일 클라이언트가 원격 이미지를 실제로 내려받았는가"만 알 수 있다.
 * 다음 경우에는 <b>읽었는데도 수신확인이 잡히지 않는다</b>.
 * <ul>
 *   <li>Gmail·Outlook·네이버 등 대부분의 웹메일이 기본값으로 외부 이미지를 차단한다
 *       (사용자가 "이미지 표시"를 눌러야 비로소 요청이 온다)</li>
 *   <li>텍스트 전용으로 읽거나, 미리보기 창에서만 스쳐 지나간 경우</li>
 *   <li>회사 메일 게이트웨이가 본문의 외부 링크를 제거하는 경우</li>
 * </ul>
 * 반대로 <b>읽지 않았는데 잡히는</b> 경우도 있다 — Gmail 이미지 프록시나 보안 스캐너가
 * 배달 시점에 이미지를 미리 받아 두면 즉시 열람으로 기록된다.
 *
 * <p>즉 "수신확인 안 됨 = 안 읽음" 이 아니다. 다우오피스도 같은 한계를 FAQ 로 안내하고
 * 있고(자사 메일 사용자끼리만 정확), 우리도 사내 발송 이외에는 참고값으로만 봐야 한다.
 * 그래서 UI 문구는 "읽지 않음"이 아니라 "확인되지 않음"이어야 한다.
 *
 * <p>텍스트 파트(text/plain)에는 아무것도 넣지 않는다. 평문에는 이미지를 심을 수 없고,
 * 눈에 보이는 URL 을 남기면 수신자에게 추적 사실만 드러내고 얻는 것은 없다.
 */
public final class MailTrackingPixel {

    /**
     * 1x1 투명 GIF 원본 바이트(43바이트).
     *
     * <p>엔드포인트 응답 본문으로도 그대로 쓴다. 파일로 두지 않고 상수로 박은 이유는
     * 클래스패스 리소스 로딩 실패라는 경우의 수를 없애기 위해서다 — 추적픽셀이
     * 500 을 뱉으면 수신자 메일 본문에 깨진 이미지 아이콘이 뜬다.
     */
    private static final byte[] TRANSPARENT_GIF_1X1 = Base64.getDecoder().decode(
            "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7");

    private MailTrackingPixel() {}

    /** 엔드포인트가 돌려줄 1x1 투명 GIF. 호출자마다 복사본을 준다(배열은 불변이 아니다). */
    public static byte[] transparentGif() {
        return TRANSPARENT_GIF_1X1.clone();
    }

    /**
     * HTML 본문 끝에 추적픽셀을 심는다.
     *
     * <p>{@code </body>} 앞에 넣고, 없으면 맨 뒤에 붙인다. 앞쪽에 넣지 않는 이유는
     * 본문이 잘려 전달되는 클라이언트에서 픽셀이 먼저 보이면 레이아웃이 밀리기 때문이다.
     *
     * <p>{@code width/height} 를 속성과 style 양쪽에 모두 준다. Outlook 데스크톱은
     * CSS 를 상당 부분 무시해서 속성이 없으면 이미지 자리에 여백이 생기고,
     * 반대로 일부 웹메일은 속성을 무시하고 CSS 만 본다.
     *
     * @param html     원본 HTML. 비어 있으면 그대로 돌려준다(빈 본문에 픽셀만 보내지 않는다).
     * @param pixelUrl {@code https://.../api/mail/open/{token}.gif}
     * @return 픽셀이 삽입된 HTML
     */
    public static String inject(String html, String pixelUrl) {
        if (html == null || html.isBlank() || pixelUrl == null || pixelUrl.isBlank()) {
            return html;
        }
        String img = "<img src=\"" + escapeAttribute(pixelUrl) + "\""
                + " width=\"1\" height=\"1\" border=\"0\" alt=\"\""
                + " style=\"width:1px;height:1px;border:0;display:block;\" />";

        // 대소문자를 가리지 않고 마지막 </body> 를 찾는다. 인용된 원본 메일이 통째로
        // 딸려 오면 </body> 가 여러 번 나오는데, 그때는 가장 바깥(마지막) 것이 진짜다.
        int close = html.toLowerCase(Locale.ROOT).lastIndexOf("</body>");
        if (close < 0) {
            return html + img;
        }
        return html.substring(0, close) + img + html.substring(close);
    }

    /**
     * 이미 픽셀이 들어 있는지 본다.
     *
     * <p>발송 재시도 때 같은 본문에 픽셀이 두 번 붙는 것을 막는다. 두 개가 붙으면
     * 열람 1회에 open_cnt 가 2씩 오른다.
     */
    public static boolean contains(String html, String pixelUrl) {
        return html != null && pixelUrl != null && !pixelUrl.isBlank() && html.contains(pixelUrl);
    }

    /** 속성값 안에서 HTML 구조를 깨뜨릴 수 있는 문자만 막는다. URL 은 우리가 만들지만 방어적으로 둔다. */
    private static String escapeAttribute(String value) {
        return value.replace("&", "&amp;")
                .replace("\"", "&quot;")
                .replace("<", "&lt;")
                .replace(">", "&gt;");
    }

    /** 상수 초기화가 실제로 43바이트 GIF 인지 자체 확인용(테스트·디버깅). */
    static int gifByteLength() {
        return TRANSPARENT_GIF_1X1.length;
    }

    /** GIF 매직넘버 확인용. */
    static boolean looksLikeGif() {
        return TRANSPARENT_GIF_1X1.length > 3
                && new String(TRANSPARENT_GIF_1X1, 0, 3, StandardCharsets.US_ASCII).equals("GIF");
    }
}
