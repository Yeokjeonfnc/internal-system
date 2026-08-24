package com.yeokjeon.erp.mail.service;

import com.yeokjeon.erp.mail.dto.MailThreadInsertParam;
import com.yeokjeon.erp.mail.mapper.MailThreadMapper;
import com.yeokjeon.erp.mail.support.MailMessageIdUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * 스레드(대화 묶음) 연결.
 *
 * <p>마이그레이션 파일이 깔아 둔 인덱스 두 개가 이 서비스의 설계 그대로다.
 * <ul>
 *   <li>{@code idx_mail_mst_rfc_message_id} — 정방향: 새 메일의 References/In-Reply-To 가
 *       가리키는 기존 메일을 찾는다.</li>
 *   <li>{@code idx_mail_mst_in_reply_to} — 역방향: 나를 부모로 가리키고 있던 기존 메일을 찾는다.
 *       웹훅 도착 순서가 뒤집혀 답장이 원본보다 먼저 저장되는 일이 실제로 일어난다.</li>
 * </ul>
 * 두 방향을 한 번에 보기 위해 {@code selectThreadIdxByMessageIds} 에는
 * <b>내 Message-ID 까지 포함한</b> 후보 목록을 넘긴다.
 *
 * <p>그래도 못 찾으면 제목 폴백(30일 이내 같은 {@code subject_norm})을 쓴다.
 * 기간을 두는 이유: "회신 부탁드립니다" 같은 제목은 1년 뒤 전혀 다른 건에서도 나오는데
 * 기간 제한이 없으면 무관한 메일 수백 통이 한 스레드에 붙어 버린다.
 *
 * <p>마지막까지 못 찾으면 새 스레드를 만든다. 반환값은 항상 non-null 이다 —
 * {@code mail_mst.thread_idx} 가 NOT NULL 이라 호출부가 null 을 받을 여지를 두면 안 된다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailThreadService {

    /** 제목 폴백 매칭 허용 기간(일). */
    private static final int SUBJECT_FALLBACK_DAYS = 30;

    private final MailThreadMapper mailThreadMapper;

    @Transactional
    public long resolveThreadIdx(String subjectNorm,
                                 String rfcMessageId,
                                 String inReplyTo,
                                 List<String> references,
                                 OffsetDateTime mailAt) {
        OffsetDateTime at = mailAt == null ? OffsetDateTime.now() : mailAt;
        String norm = subjectNorm == null ? "" : subjectNorm.trim();

        List<String> candidates = candidateMessageIds(rfcMessageId, inReplyTo, references);
        if (!candidates.isEmpty()) {
            Long found = mailThreadMapper.selectThreadIdxByMessageIds(candidates);
            if (found != null) {
                log.debug("스레드 연결(헤더) threadIdx={} 후보={}건", found, candidates.size());
                return found;
            }
        }

        if (!norm.isEmpty()) {
            Long found = mailThreadMapper.selectThreadIdxBySubjectNorm(norm, SUBJECT_FALLBACK_DAYS);
            if (found != null) {
                log.debug("스레드 연결(제목 폴백) threadIdx={}", found);
                return found;
            }
        }

        MailThreadInsertParam param = new MailThreadInsertParam();
        param.setSubjectNorm(norm);
        param.setFirstMailAt(at);
        param.setLastMailAt(at);
        mailThreadMapper.insert(param);
        Long threadIdx = param.getThreadIdx();
        if (threadIdx == null) {
            // useGeneratedKeys 가 안 먹으면 이후 INSERT 가 NOT NULL 제약에 걸려 죽는다.
            // 원인이 드러나도록 여기서 끊는다.
            throw new IllegalStateException("메일 스레드 생성에 실패했습니다.");
        }
        return threadIdx;
    }

    /**
     * 스레드의 첫/마지막 시각과 메일 건수를 다시 계산한다.
     *
     * <p>메일을 넣거나 지운 뒤 반드시 부른다. 캐시 컬럼을 안 맞추면 스레드 목록의
     * 정렬(최근 대화순)이 옛 시각에 묶여 새 메일이 아래로 가라앉는다.
     */
    @Transactional
    public void touch(long threadIdx) {
        mailThreadMapper.touch(threadIdx);
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    /**
     * 스레드 후보 Message-ID 목록.
     *
     * <p>순서: In-Reply-To(가장 정확) → References(조상들) → 내 Message-ID(역방향).
     * 전부 꺾쇠를 뗀 소문자 형태로 정규화해 DB 저장 형식과 맞춘다.
     */
    private static List<String> candidateMessageIds(String rfcMessageId,
                                                    String inReplyTo,
                                                    List<String> references) {
        Set<String> unique = new LinkedHashSet<>();
        addIfPresent(unique, MailMessageIdUtil.strip(inReplyTo));
        if (references != null) {
            for (String reference : references) {
                addIfPresent(unique, MailMessageIdUtil.strip(reference));
            }
        }
        addIfPresent(unique, MailMessageIdUtil.strip(rfcMessageId));
        return unique.isEmpty() ? List.of() : new ArrayList<>(unique);
    }

    private static void addIfPresent(Set<String> target, String value) {
        if (value != null && !value.isBlank()) {
            target.add(value);
        }
    }
}
