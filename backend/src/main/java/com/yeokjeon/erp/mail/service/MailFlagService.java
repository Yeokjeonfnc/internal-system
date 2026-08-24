package com.yeokjeon.erp.mail.service;

import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.mail.dto.MailListItemDto;
import com.yeokjeon.erp.mail.dto.MailMstJdbcRow;
import com.yeokjeon.erp.mail.dto.MailUpdateFlagsRequestDto;
import com.yeokjeon.erp.mail.mapper.MailMstMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 메일 상태 플래그(읽음·스팸·담당자·연결) 변경.
 *
 * <p>조회 서비스와 나눈 이유: 목록/상세는 {@code readOnly} 로 묶어 두는데,
 * "상세를 열면 읽음 처리" 같은 쓰기가 그 안에 섞이면 readOnly 전제가 깨진다.
 * 컨트롤러가 조회 후 이 서비스를 따로 부르는 구조로 둔다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailFlagService {

    private final MailMstMapper mailMstMapper;

    /**
     * 플래그 일괄 변경.
     *
     * <p>요청 DTO 의 필드는 전부 nullable 이고, null 인 항목은 XML 의
     * {@code COALESCE(#{...}, 기존컬럼)} 이 그대로 두게 돼 있다. 그래서 화면이
     * "읽음만" 보내든 "담당자만" 보내든 나머지를 덮어쓰지 않는다.
     */
    @Transactional
    public MailListItemDto updateFlags(long mailIdx, MailUpdateFlagsRequestDto body, String callerUserId) {
        if (body == null) {
            throw new IllegalArgumentException("변경할 내용이 없습니다.");
        }
        requireMail(mailIdx);
        int updated = mailMstMapper.updateFlags(mailIdx, body);
        if (updated == 0) {
            throw new IllegalStateException("메일 상태 변경에 실패했습니다.");
        }
        log.debug("메일 플래그 변경 mailIdx={} by={}", mailIdx, callerUserId);
        return toItem(mailIdx);
    }

    /** 상세 진입 시 읽음 처리 등 단일 플래그 변경. */
    @Transactional
    public MailListItemDto markRead(long mailIdx, boolean read) {
        requireMail(mailIdx);
        mailMstMapper.updateReadYn(mailIdx, read ? "Y" : "N");
        return toItem(mailIdx);
    }

    /**
     * 소프트 삭제.
     *
     * <p>물리 삭제하지 않는 이유는 mail_body/mail_att/mail_event_log 가 전부
     * {@code ON DELETE CASCADE} 로 매달려 있어 한 번 지우면 배달 이력까지 사라지기 때문이다.
     * 메일 이력은 감사 자료라 화면에서만 감춘다.
     */
    @Transactional
    public void softDelete(long mailIdx, String callerUserId) {
        requireMail(mailIdx);
        int deleted = mailMstMapper.softDelete(mailIdx);
        if (deleted == 0) {
            throw new IllegalStateException("메일 삭제에 실패했습니다.");
        }
        log.info("메일 삭제 mailIdx={} by={}", mailIdx, callerUserId);
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    private MailMstJdbcRow requireMail(long mailIdx) {
        MailMstJdbcRow row = mailMstMapper.selectByIdx(mailIdx);
        if (row == null || Boolean.TRUE.equals(row.deletedYn())) {
            throw new ResourceNotFoundException("메일", "mailIdx", mailIdx);
        }
        return row;
    }

    private MailListItemDto toItem(long mailIdx) {
        MailMstJdbcRow row = mailMstMapper.selectByIdx(mailIdx);
        if (row == null) {
            throw new ResourceNotFoundException("메일", "mailIdx", mailIdx);
        }
        return MailListItemDto.fromRow(row);
    }
}
