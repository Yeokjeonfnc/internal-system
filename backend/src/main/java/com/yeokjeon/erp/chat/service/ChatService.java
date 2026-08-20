package com.yeokjeon.erp.chat.service;

import com.yeokjeon.erp.chat.dto.ChatMemberDto;
import com.yeokjeon.erp.chat.dto.ChatMemberRow;
import com.yeokjeon.erp.chat.dto.ChatMessageDto;
import com.yeokjeon.erp.chat.dto.ChatMessageInsertParam;
import com.yeokjeon.erp.chat.dto.ChatMessageRow;
import com.yeokjeon.erp.chat.dto.ChatRoomCreateRequest;
import com.yeokjeon.erp.chat.dto.ChatRoomDto;
import com.yeokjeon.erp.chat.dto.ChatRoomInsertParam;
import com.yeokjeon.erp.chat.dto.ChatRoomRow;
import com.yeokjeon.erp.chat.mapper.ChatMapper;
import com.yeokjeon.erp.chat.ws.ChatEventPublisher;
import com.yeokjeon.erp.config.FileStorageProperties;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ChatService {

    private final ChatMapper chatMapper;
    private final ChatEventPublisher eventPublisher;
    private final FileStorageProperties fileStorageProperties;

    private Path storageRoot;

    /** hidden_at 컬럼 존재 여부 캐시 — null 이면 아직 확인 전. */
    private volatile Boolean hiddenAtSupported;

    @PostConstruct
    void initStorageRoot() throws IOException {
        storageRoot = Path.of(fileStorageProperties.getStorageRoot())
                .toAbsolutePath()
                .normalize();
        Files.createDirectories(storageRoot);
    }

    public List<ChatRoomDto> listRooms(String userId) {
        String uid = requireUserId(userId);
        return chatMapper.selectRoomsForUser(uid, supportsHiddenAt()).stream()
                .map(this::toRoomDto)
                .collect(Collectors.toList());
    }

    public List<ChatMessageDto> listMessages(String userId, int roomIdx) {
        ensureMember(userId, roomIdx);
        return chatMapper.selectMessages(roomIdx).stream()
                .map(ChatService::toMessageDto)
                .collect(Collectors.toList());
    }

    public List<ChatMemberDto> directory(String userId) {
        String uid = requireUserId(userId);
        return chatMapper.selectDirectory(uid).stream()
                .map(ChatService::toMemberDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public ChatRoomDto createRoom(String userId, ChatRoomCreateRequest request) {
        String uid = requireUserId(userId);
        Set<String> memberIds = new LinkedHashSet<>();
        memberIds.add(uid);
        if (request.memberIds() != null) {
            for (String m : request.memberIds()) {
                if (StringUtils.hasText(m)) {
                    memberIds.add(m.trim());
                }
            }
        }
        if (memberIds.size() < 2) {
            throw new IllegalArgumentException("대화 상대를 선택하세요.");
        }

        boolean group = memberIds.size() > 2 || StringUtils.hasText(request.title());

        // 1:1 은 기존 방 재사용.
        if (!group) {
            String other = memberIds.stream()
                    .filter(id -> !id.equals(uid))
                    .findFirst()
                    .orElseThrow();
            Integer existing = chatMapper.findDirectRoom(uid, other);
            if (existing != null) {
                // 전에 숨겨 둔 방이면 되살린다 — 새 방을 만들면 과거 대화가 끊긴다.
                if (supportsHiddenAt()) {
                    chatMapper.unhideRoom(existing, uid);
                }
                return requireRoom(uid, existing);
            }
        }

        ChatRoomInsertParam param = new ChatRoomInsertParam();
        param.setTitle(group ? request.title() : null);
        param.setGroup(group);
        param.setCreatedBy(uid);
        chatMapper.insertRoom(param);
        int roomIdx = param.getRoomIdx();

        for (String m : memberIds) {
            chatMapper.insertMember(roomIdx, m);
        }

        ChatRoomDto dto = requireRoom(uid, roomIdx);
        eventPublisher.publishRoomCreated(memberIds, dto);
        return dto;
    }

    @Transactional
    public ChatMessageDto sendMessage(String userId, int roomIdx, String text) {
        String uid = requireUserId(userId);
        ensureMember(uid, roomIdx);
        if (!StringUtils.hasText(text)) {
            throw new IllegalArgumentException("메시지를 입력하세요.");
        }

        ChatMessageInsertParam param = new ChatMessageInsertParam();
        param.setRoomIdx(roomIdx);
        param.setSenderId(uid);
        param.setMsgTxt(text.trim());
        param.setMsgType("text");
        chatMapper.insertMessage(param);
        chatMapper.touchRoom(roomIdx);
        chatMapper.markRead(roomIdx, uid);

        ChatMessageRow row = chatMapper.selectMessage(param.getMessageIdx());
        ChatMessageDto dto = toMessageDto(row);

        List<String> members = chatMapper.selectMembers(roomIdx).stream()
                .map(ChatMemberRow::userId)
                .collect(Collectors.toList());
        eventPublisher.publishMessage(members, dto);
        return dto;
    }

    @Transactional
    public void markRead(String userId, int roomIdx) {
        String uid = requireUserId(userId);
        chatMapper.markRead(roomIdx, uid);
    }

    /**
     * 대화방 삭제 — 본인 목록에서만 숨긴다(소프트). 확인 다이얼로그가 약속한 대로
     * 새 메시지가 오면 다시 나타나며, 멤버십을 지우지 않으므로 그 사이의 메시지도 놓치지 않는다.
     */
    @Transactional
    public void hideRoom(String userId, int roomIdx) {
        String uid = requireUserId(userId);
        ensureMember(uid, roomIdx);
        chatMapper.hideRoom(roomIdx, uid, supportsHiddenAt());
    }

    /** 메시지 삭제(소프트 삭제) — 본인이 보낸 메시지만 가능. 멤버 전원에게 실시간 통지. */
    @Transactional
    public void deleteMessage(String userId, long messageIdx) {
        String uid = requireUserId(userId);
        ChatMessageRow row = chatMapper.selectMessage(messageIdx);
        if (row == null) {
            throw new ResourceNotFoundException("메시지", "messageIdx", messageIdx);
        }
        if (!uid.equals(row.senderId())) {
            throw new IllegalArgumentException("본인이 보낸 메시지만 삭제할 수 있습니다.");
        }
        if (chatMapper.deleteMessage(messageIdx, uid) == 0) {
            return; // 이미 삭제됨 — 멱등 처리.
        }
        List<String> members = chatMapper.selectMembers(row.roomIdx()).stream()
                .map(ChatMemberRow::userId)
                .collect(Collectors.toList());
        eventPublisher.publishMessageDeleted(members, row.roomIdx(), messageIdx);
    }

    /** 이미지/파일 첨부 메시지 전송. */
    @Transactional
    public ChatMessageDto sendAttachment(
            String userId, int roomIdx, MultipartFile file, String caption) {
        String uid = requireUserId(userId);
        ensureMember(uid, roomIdx);
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("첨부할 파일을 선택하세요.");
        }
        if (file.getSize() > fileStorageProperties.getMaxSizeBytes()) {
            throw new IllegalArgumentException("파일 크기는 50MB까지 가능합니다.");
        }

        String originalName = sanitizeName(file.getOriginalFilename());
        if (originalName.isBlank()) {
            throw new IllegalArgumentException("파일명을 확인할 수 없습니다.");
        }
        String storedName = UUID.randomUUID() + "_" + originalName;
        Path dir = roomDir(roomIdx);
        Path target = dir.resolve(storedName).normalize();
        if (!target.startsWith(dir)) {
            throw new IllegalArgumentException("잘못된 파일 경로입니다.");
        }
        try {
            Files.createDirectories(dir);
            Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            log.error("채팅 파일 저장 실패 roomIdx={} name={}", roomIdx, originalName, e);
            throw new IllegalStateException("파일 저장에 실패했습니다.");
        }

        String contentType = resolveContentType(file, originalName);
        boolean isImage = contentType.startsWith("image/");

        ChatMessageInsertParam param = new ChatMessageInsertParam();
        param.setRoomIdx(roomIdx);
        param.setSenderId(uid);
        param.setMsgTxt(StringUtils.hasText(caption) ? caption.trim() : null);
        param.setMsgType(isImage ? "image" : "file");
        param.setFileName(originalName);
        param.setStoredName(storedName);
        param.setContentType(contentType);
        param.setFileSize(file.getSize());
        chatMapper.insertMessage(param);
        chatMapper.touchRoom(roomIdx);
        chatMapper.markRead(roomIdx, uid);

        ChatMessageDto dto = toMessageDto(chatMapper.selectMessage(param.getMessageIdx()));
        List<String> members = chatMapper.selectMembers(roomIdx).stream()
                .map(ChatMemberRow::userId)
                .collect(Collectors.toList());
        eventPublisher.publishMessage(members, dto);
        return dto;
    }

    /** 첨부 파일 다운로드(또는 이미지 표시) — 방 멤버만 접근 가능. */
    public AttachmentPayload getAttachment(String userId, long messageIdx) {
        String uid = requireUserId(userId);
        ChatMessageRow row = chatMapper.selectMessage(messageIdx);
        if (row == null || row.storedName() == null) {
            throw new ResourceNotFoundException("첨부 파일", "messageIdx", messageIdx);
        }
        ensureMember(uid, row.roomIdx());
        Path filePath = roomDir(row.roomIdx()).resolve(row.storedName()).normalize();
        if (!Files.isRegularFile(filePath)) {
            throw new ResourceNotFoundException("첨부 파일", "messageIdx", messageIdx);
        }
        String contentType = StringUtils.hasText(row.contentType())
                ? row.contentType()
                : "application/octet-stream";
        return new AttachmentPayload(new FileSystemResource(filePath), row.fileName(), contentType);
    }

    private Path roomDir(int roomIdx) {
        return storageRoot.resolve("chat").resolve(String.valueOf(roomIdx)).normalize();
    }

    private static String sanitizeName(String name) {
        if (!StringUtils.hasText(name)) {
            return "";
        }
        return Path.of(name).getFileName().toString()
                .replaceAll("[\\\\/:*?\"<>|]", "_")
                .trim();
    }

    private static String resolveContentType(MultipartFile file, String fileName) {
        if (file.getContentType() != null
                && StringUtils.hasText(file.getContentType())
                && !"application/octet-stream".equalsIgnoreCase(file.getContentType())) {
            return file.getContentType().trim();
        }
        String lower = fileName.toLowerCase();
        if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
        if (lower.endsWith(".png")) return "image/png";
        if (lower.endsWith(".gif")) return "image/gif";
        if (lower.endsWith(".webp")) return "image/webp";
        if (lower.endsWith(".bmp")) return "image/bmp";
        if (lower.endsWith(".pdf")) return "application/pdf";
        return "application/octet-stream";
    }

    public record AttachmentPayload(Resource resource, String fileName, String contentType) {}

    // ── 매핑 헬퍼 ────────────────────────────────────────────────────────
    private ChatRoomDto toRoomDto(ChatRoomRow row) {
        List<ChatMemberDto> members = chatMapper.selectMembers(row.roomIdx()).stream()
                .map(ChatService::toMemberDto)
                .collect(Collectors.toList());
        return new ChatRoomDto(
                String.valueOf(row.roomIdx()),
                row.title(),
                Boolean.TRUE.equals(row.isGroup()),
                members,
                row.lastText(),
                row.lastAt(),
                row.unreadCount() == null ? 0 : row.unreadCount());
    }

    private ChatRoomDto requireRoom(String userId, int roomIdx) {
        ChatRoomRow row = chatMapper.selectRoom(roomIdx, userId);
        if (row == null) {
            throw new ResourceNotFoundException("채팅방", "roomIdx", roomIdx);
        }
        return toRoomDto(row);
    }

    private static ChatMemberDto toMemberDto(ChatMemberRow row) {
        return new ChatMemberDto(row.userId(), row.userName(), row.deptNm());
    }

    private static ChatMessageDto toMessageDto(ChatMessageRow row) {
        // 삭제된 메시지는 내용/첨부를 내려주지 않고 deleted=true 로만 표시한다.
        boolean deleted = Boolean.TRUE.equals(row.deleted());
        return new ChatMessageDto(
                String.valueOf(row.messageIdx()),
                String.valueOf(row.roomIdx()),
                row.senderId(),
                row.senderName(),
                deleted ? "" : row.text(),
                row.createdAt(),
                deleted ? "text" : (row.msgType() == null ? "text" : row.msgType()),
                deleted ? null : row.fileName(),
                deleted ? null : row.fileSize(),
                deleted ? null : row.contentType(),
                deleted);
    }

    /**
     * chat_room_member.hidden_at 컬럼 존재 여부.
     *
     * <p>운영 DB 에 마이그레이션이 아직 안 붙었을 수 있는데, 대화목록 조회는 메신저를 열 때마다
     * 도는 쿼리라 여기서 컬럼을 잘못 참조하면 메신저 전체가 죽는다. 스키마는 실행 중에 바뀌지
     * 않으므로 한 번만 확인해 캐시한다.
     */
    private boolean supportsHiddenAt() {
        Boolean cached = hiddenAtSupported;
        if (cached == null) {
            cached = chatMapper.countInformationSchemaColumns("chat_room_member", "hidden_at") > 0;
            if (!cached) {
                log.warn("chat_room_member.hidden_at 컬럼이 없어 대화방 삭제가 예전 방식(멤버십 제거)으로 동작합니다."
                        + " deploy/db/migrations/20260618_chat_room_member_hidden.sql 적용 필요.");
            }
            hiddenAtSupported = cached;
        }
        return cached;
    }

    private void ensureMember(String userId, int roomIdx) {
        String uid = requireUserId(userId);
        if (chatMapper.countMembership(roomIdx, uid) == 0) {
            throw new IllegalArgumentException("참여 중인 대화가 아닙니다.");
        }
    }

    private static String requireUserId(String userId) {
        if (!StringUtils.hasText(userId)) {
            throw new IllegalArgumentException("userId 가 필요합니다.");
        }
        return userId.trim();
    }
}
