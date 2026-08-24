package com.yeokjeon.erp.mail.service;

import com.yeokjeon.erp.mail.dto.MailBulkAction;
import com.yeokjeon.erp.mail.dto.MailBulkActionRequestDto;
import com.yeokjeon.erp.mail.dto.MailBulkActionResultDto;
import com.yeokjeon.erp.mail.dto.MailMstJdbcRow;
import com.yeokjeon.erp.mail.mapper.MailMstMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * 목록 일괄 동작 (mal001-B).
 *
 * <p>다우오피스에서 사용자가 가장 많이 쓰는 조작이다 — 목록에서 여러 통을 체크하고
 * 읽음/삭제/이동을 한 번에 누른다. 단건 API 를 화면에서 N번 부르는 방식으로 만들면
 * 20통을 지울 때 중간에 하나가 실패해도 되돌릴 방법이 없고, 왕복도 20배가 된다.
 * 그래서 <b>한 요청 = 한 트랜잭션</b>이다.
 *
 * <p><b>보안상 가장 중요한 지점</b>: {@code mailIdxes} 는 화면이 준 값이라 남의 mail_idx 가
 * 섞여 올 수 있다. 매퍼 SQL 의 {@code user_id = #{userId}} 조건이 유일한 방어선이므로
 * 절대 빼면 안 된다.
 *
 * <p><b>알아 둘 제약</b>: {@code mail_mst.user_id} 는 개인 사서함이 아니라 '담당자' 컬럼이고
 * NULL 을 허용한다. 담당자가 지정되지 않은 수신 메일은 소유자 조건에 걸리지 않아
 * 일괄 동작 대상에서 빠진다. 이는 "본인 소유 메일만" 이라는 요구사항을 그대로 따른 결과이고,
 * 담당자 없는 메일까지 다루려면 정책을 먼저 정해야 한다(누구나 만질 수 있게 할 것인가?).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailBulkService {

    private final MailMstMapper mailMstMapper;
    private final MailFolderService mailFolderService;
    private final MailThreadService mailThreadService;

    /**
     * 일괄 동작 실행.
     *
     * <p>{@code @Transactional} 이 핵심이다 — 20통 중 5통째에서 실패하면 앞의 4통도
     * 되돌아가야 화면 목록과 DB 가 어긋나지 않는다.
     */
    @Transactional
    public MailBulkActionResultDto execute(MailBulkActionRequestDto body, String callerUserId) {
        String uid = requireUserId(callerUserId);
        if (body == null) {
            throw new IllegalArgumentException("처리할 내용이 없습니다.");
        }
        MailBulkAction action = MailBulkAction.from(body.action());
        List<Long> targets = normalizeTargets(body.mailIdxes());
        if (targets.isEmpty()) {
            throw new IllegalArgumentException("대상 메일을 선택해 주세요.");
        }

        if (action == MailBulkAction.MOVE) {
            // 목적지가 내 메일함인지 먼저 확인한다. 여기서 안 걸러내면 남의 메일함 idx 는
            // FK 위반(500)으로 터지고, 없는 idx 는 조용히 0건 갱신으로 끝나 원인을 알 수 없다.
            // folderIdx 가 null 이면 "기본함으로 되돌리기"라 검증 대상이 아니다.
            if (body.folderIdx() != null) {
                mailFolderService.ensureOwned(body.folderIdx(), uid);
            }
        }

        int affected = action == MailBulkAction.PURGE
                ? purge(targets, uid)
                : mailMstMapper.bulkUpdate(targets, uid, action.name(), body.folderIdx());

        log.info("메일 일괄 {} 요청 {}건 → 처리 {}건 by={}",
                action.name(), targets.size(), affected, uid);

        return new MailBulkActionResultDto(
                action.name(), targets.size(), affected, message(action, targets.size(), affected));
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    /**
     * 완전 삭제.
     *
     * <p>지우기 <b>전에</b> 스레드 번호를 모아 둔다. 삭제 후에는 행이 없어서 어떤 스레드의
     * 캐시({@code mail_thread_mst.mail_cnt})를 다시 세야 하는지 알 방법이 사라진다.
     * 그러면 대화 목록에 "3통"이라고 적힌 빈 스레드가 남는다.
     *
     * <p>매퍼가 이미 {@code deleted_yn = true} 조건을 걸고 있어 휴지통 밖의 메일은
     * 대상에서 빠진다 — 실수 한 번에 복구 불가능한 손실이 생기지 않게 하는 안전장치다.
     */
    private int purge(List<Long> targets, String userId) {
        Set<Long> threadIdxes = new LinkedHashSet<>();
        for (Long mailIdx : targets) {
            MailMstJdbcRow row = mailMstMapper.selectByIdx(mailIdx);
            // 남의 메일이거나 휴지통 밖이면 어차피 안 지워진다. 스레드 수집도 건너뛴다.
            if (row != null
                    && userId.equals(row.userId())
                    && Boolean.TRUE.equals(row.deletedYn())
                    && row.threadIdx() != null) {
                threadIdxes.add(row.threadIdx());
            }
        }

        int affected = mailMstMapper.purgeByIdxes(targets, userId);

        // 스레드 캐시를 실제 남은 메일 기준으로 다시 센다. 스레드 하나에 속한 메일은
        // 많아야 수십 건이라 재계산 비용이 무시할 만하다(MailThreadService.touch 참고).
        for (Long threadIdx : threadIdxes) {
            mailThreadService.touch(threadIdx);
        }
        return affected;
    }

    /**
     * 대상 목록 정리 — 중복 제거 + 유효하지 않은 값 제거.
     *
     * <p>중복을 지우는 이유는 SQL 때문이 아니라 결과 건수 때문이다. 같은 idx 가 두 번
     * 들어와도 UPDATE 는 1건인데, 요청 건수를 그대로 세면 "2건 중 1건 처리"라는
     * 이상한 안내가 나간다.
     *
     * <p>순서를 유지하는 LinkedHashSet 을 쓰는 것은 로그를 읽을 때 요청 순서가 보이게
     * 하려는 것뿐이다(SQL 결과에는 영향이 없다).
     */
    private static List<Long> normalizeTargets(List<Long> mailIdxes) {
        if (mailIdxes == null || mailIdxes.isEmpty()) {
            return List.of();
        }
        Set<Long> unique = new LinkedHashSet<>();
        for (Long idx : mailIdxes) {
            if (idx != null && idx > 0) {
                unique.add(idx);
            }
        }
        return new ArrayList<>(unique);
    }

    /**
     * 화면에 띄울 안내 문구.
     *
     * <p>요청 건수와 처리 건수가 다르면 그 사실을 감추지 않는다. "20건 처리했습니다"라고
     * 해 놓고 목록에는 13건만 바뀌어 있으면 사용자는 화면이 고장 났다고 판단한다.
     */
    private static String message(MailBulkAction action, int requested, int affected) {
        String verb = switch (action) {
            case READ -> "읽음 처리";
            case UNREAD -> "안읽음 처리";
            case STAR -> "중요 표시";
            case UNSTAR -> "중요 표시 해제";
            case DELETE -> "휴지통으로 이동";
            case RESTORE -> "복구";
            case PURGE -> "완전 삭제";
            case SPAM -> "스팸 처리";
            case NOTSPAM -> "스팸 해제";
            case MOVE -> "메일함 이동";
        };
        if (affected == 0) {
            return verb + "할 수 있는 메일이 없습니다. (본인 담당 메일만 처리할 수 있습니다)";
        }
        if (affected < requested) {
            return affected + "건을 " + verb + "했습니다. "
                    + (requested - affected) + "건은 대상이 아니어서 제외했습니다.";
        }
        return affected + "건을 " + verb + "했습니다.";
    }

    private static String requireUserId(String userId) {
        if (!StringUtils.hasText(userId)) {
            // 소유자 조건이 빈 문자열이 되면 SQL 이 아무 행도 못 고치지만,
            // 조건을 실수로 뺐을 때를 대비해 여기서 먼저 끊는다.
            throw new IllegalStateException("로그인 정보를 확인할 수 없습니다.");
        }
        return userId.trim();
    }
}
