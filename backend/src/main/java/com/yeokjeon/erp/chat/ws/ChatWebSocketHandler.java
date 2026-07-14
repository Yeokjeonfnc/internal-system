package com.yeokjeon.erp.chat.ws;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Map;

/**
 * 실시간 메신저 푸시 채널.
 *
 * <p>핸드셰이크 URL 의 {@code ?userId=...} 로 사용자를 식별하고 세션을 등록한다.
 * 방/메시지 조회·전송은 REST 로 처리하고, 이 소켓은 서버→클라이언트 푸시 전용이다.
 * 클라이언트가 보내는 프레임은 ping 정도만 처리한다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ChatWebSocketHandler extends TextWebSocketHandler {

    private static final String ATTR_USER_ID = "chatUserId";

    private final ChatSessionRegistry registry;

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        String userId = resolveUserId(session);
        if (userId == null || userId.isBlank()) {
            try {
                session.close(CloseStatus.POLICY_VIOLATION.withReason("userId required"));
            } catch (Exception ignore) {
                // no-op
            }
            return;
        }
        session.getAttributes().put(ATTR_USER_ID, userId);
        registry.register(userId, session);
        log.debug("채팅 소켓 연결: user={}", userId);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        // 푸시 전용 채널 — 클라이언트 keep-alive ping 만 응답.
        String payload = message.getPayload();
        if (payload != null && payload.contains("\"ping\"")) {
            try {
                session.sendMessage(new TextMessage("{\"type\":\"pong\"}"));
            } catch (Exception ignore) {
                // no-op
            }
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        Object userId = session.getAttributes().get(ATTR_USER_ID);
        if (userId != null) {
            registry.remove(userId.toString(), session);
            log.debug("채팅 소켓 종료: user={}", userId);
        }
    }

    private String resolveUserId(WebSocketSession session) {
        URI uri = session.getUri();
        if (uri == null || uri.getQuery() == null) {
            return null;
        }
        for (String pair : uri.getQuery().split("&")) {
            int eq = pair.indexOf('=');
            if (eq > 0 && "userId".equals(pair.substring(0, eq))) {
                return java.net.URLDecoder.decode(
                        pair.substring(eq + 1), StandardCharsets.UTF_8);
            }
        }
        return null;
    }

    /** 테스트/디버그용 — 세션에 저장된 사용자 ID. */
    public static String userIdOf(Map<String, Object> attributes) {
        Object v = attributes.get(ATTR_USER_ID);
        return v == null ? null : v.toString();
    }
}
