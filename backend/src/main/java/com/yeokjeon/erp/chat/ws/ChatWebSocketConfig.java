package com.yeokjeon.erp.chat.ws;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

/**
 * 메신저 WebSocket 엔드포인트 등록.
 *
 * <p>서블릿 context-path 가 {@code /api} 이므로 실제 접속 경로는 {@code /api/ws/chat} 이다.
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
