package com.yeokjeon.erp.mail.service;

import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.mail.dto.MailFolderCountDto;
import com.yeokjeon.erp.mail.dto.MailFolderDto;
import com.yeokjeon.erp.mail.dto.MailFolderInsertParam;
import com.yeokjeon.erp.mail.dto.MailFolderJdbcRow;
import com.yeokjeon.erp.mail.dto.MailFolderSaveRequestDto;
import com.yeokjeon.erp.mail.mapper.MailFolderMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;

/**
 * 사용자 정의 메일함 CRUD (mal001-C).
 *
 * <p><b>메일함은 개인 소유물이다.</b> 메일 본체는 거래처 응대 이력이라 메뉴 권한만 있으면
 * 누구나 보지만(사서함이 아니라 공용 이력), 메일함은 각자가 자기 화면을 정리하려고 만든
 * 것이라 남이 손대면 안 된다. 그래서 모든 조회·변경이 {@code userId} 를 조건으로 갖고,
 * 매퍼 SQL 에도 같은 조건이 한 번 더 들어 있다(이중 방어).
 *
 * <p>남의 메일함에 접근하면 403 이 아니라 <b>404</b> 를 준다. 403 은 "그 번호의 메일함이
 * 존재한다"는 사실을 알려 주는 셈이라, 번호를 훑어 남이 메일함을 몇 개 만들었는지
 * 셀 수 있다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailFolderService {

    /**
     * 한 사용자가 만들 수 있는 메일함 수.
     *
     * <p>다우오피스는 무제한이지만, 사이드바에 100개가 늘어서면 그 자체로 못 쓰는 화면이 된다.
     * 무엇보다 {@code /mail/counts} 가 메일함마다 집계를 돌리므로 개수가 그대로 비용이다.
     */
    private static final int MAX_FOLDERS_PER_USER = 50;

    /**
     * 허용 계층 깊이(1 = 최상위).
     *
     * <p>DB 는 깊이를 막지 않지만 여기서 2단계까지만 허용한다. 3단계를 넘으면 좌측
     * 사이드바 들여쓰기가 읽기 어려워지고, 실사용에서 그만큼 깊게 쓰는 경우도 드물다.
     * 구조는 열어 두되(스키마는 무제한) 화면·서비스에서 절제하는 쪽을 택했다.
     */
    private static final int MAX_DEPTH = 2;

    private final MailFolderMapper mailFolderMapper;

    @Transactional(readOnly = true)
    public List<MailFolderDto> list(String userId) {
        return mailFolderMapper.selectByUserId(requireUserId(userId)).stream()
                .map(MailFolderDto::fromRow)
                .toList();
    }

    /** 메일함 관리 화면에서 "지우기 전에 몇 통 들어 있나"를 보여 줄 때 쓴다. */
    @Transactional(readOnly = true)
    public List<MailFolderCountDto> listWithCounts(String userId) {
        return mailFolderMapper.selectFolderCounts(requireUserId(userId));
    }

    @Transactional
    public MailFolderDto create(MailFolderSaveRequestDto body, String userId) {
        String uid = requireUserId(userId);
        if (body == null || !StringUtils.hasText(body.folderNm())) {
            throw new IllegalArgumentException("메일함 이름을 입력해 주세요.");
        }
        String folderNm = body.folderNm().trim();

        if (mailFolderMapper.countByUserId(uid) >= MAX_FOLDERS_PER_USER) {
            throw new IllegalStateException(
                    "메일함은 최대 " + MAX_FOLDERS_PER_USER + "개까지 만들 수 있습니다.");
        }
        // 부모가 있으면 그것부터 내 것인지 확인한다. 확인 없이 넣으면 FK 는 통과하고
        // 남의 메일함 아래에 내 메일함이 매달린다(FK 는 소유자를 보지 않는다).
        Long parentIdx = normalizeParent(body.parentFolderIdx(), uid, null);

        if (mailFolderMapper.countByName(uid, parentIdx, folderNm, null) > 0) {
            // DB 유니크 제약(uq_mail_folder_owner_name)이 어차피 막지만, 그대로 두면
            // 사용자에게 제약 위반 원문이 나간다. 여기서 미리 사람이 읽을 문장으로 바꾼다.
            throw new IllegalArgumentException("같은 이름의 메일함이 이미 있습니다: " + folderNm);
        }

        MailFolderInsertParam param = new MailFolderInsertParam();
        param.setUserId(uid);
        param.setParentFolderIdx(parentIdx);
        param.setFolderNm(folderNm);
        param.setSortOrder(body.sortOrder() != null
                ? body.sortOrder()
                : mailFolderMapper.selectNextSortOrder(uid, parentIdx));
        mailFolderMapper.insert(param);

        Long newIdx = param.getMailFolderIdx();
        if (newIdx == null) {
            throw new IllegalStateException("메일함 생성에 실패했습니다.");
        }
        log.info("메일함 생성 folderIdx={} nm={} by={}", newIdx, folderNm, uid);
        return findOne(newIdx, uid);
    }

    @Transactional
    public MailFolderDto update(long folderIdx, MailFolderSaveRequestDto body, String userId) {
        String uid = requireUserId(userId);
        if (body == null) {
            throw new IllegalArgumentException("변경할 내용이 없습니다.");
        }
        MailFolderJdbcRow current = requireFolder(folderIdx, uid);

        String folderNm = StringUtils.hasText(body.folderNm()) ? body.folderNm().trim() : null;

        // "부모를 보냈는가"와 "null 을 보냈는가"는 다르다. 전자는 안 바꿈, 후자는 최상위로 이동.
        // record 는 필드 존재 여부를 알 수 없어(미전송도 null) parentFolderIdx 가 null 이면
        // "안 바꿈"으로 본다. 최상위로 올리는 것은 별도 값이 필요하므로, 화면은 0 을 보낸다.
        boolean parentGiven = body.parentFolderIdx() != null;
        Long parentIdx = null;
        if (parentGiven) {
            // 0 은 "최상위로 올린다"는 뜻의 약속된 값이다. record 로는 null 과 미전송을
            // 구분할 수 없어 이 규칙이 필요하다.
            parentIdx = body.parentFolderIdx() == 0L
                    ? null
                    : normalizeParent(body.parentFolderIdx(), uid, folderIdx);
        }

        // 이름이나 부모가 바뀌면 중복 검사를 다시 한다. 둘 다 안 바뀌면 자기 자신과
        // 부딪힐 뿐이라 검사할 필요가 없다.
        if (folderNm != null || parentGiven) {
            String targetNm = folderNm != null ? folderNm : current.folderNm();
            Long targetParent = parentGiven ? parentIdx : current.parentFolderIdx();
            if (mailFolderMapper.countByName(uid, targetParent, targetNm, folderIdx) > 0) {
                throw new IllegalArgumentException("같은 이름의 메일함이 이미 있습니다: " + targetNm);
            }
        }

        mailFolderMapper.update(folderIdx, uid, folderNm, parentGiven, parentIdx, body.sortOrder());
        log.info("메일함 수정 folderIdx={} by={}", folderIdx, uid);
        return findOne(folderIdx, uid);
    }

    /**
     * 메일함 삭제.
     *
     * <p><b>안에 있던 메일은 사라지지 않는다.</b> {@code mail_mst.folder_idx} 의 FK 가
     * {@code ON DELETE SET NULL} 이라 folder_idx 만 풀리고 메일은 기본함(받은메일함 등)으로
     * 돌아간다. 하위 메일함은 {@code ON DELETE CASCADE} 로 함께 지워지고 그 안의 메일도
     * 같은 규칙으로 풀리므로, 메일이 유실되는 경로가 없다.
     */
    @Transactional
    public void delete(long folderIdx, String userId) {
        String uid = requireUserId(userId);
        requireFolder(folderIdx, uid);
        int deleted = mailFolderMapper.delete(folderIdx, uid);
        if (deleted == 0) {
            throw new IllegalStateException("메일함 삭제에 실패했습니다.");
        }
        log.info("메일함 삭제 folderIdx={} by={} (안의 메일은 folder_idx=NULL 로 풀린다)", folderIdx, uid);
    }

    /**
     * 메일 이동 대상으로 쓸 수 있는 메일함인지 확인한다.
     *
     * <p>{@link MailBulkService} 가 MOVE 를 처리하기 전에 부른다. 여기서 걸러야
     * 남의 메일함 idx 를 넣었을 때 FK 위반(500)이 아니라 404 로 분명히 알릴 수 있다.
     */
    @Transactional(readOnly = true)
    public void ensureOwned(long folderIdx, String userId) {
        requireFolder(folderIdx, requireUserId(userId));
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    private MailFolderDto findOne(long folderIdx, String userId) {
        return MailFolderDto.fromRow(requireFolder(folderIdx, userId));
    }

    /** 소유자 조건이 SQL 에 있으므로 남의 메일함이면 null 이 오고, 그대로 404 가 된다. */
    private MailFolderJdbcRow requireFolder(long folderIdx, String userId) {
        MailFolderJdbcRow row = mailFolderMapper.selectByIdx(folderIdx, userId);
        if (row == null) {
            throw new ResourceNotFoundException("메일함", "folderIdx", folderIdx);
        }
        return row;
    }

    /**
     * 상위 메일함 검증.
     *
     * <p>세 가지를 본다.
     * <ol>
     *   <li>내 메일함인가 — FK 는 소유자를 보지 않아서 이걸 안 하면 남의 함 아래 매달린다</li>
     *   <li>깊이가 {@link #MAX_DEPTH} 를 넘지 않는가</li>
     *   <li>자기 자신을 부모로 삼지 않는가 — 그러면 사이드바 렌더링이 무한 재귀에 빠진다</li>
     * </ol>
     *
     * @param selfIdx 수정 중인 메일함(자기 참조 검사용). 생성 시에는 null.
     */
    private Long normalizeParent(Long parentFolderIdx, String userId, Long selfIdx) {
        if (parentFolderIdx == null || parentFolderIdx <= 0) {
            return null;
        }
        if (selfIdx != null && parentFolderIdx.equals(selfIdx)) {
            throw new IllegalArgumentException("메일함을 자기 자신의 하위로 옮길 수 없습니다.");
        }
        MailFolderJdbcRow parent = requireFolder(parentFolderIdx, userId);

        // 부모가 이미 자식을 갖고 있으면(= 부모의 부모가 있으면) 손자가 되어 3단계다.
        if (parent.parentFolderIdx() != null) {
            throw new IllegalArgumentException(
                    "메일함은 " + MAX_DEPTH + "단계까지만 만들 수 있습니다.");
        }
        return parentFolderIdx;
    }

    private static String requireUserId(String userId) {
        if (!StringUtils.hasText(userId)) {
            // 토큰에서 온 값이라 정상 흐름에서는 비어 있을 수 없다. 비어 있다면
            // 필터를 거치지 않은 호출이므로 조건 없는 전체 조회로 이어지기 전에 끊는다.
            throw new IllegalStateException("로그인 정보를 확인할 수 없습니다.");
        }
        return userId.trim();
    }
}
