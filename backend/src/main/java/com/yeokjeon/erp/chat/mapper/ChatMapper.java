package com.yeokjeon.erp.chat.mapper;

import com.yeokjeon.erp.chat.dto.ChatMemberRow;
import com.yeokjeon.erp.chat.dto.ChatMessageInsertParam;
import com.yeokjeon.erp.chat.dto.ChatMessageRow;
import com.yeokjeon.erp.chat.dto.ChatRoomInsertParam;
import com.yeokjeon.erp.chat.dto.ChatRoomRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface ChatMapper {

    /** 내가 속한 방 목록 (마지막 메시지 + 안읽음 수 포함, 최신순). */
    List<ChatRoomRow> selectRoomsForUser(@Param("userId") String userId);

    /** 단일 방 정보 (내가 멤버일 때만). */
    ChatRoomRow selectRoom(@Param("roomIdx") int roomIdx, @Param("userId") String userId);

    /** 방 참여자 목록. */
    List<ChatMemberRow> selectMembers(@Param("roomIdx") int roomIdx);

    /** 방의 메시지 (시간순). */
    List<ChatMessageRow> selectMessages(@Param("roomIdx") int roomIdx);

    /** 단일 메시지 (전송 직후 발신자명 포함 재조회). */
    ChatMessageRow selectMessage(@Param("messageIdx") long messageIdx);

    /** 새 대화 상대 후보(사원) 목록 — 본인 제외. */
    List<ChatMemberRow> selectDirectory(@Param("userId") String userId);

    /** 동일 멤버 2명의 기존 1:1 방 idx (없으면 null). */
    Integer findDirectRoom(@Param("userId") String userId, @Param("otherId") String otherId);

    int insertRoom(ChatRoomInsertParam param);

    int insertMember(@Param("roomIdx") int roomIdx, @Param("userId") String userId);

    int insertMessage(ChatMessageInsertParam param);

    int touchRoom(@Param("roomIdx") int roomIdx);

    int markRead(@Param("roomIdx") int roomIdx, @Param("userId") String userId);

    /** 대화방을 본인 목록에서 숨김(소프트 삭제). */
    int hideRoom(@Param("roomIdx") int roomIdx, @Param("userId") String userId);

    /** 메시지 소프트 삭제 — 본인이 보낸 메시지만 삭제 가능. */
    int deleteMessage(@Param("messageIdx") long messageIdx, @Param("senderId") String senderId);

    /** 멤버 여부 확인. */
    int countMembership(@Param("roomIdx") int roomIdx, @Param("userId") String userId);
}
