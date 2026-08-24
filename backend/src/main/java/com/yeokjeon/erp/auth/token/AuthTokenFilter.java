package com.yeokjeon.erp.auth.token;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Set;

/**
 * 모든 API 요청의 로그인 여부를 검사한다.
 *
 * <p>기존 구조는 서버 검증이 전혀 없이 요청의 {@code ?userId=} 값을 그대로 신분으로 믿었다.
 * 이 필터는 두 가지를 강제한다.
 *
 * <ol>
 *   <li><b>토큰 필수</b> — 허용 목록을 제외한 모든 경로는 {@code Authorization: Bearer <토큰>}
 *       이 있어야 하며, 서명·만료가 유효해야 한다.
 *   <li><b>신분 일치</b> — 요청에 {@code userId} 파라미터가 있으면 토큰 주인과 같아야 한다.
 *       (남의 ID 를 적어 넣어 타인 행세하는 것을 차단. 엔드포인트 수정 없이 전 구간에 적용된다.)
 * </ol>
 *
 * <p>WebSocket 핸드셰이크는 브라우저 API 특성상 헤더를 넣을 수 없어 {@code ?token=} 쿼리로 받는다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AuthTokenFilter extends OncePerRequestFilter {

    /**
     * 토큰 없이 호출할 수 있는 경로(서블릿 context-path `/api` 를 제외한 값).
     *
     * <p>`/mail/webhook` 은 Resend 서버가 직접 POST 하는 엔드포인트라 우리 로그인 토큰을
     * 실을 방법이 없다. 대신 Svix 서명(svix-id/svix-timestamp/svix-signature)이 유일한
     * 방어선이므로, {@code SvixSignatureVerifier} 검증을 절대 우회하게 두지 말 것.
     *
     * <p>이 집합은 {@code contains} 완전일치로 비교한다 — 웹훅에 하위 경로를 만들면
     * 그 경로는 인증이 걸려 Resend 가 401 만 받고 이벤트를 넘기지 못한다.
     */
    private static final Set<String> PUBLIC_PATHS =
            Set.of("/auth/login", "/health", "/mail/webhook");

    /**
     * 완전일치로는 열 수 없어 접두사로 여는 경로.
     *
     * <p>{@code /mail/open/{token}.gif} 는 수신확인 추적픽셀이다. 경로 안에 토큰이
     * 들어가므로 {@link #PUBLIC_PATHS} 의 완전일치로는 구조적으로 등록할 수 없다.
     * 수신자의 메일 클라이언트가 부르는 요청이라 우리 로그인 토큰이 실릴 수 없고,
     * 인증을 걸어 두면 전부 401 이 되어 수신확인이 하나도 잡히지 않는다
     * (수신자 화면에는 깨진 이미지만 남는다).
     *
     * <p>토큰 자체가 방어선이다 — mail_idx 에서 HMAC 으로 유도한 값이라 서버 키
     * 없이는 위조할 수 없고, 유출돼도 열람 시각이 기록될 뿐 메일 내용은 나가지 않는다.
     */
    private static final String OPEN_PIXEL_PREFIX = "/mail/open/";

    /**
     * 쿼리 토큰({@code ?token=})을 허용하는 WebSocket 경로.
     *
     * <p>이름은 chat 이지만 메신저 전용 채널이 아니다 — 메일 수신 알림도 이 소켓으로
     * 나간다({@code ChatWebSocketConfig} 주석 참고). 실시간 푸시 경로를 새로 추가하는
     * 일이 생기면 <b>여기에도 반드시 함께 등록해야 한다</b>. 안 그러면 브라우저는
     * 헤더를 못 실어 토큰이 아예 전달되지 않고, 핸드셰이크가 401 로 끊긴다.
     */
    private static final String WS_PATH = "/ws/chat";

    /** 요청 처리 중 현재 로그인 사용자를 참조할 때 쓰는 속성 키. */
    public static final String ATTR_CURRENT_USER_ID = "authenticatedUserId";

    private final AuthTokenService authTokenService;
    private final TokenInvalidationRegistry tokenInvalidationRegistry;

    @Override
    protected boolean shouldNotFilter(@NonNull HttpServletRequest request) {
        // CORS 사전 요청(preflight)에는 인증 헤더가 실리지 않는다.
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }
        String path = pathWithinApi(request);
        return PUBLIC_PATHS.contains(path) || path.startsWith(OPEN_PIXEL_PREFIX);
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        String path = pathWithinApi(request);

        // 브라우저가 직접 여는 요청(WebSocket 핸드셰이크, <img src>·새 탭 다운로드)은
        // Authorization 헤더를 실을 수 없어 쿼리 토큰을 허용한다.
        // 그 외 경로는 헤더만 인정한다(토큰이 URL·접근로그에 남는 범위를 최소화).
        boolean allowQueryToken = path.startsWith(WS_PATH) || path.endsWith("/download");

        String token = bearerToken(request.getHeader("Authorization"));
        if (token == null && allowQueryToken) {
            token = request.getParameter("token");
        }

        AuthTokenService.Verified verified = authTokenService.verifyDetailed(token);
        if (verified == null) {
            log.debug("인증 실패(토큰 없음/무효): {} {}", request.getMethod(), path);
            reject(response, HttpServletResponse.SC_UNAUTHORIZED, "로그인이 필요합니다.");
            return;
        }
        String authenticatedUserId = verified.userId();

        // 비밀번호 변경·계정 삭제 이전에 발급된 토큰은 서명이 맞아도 받지 않는다.
        if (!tokenInvalidationRegistry.isStillValid(authenticatedUserId, verified.issuedAt())) {
            log.info("무효화된 토큰 차단: userId={} ({} {})", authenticatedUserId, request.getMethod(), path);
            reject(response, HttpServletResponse.SC_UNAUTHORIZED, "다시 로그인해 주세요.");
            return;
        }

        /*
         * 요청이 주장하는 신분과 토큰 주인이 다르면 차단한다.
         *
         * **주의: `userId` 는 예약된 파라미터 이름이다.** 이 필터는 그 이름의
         * 파라미터를 무조건 "호출자 본인"으로 해석한다. "남의 ID" 나 "아직 없는
         * 새 ID" 를 받아야 하는 API 는 반드시 **다른 이름**을 쓸 것
         * (예: check-user-id 는 candidateUserId). 이름을 재사용하면 그 API 는
         * 슈퍼관리자까지 포함해 항상 403 이 되고, 원인이 화면에 드러나지 않는다.
         */
        String claimedUserId = request.getParameter("userId");
        if (claimedUserId != null
                && !claimedUserId.isBlank()
                && !claimedUserId.equals(authenticatedUserId)) {
            log.warn(
                    "신분 불일치 차단: 토큰={} 요청={} ({} {})",
                    authenticatedUserId,
                    claimedUserId,
                    request.getMethod(),
                    path);
            reject(response, HttpServletResponse.SC_FORBIDDEN, "다른 사용자의 권한으로 요청할 수 없습니다.");
            return;
        }

        request.setAttribute(ATTR_CURRENT_USER_ID, authenticatedUserId);
        filterChain.doFilter(request, response);
    }

    /** context-path(`/api`)를 뺀 실제 매핑 경로. */
    private static String pathWithinApi(HttpServletRequest request) {
        String uri = request.getRequestURI();
        String contextPath = request.getContextPath();
        if (contextPath != null && !contextPath.isEmpty() && uri.startsWith(contextPath)) {
            uri = uri.substring(contextPath.length());
        }
        return uri.isEmpty() ? "/" : uri;
    }

    private static String bearerToken(String header) {
        if (header == null) {
            return null;
        }
        String prefix = "Bearer ";
        return header.regionMatches(true, 0, prefix, 0, prefix.length())
                ? header.substring(prefix.length()).trim()
                : null;
    }

    private static void reject(HttpServletResponse response, int status, String message)
            throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.getWriter()
                .write("{\"success\":false,\"message\":\"" + message + "\",\"data\":null}");
    }
}
