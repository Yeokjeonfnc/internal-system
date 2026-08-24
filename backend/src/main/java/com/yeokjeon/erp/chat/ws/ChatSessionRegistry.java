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
 *
 * <p><b>이름은 chat 이지만 채팅 전용이 아니다.</b> 이 클래스에는 방·메시지 같은 채팅
 * 개념이 하나도 없고 {@code userId → 세션} 맵과 {@code sendToUsers} 뿐이다. 그래서
 * 메일 수신 알림({@code MailNotifyService})도 같은 소켓으로 나간다. 사용자 한 명당
 * 소켓 하나만 유지하기 위한 의도적인 재사용이니, 앞으로도 여기에 특정 도메인
 * (채팅이든 메일이든) 지식을 넣지 말 것.
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

    /**
     * 지정한 사용자들에게 동일한 텍스트 프레임을 전송한다.
     *
     * <p>세션 하나가 실패해도 나머지 전송은 계속한다 — 푸시는 어느 도메인에서든
     * 부가 기능이라, 한 사람의 죽은 소켓 때문에 다른 사람이 못 받으면 안 된다.
     */
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
                    // 도메인 중립이라 "채팅"이라고 쓰지 않는다(메일 알림도 여기로 나간다).
                    log.warn("소켓 푸시 실패 (user={}): {}", userId, e.getMessage());
                }
            }
        }
    }
}
