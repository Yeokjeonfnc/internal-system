package com.yeokjeon.erp.chat.controller;

import com.yeokjeon.erp.chat.dto.ChatMemberDto;
import com.yeokjeon.erp.chat.dto.ChatMessageDto;
import com.yeokjeon.erp.chat.dto.ChatMessageSendRequest;
import com.yeokjeon.erp.chat.dto.ChatRoomCreateRequest;
import com.yeokjeon.erp.chat.dto.ChatRoomDto;
import com.yeokjeon.erp.chat.service.ChatService;
import com.yeokjeon.erp.common.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;

/** 메신저(msg001) REST API — 방/메시지/디렉터리. 실시간 푸시는 /ws/chat 소켓. */
@RestController
@RequestMapping("/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;

    @GetMapping("/rooms")
    public ResponseEntity<ApiResponse<List<ChatRoomDto>>> listRooms(
            @RequestParam String userId) {
        return ResponseEntity.ok(ApiResponse.success(chatService.listRooms(userId)));
    }

    @PostMapping("/rooms")
    public ResponseEntity<ApiResponse<ChatRoomDto>> createRoom(
            @RequestParam String userId,
            @Valid @RequestBody ChatRoomCreateRequest body) {
        return ResponseEntity.ok(
                ApiResponse.success("대화방이 생성되었습니다.", chatService.createRoom(userId, body)));
    }

    @GetMapping("/rooms/{roomIdx}/messages")
    public ResponseEntity<ApiResponse<List<ChatMessageDto>>> listMessages(
            @PathVariable int roomIdx, @RequestParam String userId) {
        return ResponseEntity.ok(
                ApiResponse.success(chatService.listMessages(userId, roomIdx)));
    }

    @PostMapping("/rooms/{roomIdx}/messages")
    public ResponseEntity<ApiResponse<ChatMessageDto>> sendMessage(
            @PathVariable int roomIdx,
            @RequestParam String userId,
            @Valid @RequestBody ChatMessageSendRequest body) {
        return ResponseEntity.ok(
                ApiResponse.success(chatService.sendMessage(userId, roomIdx, body.text())));
    }

    @PostMapping("/rooms/{roomIdx}/read")
    public ResponseEntity<ApiResponse<Void>> markRead(
            @PathVariable int roomIdx, @RequestParam String userId) {
        chatService.markRead(userId, roomIdx);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    /** 대화방을 본인 목록에서 숨김(소프트 삭제). */
    @PostMapping("/rooms/{roomIdx}/hide")
    public ResponseEntity<ApiResponse<Void>> hideRoom(
            @PathVariable int roomIdx, @RequestParam String userId) {
        chatService.hideRoom(userId, roomIdx);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    /** 메시지 삭제(소프트 삭제) — 본인이 보낸 메시지만 가능. */
    @PostMapping("/messages/{messageIdx}/delete")
    public ResponseEntity<ApiResponse<Void>> deleteMessage(
            @PathVariable long messageIdx, @RequestParam String userId) {
        chatService.deleteMessage(userId, messageIdx);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @PostMapping("/rooms/{roomIdx}/attachments")
    public ResponseEntity<ApiResponse<ChatMessageDto>> uploadAttachment(
            @PathVariable int roomIdx,
            @RequestParam String userId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "caption", required = false) String caption) {
        return ResponseEntity.ok(
                ApiResponse.success(chatService.sendAttachment(userId, roomIdx, file, caption)));
    }

    @GetMapping("/attachments/{messageIdx}/download")
    public ResponseEntity<Resource> downloadAttachment(
            @PathVariable long messageIdx,
            @RequestParam String userId,
            @RequestParam(value = "download", required = false) boolean forceDownload) {
        ChatService.AttachmentPayload payload = chatService.getAttachment(userId, messageIdx);
        String encoded = URLEncoder.encode(payload.fileName(), StandardCharsets.UTF_8)
                .replace("+", "%20");
        // 이미지는 미리보기를 위해 inline, 그 외 파일은 다운로드(attachment).
        // ?download=true 면 이미지도 강제로 내려받게 한다.
        //
        // 보안: contentType 은 업로더(클라이언트)가 보낸 값이라 신뢰할 수 없다.
        // image/svg+xml 처럼 스크립트를 품을 수 있는 타입을 inline 으로 내려주면
        // 같은 출처에서 실행되어 저장형 XSS 가 된다. 그래서 inline 은 안전한
        // 래스터 이미지 타입만 허용하고, 그 외에는 무조건 attachment 로 내린다.
        boolean inline = !forceDownload && isInlineSafeImage(payload.contentType());
        String disposition = inline ? "inline" : "attachment";
        return ResponseEntity.ok()
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        disposition + "; filename=\"" + payload.fileName()
                                + "\"; filename*=UTF-8''" + encoded)
                // 브라우저가 선언된 타입을 무시하고 스니핑해서 실행하는 것도 차단.
                .header("X-Content-Type-Options", "nosniff")
                .contentType(MediaType.parseMediaType(
                        inline ? payload.contentType() : MediaType.APPLICATION_OCTET_STREAM_VALUE))
                .body(payload.resource());
    }

    @GetMapping("/directory")
    public ResponseEntity<ApiResponse<List<ChatMemberDto>>> directory(
            @RequestParam String userId) {
        return ResponseEntity.ok(ApiResponse.success(chatService.directory(userId)));
    }

    /** inline 미리보기를 허용할 이미지 타입 — 스크립트 실행이 불가능한 래스터 포맷만. */
    private static boolean isInlineSafeImage(String contentType) {
        if (contentType == null) {
            return false;
        }
        String t = contentType.trim().toLowerCase();
        int semicolon = t.indexOf(';');
        if (semicolon >= 0) {
            t = t.substring(0, semicolon).trim();
        }
        return t.equals("image/jpeg")
                || t.equals("image/png")
                || t.equals("image/gif")
                || t.equals("image/webp")
                || t.equals("image/bmp");
    }
}
