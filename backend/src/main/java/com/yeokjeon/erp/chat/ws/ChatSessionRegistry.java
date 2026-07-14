package com.yeokjeon.erp.chat.ws;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.io.IOException;
import java.util.Collection;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 접속 중인 WebSocket 세션을 사용자 ID 기준으로 보관한다.
 * 한 사용자가 여러 기기/탭에서 접속할 수 있으므로 세션을 Set 으로 관리한다.
 */
@Slf4j
@Component
public class ChatSessionRegistry {

    private final Map<String, Set<WebSocketSession>> sessionsByUser = new ConcurrentHashMap<>();

    public void register(String userId, WebSocketSession session) {
        if (userId == null || userId.isBlank()) {
            return;
        }
        sessionsByUser
                .computeIfAbsent(userId, k -> ConcurrentHashMap.newKeySet())
                .add(session);
    }

    public void remove(String userId, WebSocketSession session) {
        if (userId == null) {
            return;
        }
        Set<WebSocketSession> set = sessionsByUser.get(userId);
        if (set != null) {
            set.remove(session);
            if (set.isEmpty()) {
                sessionsByUser.remove(userId);
            }
        }
    }

    /** 지정한 사용자들에게 동일한 텍스트 프레임을 전송한다. */
    public void sendToUsers(Collection<String> userIds, String payload) {
        for (String userId : userIds) {
            Set<WebSocketSession> set = sessionsByUser.get(userId);
            if (set == null) {
                continue;
            }
            for (WebSocketSession session : set) {
                if (!session.isOpen()) {
                    continue;
                }
                try {
                    session.sendMessage(new TextMessage(payload));
                } catch (IOException e) {
                    log.warn("채팅 푸시 실패 (user={}): {}", userId, e.getMessage());
                }
            }
        }
    }
}
