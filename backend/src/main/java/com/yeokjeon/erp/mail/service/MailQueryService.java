package com.yeokjeon.erp.mail.service;

import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.mail.config.ResendProperties;
import com.yeokjeon.erp.mail.dto.MailAddrDtlJdbcRow;
import com.yeokjeon.erp.mail.dto.MailCountsDto;
import com.yeokjeon.erp.mail.dto.MailCountsJdbcRow;
import com.yeokjeon.erp.mail.dto.MailDetailDto;
import com.yeokjeon.erp.mail.dto.MailEventLogJdbcRow;
import com.yeokjeon.erp.mail.dto.MailFolderCountDto;
import com.yeokjeon.erp.mail.dto.MailListItemDto;
import com.yeokjeon.erp.mail.dto.MailListQuery;
import com.yeokjeon.erp.mail.dto.MailMstJdbcRow;
import com.yeokjeon.erp.mail.dto.MailReceiptDto;
import com.yeokjeon.erp.mail.dto.MailReceiptRecipientDto;
import com.yeokjeon.erp.mail.dto.MailThreadDto;
import com.yeokjeon.erp.mail.dto.MailThreadMstJdbcRow;
import com.yeokjeon.erp.mail.mapper.MailAddrMapper;
import com.yeokjeon.erp.mail.mapper.MailAttMapper;
import com.yeokjeon.erp.mail.mapper.MailBodyMapper;
import com.yeokjeon.erp.mail.mapper.MailEventLogMapper;
import com.yeokjeon.erp.mail.mapper.MailMstMapper;
import com.yeokjeon.erp.mail.mapper.MailThreadMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * 메일 조회 전담 서비스.
 *
 * <p>읽기만 하는 경로를 쓰기 서비스와 분리한 이유: 목록·상세는 화면이 뜰 때마다 불리는
 * 가장 뜨거운 경로라 {@code readOnly = true} 로 못 박아 두면 실수로 UPDATE 가 섞여도
 * 즉시 드러나고, JPA 세션 플러시도 건너뛴다.
 *
 * <p>여기서는 절대 외부 HTTP 를 부르지 않는다. Resend 호출은 워커·발송 서비스만 한다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailQueryService {

    /** 목록 기본·최대 건수. 화면은 페이저 없이 전량 로드라 상한이 안전장치다. */
    private static final int DEFAULT_LIMIT = 100;
    private static final int MAX_LIMIT = 500;
    /**
     * 1자 키워드는 trigram(3글자 단위) 후보를 아예 못 뽑아 인덱스가 무력해지고
     * 전체 스캔이 된다. 서버 부하를 지키기 위해 조건 자체를 버린다.
     */
    private static final int MIN_KEYWORD_LEN = 2;
    /** 상세 화면 타임라인에 보여줄 배달 이벤트 상한. */
    private static final int EVENT_LIMIT = 100;

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    private final MailMstMapper mailMstMapper;
    private final MailBodyMapper mailBodyMapper;
    private final MailAddrMapper mailAddrMapper;
    private final MailAttMapper mailAttMapper;
    private final MailEventLogMapper mailEventLogMapper;
    private final MailThreadMapper mailThreadMapper;
    private final ResendProperties properties;

    @Transactional(readOnly = true)
    public List<MailListItemDto> listByFolder(MailListQuery query) {
        return mailMstMapper.selectByFolder(normalize(query)).stream()
                .map(MailListItemDto::fromRow)
                .toList();
    }

    @Transactional(readOnly = true)
    public int countByFolder(MailListQuery query) {
        return mailMstMapper.countByFolder(normalize(query));
    }

    @Transactional(readOnly = true)
    public MailDetailDto findDetail(long mailIdx) {
        MailMstJdbcRow mst = requireMail(mailIdx);
        // 본문·참여자·첨부·이벤트를 한 트랜잭션 안에서 모아 상세 한 덩어리로 만든다.
        // 각각 별도 요청으로 쪼개면 화면 한 번 여는 데 왕복이 다섯 번 생긴다.
        return MailDetailDto.of(
                mst,
                mailBodyMapper.selectByMailIdx(mailIdx),
                mailAddrMapper.selectByMailIdx(mailIdx),
                mailAttMapper.selectByMailIdx(mailIdx),
                mailEventLogMapper.selectByMailIdx(mailIdx, EVENT_LIMIT));
    }

    @Transactional(readOnly = true)
    public MailThreadDto findThread(long threadIdx) {
        MailThreadMstJdbcRow thread = mailThreadMapper.selectByIdx(threadIdx);
        if (thread == null) {
            throw new ResourceNotFoundException("메일 스레드", "threadIdx", threadIdx);
        }
        List<MailListItemDto> mails = mailMstMapper.selectByThreadIdx(threadIdx).stream()
                .map(MailListItemDto::fromRow)
                .toList();
        return new MailThreadDto(
                thread.threadIdx(),
                thread.subjectNorm() == null ? "" : thread.subjectNorm(),
                // mail_thread_mst.mail_cnt 는 touch 로 갱신되는 캐시라 삭제 직후 잠깐 어긋난다.
                // 방금 함께 읽어 온 실제 목록 길이가 언제나 정확하므로 그쪽을 쓴다.
                mails.size(),
                toSeoul(thread.firstMailAt()),
                toSeoul(thread.lastMailAt()),
                mails);
    }

    /**
     * 사이드바 뱃지용 건수 (mal001-I).
     *
     * <p>기본 메일함 집계와 사용자 정의 메일함 집계를 <b>같은 트랜잭션</b>에서 읽는다.
     * 두 번 나눠 부르면 그 사이에 메일이 들어와 "받은메일함 10 / 내 메일함 합계 11" 처럼
     * 사이드바 숫자끼리 안 맞는 순간이 생긴다.
     *
     * @param ownerUserId null/"" 이면 전체 집계. 그때 사용자 정의 메일함은 빈 목록이다 —
     *                    메일함은 개인 소유물이라 "전체 사용자의 메일함"이라는 개념이 없다.
     */
    @Transactional(readOnly = true)
    public MailCountsDto counts(String ownerUserId) {
        String owner = blankToNull(ownerUserId);
        MailCountsJdbcRow row = mailMstMapper.selectFolderCounts(owner);
        List<MailFolderCountDto> folders = owner == null
                ? List.of()
                : mailMstMapper.selectCustomFolderCounts(owner);
        // 메일이 한 통도 없으면 집계 쿼리가 행을 안 줄 수 있다. 화면 배지가 깨지지 않게
        // 0 으로 채우되, 사용자 메일함 목록은 살아 있으므로 그대로 실어 보낸다.
        return MailCountsDto.fromRow(row, folders);
    }

    /**
     * 수신확인 조회 (mal001-G) — 수신자별 확인 상태.
     *
     * <p><b>지금은 열람 추적이 메일 단위다.</b> 추적픽셀 URL 에 mail_idx 만 들어 있어서
     * 누가 열었는지 구분할 수 없다. 그런데도 응답을 수신자 배열로 만드는 이유는, 나중에
     * 픽셀 토큰에 수신자를 넣어 수신자별 추적으로 바꿀 때 <b>화면을 고치지 않아도 되게</b>
     * 하기 위해서다. 응답 모양이 바뀌면 Flutter 모델과 목록 위젯이 전부 따라 바뀐다.
     *
     * <p>수신자별로 지금도 정확한 값이 하나 있다 — {@code mail_event_log.recipient} 다.
     * Resend 가 delivered/bounced 를 수신자와 함께 주기 때문에, "누구에게 반송됐는가"는
     * 오늘도 사람별로 답할 수 있다. 열람 여부만 메일 단위이며, 수신자가 <b>한 명일 때만</b>
     * 그 값을 개인에게 귀속시킨다(여러 명일 때 전원에게 복사하면 한 명이 열었는데 전원이
     * "확인"으로 보인다).
     *
     * <p>발신 메일만 대상이다. 받은 메일에 "상대가 읽었는가"라는 개념이 없다.
     */
    @Transactional(readOnly = true)
    public MailReceiptDto findReceipt(long mailIdx) {
        MailMstJdbcRow mst = requireMail(mailIdx);
        if (!"OUT".equals(mst.direction())) {
            throw new IllegalStateException("보낸 메일만 수신확인을 조회할 수 있습니다.");
        }
        List<MailAddrDtlJdbcRow> addresses = mailAddrMapper.selectByMailIdx(mailIdx);
        List<MailEventLogJdbcRow> events = mailEventLogMapper.selectByMailIdx(mailIdx, EVENT_LIMIT);

        OffsetDateTime mailOpenedAt = mst.openedAt();
        int mailOpenCnt = mst.openCnt() == null ? 0 : mst.openCnt();

        // 같은 주소가 TO 와 CC 에 겹쳐 들어간 메일이 실제로 있다. 화면에 두 줄로 뜨면
        // "2명 중 1명 확인" 같은 잘못된 숫자가 나오므로 첫 등장만 남긴다.
        Set<String> seen = new LinkedHashSet<>();
        List<MailReceiptRecipientDto> recipients = new ArrayList<>();
        for (MailAddrDtlJdbcRow addr : addresses) {
            String addrType = addr.addrType();
            if (!"TO".equals(addrType) && !"CC".equals(addrType) && !"BCC".equals(addrType)) {
                continue;
            }
            String email = addr.email() == null ? "" : addr.email().trim().toLowerCase(Locale.ROOT);
            if (email.isEmpty() || !seen.add(email)) {
                continue;
            }
            recipients.add(buildRecipient(addrType, email, addr.dispNm(), events));
        }

        // 수신자가 한 명이면 메일 단위 열람 기록은 그 사람의 것이 확실하다.
        if (recipients.size() == 1 && mailOpenedAt != null) {
            MailReceiptRecipientDto only = recipients.get(0);
            if (!only.opened()) {
                recipients.set(0, new MailReceiptRecipientDto(
                        only.addrType(), only.email(), only.dispNm(),
                        true, toSeoul(mailOpenedAt), mailOpenCnt,
                        only.lastStatus(), only.lastStatusAt()));
            }
        }

        int openedCnt = 0;
        for (MailReceiptRecipientDto recipient : recipients) {
            if (recipient.opened()) {
                openedCnt++;
            }
        }

        return new MailReceiptDto(
                mailIdx,
                mst.subject() == null ? "" : mst.subject(),
                "Y".equals(mst.readReceiptYn()),
                mailOpenedAt != null || openedCnt > 0,
                toSeoul(mailOpenedAt),
                mailOpenCnt,
                // 추적 설정이 없으면 픽셀이 아예 안 심겨 영원히 미확인이다. 화면이
                // "상대가 안 읽음"과 "기능이 꺼져 있음"을 구분할 수 있어야 한다.
                properties.isTrackingConfigured(),
                recipients.size(),
                openedCnt,
                recipients);
    }

    @Transactional(readOnly = true)
    public List<MailListItemDto> listByPartner(int partnerIdx, int limit) {
        return mailMstMapper.selectByPartnerIdx(partnerIdx, clampLimit(limit)).stream()
                .map(MailListItemDto::fromRow)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<MailListItemDto> listByMapping(long mappingId) {
        return mailMstMapper.selectByMappingId(mappingId).stream()
                .map(MailListItemDto::fromRow)
                .toList();
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    /**
     * 조회 조건을 안전한 범위로 다듬는다.
     *
     * <p>XML 이 아니라 여기서 하는 이유: 폴더 미매칭을 {@code 1 = 0} 으로 막는 것은 XML 이
     * 맡지만, "너무 짧은 키워드"와 "limit 폭주"는 SQL 로 표현할 수 없다.
     */
    private static MailListQuery normalize(MailListQuery query) {
        if (query == null) {
            throw new IllegalArgumentException("조회 조건이 없습니다.");
        }
        String folder = query.folder() == null ? "" : query.folder().trim().toLowerCase(Locale.ROOT);
        Long folderIdx = query.folderIdx();

        // 사용자 정의 메일함은 화면이 "folder:12" 형태로 보낸다. 폴더 이름 자리에 숫자를
        // 얹는 방식이라 XML 의 <choose> 를 늘리지 않고도 함이 무한히 늘어날 수 있다.
        // 파싱을 XML 이 아니라 여기서 하는 이유는 OGNL 로 문자열을 자르는 코드가
        // 읽기도 디버깅도 어렵기 때문이다.
        if (folder.startsWith(MailListQuery.CUSTOM_PREFIX)) {
            String rawIdx = folder.substring(MailListQuery.CUSTOM_PREFIX.length()).trim();
            folder = MailListQuery.FOLDER_CUSTOM;
            try {
                long parsed = Long.parseLong(rawIdx);
                // 0 이하는 유효한 PK 가 아니다. null 로 두면 XML 이 1 = 0 으로 막는다 —
                // 조건 없는 folder_idx 조회로 흘러가는 것보다 아무것도 안 주는 쪽이 안전하다.
                folderIdx = parsed > 0 ? parsed : null;
            } catch (NumberFormatException e) {
                folderIdx = null;
            }
        }

        String keyword = blankToNull(query.keyword());
        if (keyword != null && keyword.length() < MIN_KEYWORD_LEN) {
            keyword = null;
        }
        return new MailListQuery(
                folder,
                folderIdx,
                blankToNull(query.ownerUserId()),
                keyword,
                query.fromDate(),
                query.toDate(),
                clampLimit(query.limit()),
                Math.max(query.offset(), 0));
    }

    /**
     * 수신자 한 명의 상태를 이벤트 원장에서 뽑는다.
     *
     * <p>{@code mail_event_log} 는 append-only 라 같은 수신자에 여러 행이 쌓인다.
     * 도착 순서가 보장되지 않으므로 <b>occurred_at 으로</b> 최신을 고른다(insert 순서나
     * event_idx 로 고르면 늦게 도착한 delivered 가 bounced 를 덮어쓴 것처럼 보인다).
     *
     * <p>{@code recipient} 가 비어 있는 이벤트는 건너뛴다 — 어느 수신자의 것인지 알 수
     * 없는 값을 특정인에게 귀속시키면 없는 사실을 만들어 내는 셈이다.
     */
    private static MailReceiptRecipientDto buildRecipient(String addrType,
                                                          String email,
                                                          String dispNm,
                                                          List<MailEventLogJdbcRow> events) {
        OffsetDateTime openedAt = null;
        OffsetDateTime lastStatusAt = null;
        String lastStatus = "";
        int openCnt = 0;

        for (MailEventLogJdbcRow event : events) {
            if (!StringUtils.hasText(event.recipient())
                    || !email.equalsIgnoreCase(event.recipient().trim())) {
                continue;
            }
            OffsetDateTime occurredAt = event.occurredAt();
            String type = event.eventType() == null ? "" : event.eventType();
            if ("opened".equals(type)) {
                openCnt++;
                // 알고 싶은 것은 "언제 처음 열었나"라서 가장 이른 값을 남긴다
                // (mail_mst.opened_at 을 COALESCE 로만 채우는 것과 같은 이유).
                if (openedAt == null || (occurredAt != null && occurredAt.isBefore(openedAt))) {
                    openedAt = occurredAt;
                }
            }
            if (lastStatusAt == null || (occurredAt != null && occurredAt.isAfter(lastStatusAt))) {
                lastStatusAt = occurredAt;
                lastStatus = type;
            }
        }

        return new MailReceiptRecipientDto(
                addrType,
                email,
                dispNm == null ? "" : dispNm,
                openedAt != null,
                toSeoul(openedAt),
                openCnt,
                lastStatus,
                toSeoul(lastStatusAt));
    }

    private MailMstJdbcRow requireMail(long mailIdx) {
        MailMstJdbcRow row = mailMstMapper.selectByIdx(mailIdx);
        if (row == null || Boolean.TRUE.equals(row.deletedYn())) {
            throw new ResourceNotFoundException("메일", "mailIdx", mailIdx);
        }
        return row;
    }

    private static int clampLimit(int limit) {
        if (limit <= 0) {
            return DEFAULT_LIMIT;
        }
        return Math.min(limit, MAX_LIMIT);
    }

    private static String blankToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private static OffsetDateTime toSeoul(OffsetDateTime value) {
        return value == null ? null : value.atZoneSameInstant(SEOUL).toOffsetDateTime();
    }
}
