package com.yeokjeon.erp.chat.ws;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.yeokjeon.erp.chat.dto.ChatMessageDto;
import com.yeokjeon.erp.chat.dto.ChatRoomDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 채팅 도메인 이벤트를 접속 중인 멤버들에게 WebSocket 으로 푸시한다.
 * 프레임 형식은 프론트 WebSocketChatService 와 합의된 JSON 이다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ChatEventPublisher {

    private final ChatSessionRegistry registry;
    private final ObjectMapper objectMapper;

    /** 신규 메시지: {"type":"message","message":{...}} */
    public void publishMessage(Collection<String> memberUserIds, ChatMessageDto message) {
        Map<String, Object> frame = new LinkedHashMap<>();
        frame.put("type", "message");
        frame.put("message", message);
        send(memberUserIds, frame);
    }

    /** 새 방 생성: {"type":"roomCreated","room":{...}} */
    public void publishRoomCreated(Collection<String> memberUserIds, ChatRoomDto room) {
        Map<String, Object> frame = new LinkedHashMap<>();
        frame.put("type", "roomCreated");
        frame.put("room", room);
        send(memberUserIds, frame);
    }

    /** 메시지 삭제: {"type":"messageDeleted","roomIdx":..,"messageIdx":..} */
    public void publishMessageDeleted(
            Collection<String> memberUserIds, int roomIdx, long messageIdx) {
        Map<String, Object> frame = new LinkedHashMap<>();
        frame.put("type", "messageDeleted");
        frame.put("roomIdx", String.valueOf(roomIdx));
        frame.put("messageIdx", String.valueOf(messageIdx));
        send(memberUserIds, frame);
    }

    private void send(Collection<String> memberUserIds, Map<String, Object> frame) {
        try {
            String payload = objectMapper.writeValueAsString(frame);
            registry.sendToUsers(memberUserIds, payload);
        } catch (Exception e) {
            log.warn("채팅 이벤트 직렬화 실패: {}", e.getMessage());
        }
    }
}
