package com.yeokjeon.erp.chat.ws;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

/**
 * 사용자 실시간 푸시 WebSocket 엔드포인트 등록.
 *
 * <p>서블릿 context-path 가 {@code /api} 이므로 실제 접속 경로는 {@code /api/ws/chat} 이다.
 *
 * <p><b>경로 이름이 {@code /ws/chat} 이지만 메신저 전용이 아니다.</b> 메일 수신 알림
 * ({@code MailNotifyService})도 이 소켓으로 나간다. 알림 전용 경로
 * ({@code /ws/notify} 같은)를 새로 만들지 <b>않은</b> 이유는 셋이다.
 *
 * <ol>
 *   <li><b>소켓이 사용자당 두 개가 된다.</b> 이 채널은 서버→클라이언트 푸시 전용이라
 *       프레임 타입 하나만 늘리면 되는데, 굳이 연결·하트비트·재연결 로직을 한 벌 더
 *       돌릴 이유가 없다(프론트 {@code WebSocketChatService} 에 이미 다 있다).
 *   <li><b>{@code AuthTokenFilter} 를 건드려야 한다.</b> 브라우저 WebSocket 은 헤더를
 *       못 실어 {@code ?token=} 쿼리 인증에 의존하는데, 그 허용 목록이 {@code /ws/chat}
 *       하나로 좁혀져 있다. 새 경로를 만들면서 거기를 같이 안 고치면 <b>401 이라
 *       연결 자체가 안 된다</b>.
 *   <li><b>{@link ChatSessionRegistry} 가 이미 도메인 중립이다.</b> {@code userId → 세션}
 *       맵일 뿐이라 그대로 재사용된다.
 * </ol>
 *
 * <p>대신 "메신저를 안 켜면 알림도 안 온다"가 되지 않도록, 프론트는 메신저 화면이
 * 아니라 <b>앱 셸({@code MainFrameLayout})에서 로그인 직후</b> 이 소켓에 붙는다.
 */
@Configuration
@EnableWebSocket
@RequiredArgsConstructor
public class ChatWebSocketConfig implements WebSocketConfigurer {

    private final ChatWebSocketHandler chatWebSocketHandler;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        // 보안: "*" 로 두면 인터넷의 아무 웹사이트나 이 소켓에 접속할 수 있다.
        // WebConfig 의 CORS 허용 출처와 동일하게 제한한다.
        // (Origin 헤더가 없는 네이티브 앱 연결은 Spring 이 동일 출처로 취급해 허용한다.)
        registry.addHandler(chatWebSocketHandler, "/ws/chat")
                .setAllowedOriginPatterns(
                        "http://localhost:*",
                        "http://127.0.0.1:*",
                        // 운영 / 테스트 (구 test.yeokjeon.com 은 폐기)
                        "https://on.yeokjeon.com",
                        "https://on-test.yeokjeon.com",
                        "https://yeokjeon.com",
                        "https://www.yeokjeon.com");
    }
}
