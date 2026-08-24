package com.yeokjeon.erp.mail.service;

import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.mail.dto.MailSignatureDto;
import com.yeokjeon.erp.mail.dto.MailSignatureInsertParam;
import com.yeokjeon.erp.mail.dto.MailSignatureJdbcRow;
import com.yeokjeon.erp.mail.dto.MailSignatureSaveRequestDto;
import com.yeokjeon.erp.mail.mapper.MailSignatureMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * 개인 서명 CRUD (mal001-D).
 *
 * <p>핵심 규칙은 하나다 — <b>{@code default_new_yn}/{@code default_reply_yn} 은 사용자당
 * 최대 하나만 'Y'</b>. DB 에 부분 유니크 인덱스로 걸 수도 있었지만 그러면 "새 기본 서명
 * 지정" 한 번에 제약 위반이 나므로(옛 것을 내리기 전에 새 것이 올라간다) 순서를 통제할 수
 * 있는 서비스에서 보장한다. 해제 → 지정을 <b>한 트랜잭션</b>에 묶는 것이 그 전제라,
 * 이 클래스의 쓰기 메서드에서 {@code @Transactional} 을 떼면 규칙이 조용히 깨진다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailSignatureService {

    /**
     * 사용자당 서명 개수 상한.
     *
     * <p>네이버웍스가 10개인 것을 참고했다. 실사용에서 3~4개를 넘기는 경우가 드물고,
     * 작성 화면의 서명 선택 드롭다운이 그 이상이면 오히려 고르기 어려워진다.
     */
    private static final int MAX_SIGNATURES_PER_USER = 10;

    /**
     * 서명 HTML 상한(바이트).
     *
     * <p>컬럼은 {@code text} 라 제한이 없지만, 서명은 <b>보내는 메일마다</b> 본문에 붙어
     * 나간다. 이미지를 base64 로 박아 넣은 서명 하나가 모든 발송 용량을 몇 배로 부풀린다.
     * 로고는 URL 로 참조하게 유도하려는 의도도 있다.
     */
    private static final int SIGN_HTML_MAX_BYTES = 64 * 1024;

    private final MailSignatureMapper mailSignatureMapper;

    @Transactional(readOnly = true)
    public List<MailSignatureDto> list(String userId) {
        return mailSignatureMapper.selectByUserId(requireUserId(userId)).stream()
                .map(MailSignatureDto::fromRow)
                .toList();
    }

    @Transactional
    public MailSignatureDto create(MailSignatureSaveRequestDto body, String userId) {
        String uid = requireUserId(userId);
        if (body == null || !StringUtils.hasText(body.signNm())) {
            throw new IllegalArgumentException("서명 이름을 입력해 주세요.");
        }
        if (mailSignatureMapper.countByUserId(uid) >= MAX_SIGNATURES_PER_USER) {
            throw new IllegalStateException(
                    "서명은 최대 " + MAX_SIGNATURES_PER_USER + "개까지 만들 수 있습니다.");
        }
        String signHtml = clampHtml(body.signHtml());

        MailSignatureInsertParam param = new MailSignatureInsertParam();
        param.setUserId(uid);
        param.setSignNm(body.signNm().trim());
        param.setSignHtml(signHtml);
        param.setDefaultNewYn(yn(body.defaultNew()));
        param.setDefaultReplyYn(yn(body.defaultReply()));
        param.setSortOrder(body.sortOrder() != null
                ? body.sortOrder()
                : mailSignatureMapper.selectNextSortOrder(uid));

        // 새 서명을 기본으로 지정했다면 기존 기본을 먼저 내린다. INSERT 뒤에 내리면
        // 방금 만든 것까지 함께 내려가므로 순서를 바꾸면 안 된다(exceptIdx 를 쓸 수 없다 —
        // 아직 PK 가 없다).
        if (Boolean.TRUE.equals(body.defaultNew())) {
            mailSignatureMapper.clearDefaultNew(uid, null);
        }
        if (Boolean.TRUE.equals(body.defaultReply())) {
            mailSignatureMapper.clearDefaultReply(uid, null);
        }
        mailSignatureMapper.insert(param);

        Long newIdx = param.getMailSignIdx();
        if (newIdx == null) {
            throw new IllegalStateException("서명 저장에 실패했습니다.");
        }
        log.info("서명 생성 signIdx={} by={}", newIdx, uid);
        return findOne(newIdx, uid);
    }

    @Transactional
    public MailSignatureDto update(long signIdx, MailSignatureSaveRequestDto body, String userId) {
        String uid = requireUserId(userId);
        if (body == null) {
            throw new IllegalArgumentException("변경할 내용이 없습니다.");
        }
        requireSignature(signIdx, uid);

        // 기본 지정을 켜는 경우에만 다른 서명을 내린다. 끄는 경우(false)는 이 서명만
        // 'N' 이 되면 되고, 그때 기본 서명이 하나도 없는 상태가 되는 것은 정상이다
        // ("서명 없이 작성"이 유효한 선택이라).
        if (Boolean.TRUE.equals(body.defaultNew())) {
            mailSignatureMapper.clearDefaultNew(uid, signIdx);
        }
        if (Boolean.TRUE.equals(body.defaultReply())) {
            mailSignatureMapper.clearDefaultReply(uid, signIdx);
        }

        mailSignatureMapper.update(
                signIdx,
                uid,
                StringUtils.hasText(body.signNm()) ? body.signNm().trim() : null,
                body.signHtml() == null ? null : clampHtml(body.signHtml()),
                yn(body.defaultNew()),
                yn(body.defaultReply()),
                body.sortOrder());

        log.info("서명 수정 signIdx={} by={}", signIdx, uid);
        return findOne(signIdx, uid);
    }

    @Transactional
    public void delete(long signIdx, String userId) {
        String uid = requireUserId(userId);
        requireSignature(signIdx, uid);
        int deleted = mailSignatureMapper.delete(signIdx, uid);
        if (deleted == 0) {
            throw new IllegalStateException("서명 삭제에 실패했습니다.");
        }
        // 이미 보낸 메일의 서명은 본문에 복사돼 있어 그대로 남는다(서명은 참조가 아니라 사본).
        log.info("서명 삭제 signIdx={} by={}", signIdx, uid);
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    private MailSignatureDto findOne(long signIdx, String userId) {
        return MailSignatureDto.fromRow(requireSignature(signIdx, userId));
    }

    /** 소유자 조건이 SQL 에 있어 남의 서명이면 null → 404. 403 을 주면 존재 여부가 새어 나간다. */
    private MailSignatureJdbcRow requireSignature(long signIdx, String userId) {
        MailSignatureJdbcRow row = mailSignatureMapper.selectByIdx(signIdx, userId);
        if (row == null) {
            throw new ResourceNotFoundException("서명", "signIdx", signIdx);
        }
        return row;
    }

    /**
     * Boolean → 'Y'/'N'. null 은 null 그대로 둔다.
     *
     * <p>매퍼가 COALESCE 로 "null = 안 바꿈"을 처리하므로, 여기서 null 을 'N' 으로
     * 바꿔 버리면 PATCH 가 매번 기본 지정을 해제하는 꼴이 된다.
     */
    private static String yn(Boolean value) {
        if (value == null) {
            return null;
        }
        return value ? "Y" : "N";
    }

    /**
     * 서명 HTML 길이 제한.
     *
     * <p>바이트로 세는 이유는 한글이 UTF-8 에서 3바이트라 글자 수로 재면 실제 전송량이
     * 세 배까지 벌어지기 때문이다. 잘라서 저장하지 않고 <b>거부</b>한다 — HTML 을 중간에서
     * 자르면 태그가 열린 채 끝나 수신자 본문 레이아웃이 통째로 깨진다.
     */
    private static String clampHtml(String html) {
        if (html == null) {
            return "";
        }
        if (html.getBytes(StandardCharsets.UTF_8).length > SIGN_HTML_MAX_BYTES) {
            throw new IllegalArgumentException(
                    "서명이 너무 큽니다(최대 " + (SIGN_HTML_MAX_BYTES / 1024) + "KB). "
                            + "이미지는 파일로 붙이지 말고 주소로 연결해 주세요.");
        }
        return html;
    }

    private static String requireUserId(String userId) {
        if (!StringUtils.hasText(userId)) {
            throw new IllegalStateException("로그인 정보를 확인할 수 없습니다.");
        }
        return userId.trim();
    }
}
