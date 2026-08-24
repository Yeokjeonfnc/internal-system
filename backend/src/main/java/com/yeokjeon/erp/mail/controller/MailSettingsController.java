package com.yeokjeon.erp.mail.controller;

import com.yeokjeon.erp.auth.access.MenuAccessGuard;
import com.yeokjeon.erp.auth.access.MenuCodes;
import com.yeokjeon.erp.auth.token.AuthTokenFilter;
import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.mail.dto.MailFolderCountDto;
import com.yeokjeon.erp.mail.dto.MailFolderDto;
import com.yeokjeon.erp.mail.dto.MailFolderSaveRequestDto;
import com.yeokjeon.erp.mail.dto.MailForwardDto;
import com.yeokjeon.erp.mail.dto.MailForwardRuleDto;
import com.yeokjeon.erp.mail.dto.MailForwardRuleSaveRequestDto;
import com.yeokjeon.erp.mail.dto.MailForwardSaveRequestDto;
import com.yeokjeon.erp.mail.dto.MailPrefSaveRequestDto;
import com.yeokjeon.erp.mail.dto.MailRuleDto;
import com.yeokjeon.erp.mail.dto.MailRuleReorderRequestDto;
import com.yeokjeon.erp.mail.dto.MailRuleSaveRequestDto;
import com.yeokjeon.erp.mail.dto.MailSignatureDto;
import com.yeokjeon.erp.mail.dto.MailSignatureSaveRequestDto;
import com.yeokjeon.erp.mail.service.MailFolderService;
import com.yeokjeon.erp.mail.service.MailForwardService;
import com.yeokjeon.erp.mail.service.MailPrefService;
import com.yeokjeon.erp.mail.service.MailRuleService;
import com.yeokjeon.erp.mail.service.MailSignatureService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * 메일 개인 설정 — 사용자 정의 메일함 · 서명 · 환경설정 (mal001 C/D/E).
 *
 * <p>{@link MailController} 와 나눈 이유: 저 컨트롤러는 "메일 데이터"를 다루고 여기는
 * "그 사람의 화면 설정"을 다룬다. 권한 판정의 성격도 달라서 한 파일에 두면 헷갈린다 —
 * 메일 본체는 공용 이력이라 메뉴 권한만 보지만, 여기 자원들은 <b>전부 개인 소유물</b>이라
 * 서비스가 {@code userId} 로 한 번 더 좁힌다.
 *
 * <p><b>권한을 VIEW 로 판정한다.</b> mal008(메일설정) 메뉴 코드를 따로 쓰지 않는 이유는,
 * 메일함·서명이 메일을 쓰기 위한 부속이라 "메일은 보는데 내 메일함은 못 만드는" 상태가
 * 의미가 없어서다. 메뉴 코드를 나누면 관리자가 mst003 에서 여덟 개를 일일이 켜 줘야 한다.
 * (mal008 은 사이드바 메뉴 표시용으로만 존재한다.)
 */
@Slf4j
@RestController
@RequestMapping("/mail")
@RequiredArgsConstructor
public class MailSettingsController {

    private final MailFolderService mailFolderService;
    private final MailSignatureService mailSignatureService;
    private final MailPrefService mailPrefService;
    private final MailRuleService mailRuleService;
    private final MailForwardService mailForwardService;
    private final MenuAccessGuard menuAccessGuard;

    // ── 사용자 정의 메일함 (mal001-C) ──────────────────────────────────────

    /**
     * 내 메일함 목록.
     *
     * @param withCounts true 면 메일함마다 전체·안읽음 건수를 함께 준다(관리 화면에서
     *                   "지우기 전에 몇 통 들어 있나"를 보여 줄 때). 사이드바는
     *                   {@code /mail/counts} 로 한 번에 받는 편이 왕복이 적다.
     */
    @GetMapping("/folders")
    public ResponseEntity<ApiResponse<?>> listFolders(
            HttpServletRequest request,
            @RequestParam(required = false, defaultValue = "false") boolean withCounts) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        if (withCounts) {
            List<MailFolderCountDto> counts = mailFolderService.listWithCounts(uid);
            return ResponseEntity.ok(ApiResponse.success("메일함 목록", counts));
        }
        List<MailFolderDto> folders = mailFolderService.list(uid);
        return ResponseEntity.ok(ApiResponse.success("메일함 목록", folders));
    }

    @PostMapping("/folders")
    public ResponseEntity<ApiResponse<MailFolderDto>> createFolder(
            HttpServletRequest request,
            @Valid @RequestBody MailFolderSaveRequestDto body) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "메일함을 만들었습니다.", mailFolderService.create(body, uid)));
    }

    /** PATCH 다 — 보내지 않은 필드는 그대로 둔다. 이름만 바꿀 때 부모까지 실어 보낼 필요가 없다. */
    @PatchMapping("/folders/{folderIdx}")
    public ResponseEntity<ApiResponse<MailFolderDto>> updateFolder(
            HttpServletRequest request,
            @PathVariable long folderIdx,
            @Valid @RequestBody MailFolderSaveRequestDto body) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "메일함을 수정했습니다.", mailFolderService.update(folderIdx, body, uid)));
    }

    /**
     * 메일함 삭제.
     *
     * <p><b>안에 있던 메일은 사라지지 않는다.</b> FK 가 {@code ON DELETE SET NULL} 이라
     * folder_idx 만 풀리고 메일은 받은메일함으로 돌아간다. 화면 안내도 "메일함만
     * 삭제되며 메일은 받은메일함으로 이동합니다" 여야 한다 — "메일도 함께 삭제됩니다"로
     * 안내하면 사용자가 지우기를 주저한다.
     */
    @DeleteMapping("/folders/{folderIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteFolder(
            HttpServletRequest request,
            @PathVariable long folderIdx) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        mailFolderService.delete(folderIdx, uid);
        return ResponseEntity.ok(ApiResponse.success(
                "메일함을 삭제했습니다. 안에 있던 메일은 받은메일함으로 이동했습니다.", null));
    }

    // ── 서명 (mal001-D) ────────────────────────────────────────────────────

    @GetMapping("/signatures")
    public ResponseEntity<ApiResponse<List<MailSignatureDto>>> listSignatures(
            HttpServletRequest request) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "서명 목록", mailSignatureService.list(uid)));
    }

    @PostMapping("/signatures")
    public ResponseEntity<ApiResponse<MailSignatureDto>> createSignature(
            HttpServletRequest request,
            @Valid @RequestBody MailSignatureSaveRequestDto body) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "서명을 저장했습니다.", mailSignatureService.create(body, uid)));
    }

    /**
     * 서명 수정.
     *
     * <p>{@code defaultNew}/{@code defaultReply} 를 true 로 보내면 <b>같은 사용자의 다른
     * 서명은 자동으로 해제된다</b>(사용자당 하나만 Y). 화면이 옛 기본을 먼저 끄는
     * 요청을 따로 보낼 필요가 없다.
     */
    @PatchMapping("/signatures/{signIdx}")
    public ResponseEntity<ApiResponse<MailSignatureDto>> updateSignature(
            HttpServletRequest request,
            @PathVariable long signIdx,
            @Valid @RequestBody MailSignatureSaveRequestDto body) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "서명을 수정했습니다.", mailSignatureService.update(signIdx, body, uid)));
    }

    @DeleteMapping("/signatures/{signIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteSignature(
            HttpServletRequest request,
            @PathVariable long signIdx) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        mailSignatureService.delete(signIdx, uid);
        return ResponseEntity.ok(ApiResponse.success("서명을 삭제했습니다.", null));
    }

    // ── 개인 환경설정 (mal001-E) ───────────────────────────────────────────

    /**
     * 내 설정 전체.
     *
     * <p>저장한 적이 없으면 빈 객체다. 서버가 기본값을 채워 주지 않는 이유는 그러면
     * "기본값"이 서버와 화면 두 군데에 생겨 언젠가 어긋나기 때문이다.
     *
     * <p><b>경로가 둘이다({@code /prefs}, {@code /preferences}).</b> 배포된 화면이
     * {@code /mail/preferences} 를 호출하는데 서버에는 {@code /mail/prefs} 만 있어서 설정
     * 카드가 항상 "준비 중"으로 떴다. 화면이 아니라 서버를 맞춘 이유는 배포 순서다 —
     * 화면을 고치면 새 화면이 나가기 전까지 계속 깨져 있지만, 서버가 둘 다 받으면
     * 어느 쪽이 먼저 나가도 동작한다. {@code /prefs} 는 구버전 화면을 위해 남겨 둔다.
     */
    @GetMapping({"/prefs", "/preferences"})
    public ResponseEntity<ApiResponse<Map<String, String>>> getPrefs(HttpServletRequest request) {
        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success("메일 설정", mailPrefService.get(uid)));
    }

    /**
     * 설정 다건 저장.
     *
     * <p>PUT 이지만 <b>부분 갱신</b>이다 — 요청에 없는 키는 지우지 않는다. 전체 치환으로
     * 만들면 구버전 화면이 자기가 모르는 새 설정을 통째로 날려 버린다. 값을 비우려면
     * 빈 문자열을 명시적으로 보낸다.
     *
     * <p>PATCH 가 아니라 PUT 인 이유는 "보낸 키 묶음"에 대해서는 완전 치환이라서다.
     *
     * <p>조회와 같은 이유로 경로가 둘이다({@code /prefs}, {@code /preferences}).
     */
    @PutMapping({"/prefs", "/preferences"})
    public ResponseEntity<ApiResponse<Map<String, String>>> savePrefs(
            HttpServletRequest request,
            @Valid @RequestBody MailPrefSaveRequestDto body) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "메일 설정을 저장했습니다.", mailPrefService.save(body.prefs(), uid)));
    }

    // ── 자동분류 규칙 (mal001-K) ───────────────────────────────────────────

    /**
     * 내 규칙 목록. <b>배열 순서가 곧 적용 우선순위</b>다(위에서부터 첫 매칭 하나만 적용).
     * 꺼 둔 규칙({@code use=false})도 함께 준다 — 설정 화면에서 켜고 끄기 때문이다.
     */
    @GetMapping("/rules")
    public ResponseEntity<ApiResponse<List<MailRuleDto>>> listRules(HttpServletRequest request) {
        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success("자동분류 규칙 목록", mailRuleService.list(uid)));
    }

    /**
     * 규칙 생성.
     *
     * <p>조건은 보낸사람·수신자(참조 포함)·제목 셋이고 <b>AND 로만</b> 묶인다(다우오피스에
     * OR 이 없다). 최소 한 가지는 있어야 한다 — 조건 없는 규칙은 모든 메일을 첫 번째로
     * 잡아 아래 규칙을 전부 죽인다.
     *
     * <p>처리는 {@code MOVE}(메일함 이동) 또는 {@code READ}(읽음처리) 중 하나다.
     * MOVE 면 {@code actionFolderIdx} 가 필수이고 <b>본인 메일함</b>이어야 한다(아니면 404).
     *
     * <p><b>기존 메일에는 소급 적용되지 않는다.</b> 설정 이후 수신분부터다 — 사람이 이미
     * 정리해 둔 메일함을 규칙이 뒤엎으면 되돌릴 방법이 없다. 화면도 그렇게 안내할 것.
     */
    @PostMapping("/rules")
    public ResponseEntity<ApiResponse<MailRuleDto>> createRule(
            HttpServletRequest request,
            @Valid @RequestBody MailRuleSaveRequestDto body) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "규칙을 만들었습니다. 지금부터 받는 메일에 적용됩니다.",
                mailRuleService.create(body, uid)));
    }

    /**
     * 규칙 순서 변경.
     *
     * <p><b>{@code /rules/{ruleIdx}} 보다 먼저 선언해야 한다.</b> 스프링은 구체 경로를
     * 우선하므로 실제로는 순서와 무관하지만, 읽는 사람이 {@code reorder} 를 PathVariable 로
     * 오해하지 않도록 붙여 둔다.
     *
     * <p>보낸 배열 순서가 그대로 새 우선순위가 된다. 규칙마다 숫자를 보내지 않는 이유는,
     * 화면이 계산한 숫자가 겹치면 같은 메일이 조회 시점에 따라 다른 메일함으로 가기 때문이다.
     */
    @PatchMapping("/rules/reorder")
    public ResponseEntity<ApiResponse<List<MailRuleDto>>> reorderRules(
            HttpServletRequest request,
            @Valid @RequestBody MailRuleReorderRequestDto body) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        mailRuleService.reorder(body.ruleIdxes(), uid);
        // 정렬된 목록을 그대로 돌려준다. 화면이 다시 GET 하지 않아도 되고, 남의 idx 가
        // 섞여 있었을 때 실제 결과가 무엇인지 눈으로 확인된다.
        return ResponseEntity.ok(ApiResponse.success("규칙 순서를 변경했습니다.", mailRuleService.list(uid)));
    }

    /** PATCH 다 — 보내지 않은 필드는 그대로 둔다. <b>조건을 지우려면 빈 문자열</b>을 보낸다. */
    @PatchMapping("/rules/{ruleIdx}")
    public ResponseEntity<ApiResponse<MailRuleDto>> updateRule(
            HttpServletRequest request,
            @PathVariable long ruleIdx,
            @Valid @RequestBody MailRuleSaveRequestDto body) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "규칙을 수정했습니다.", mailRuleService.update(ruleIdx, body, uid)));
    }

    /** 규칙만 사라진다. 그 규칙으로 이미 옮겨진 메일은 그대로 있다. */
    @DeleteMapping("/rules/{ruleIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteRule(
            HttpServletRequest request,
            @PathVariable long ruleIdx) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        mailRuleService.delete(ruleIdx, uid);
        return ResponseEntity.ok(ApiResponse.success(
                "규칙을 삭제했습니다. 이미 분류된 메일은 그대로 남습니다.", null));
    }

    // ── 자동전달 (mal001-L) ────────────────────────────────────────────────

    /**
     * 자동전달 설정 전체 — 전체 전달 + 예외 규칙 목록을 한 번에 준다.
     *
     * <p>응답의 {@code maxRules} 가 예외 규칙 상한이다. 화면이 상수로 복사해 두면 서버와
     * 어긋나는 날이 오므로 이 값을 쓸 것.
     */
    @GetMapping("/forward")
    public ResponseEntity<ApiResponse<MailForwardDto>> getForward(HttpServletRequest request) {
        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success("자동전달 설정", mailForwardService.get(uid)));
    }

    /**
     * 전체 자동전달 저장(PUT — 세 값이 한 덩어리라 부분 갱신하지 않는다).
     *
     * <p><b>{@code keepOriginal=false} 는 화면에서 반드시 경고해야 한다.</b> 전달 후 원본이
     * 휴지통으로 가는데, 이 ERP 의 받은메일함은 개인 사서함이 아니라 공용이라
     * <b>다른 사람 화면에서도 사라진다</b>.
     *
     * <p>{@code use=true} 면 주소가 필수다. 본인 주소나 시스템 발신 주소는 거부한다 —
     * 메일이 계속 되돌아와 무한 전달이 된다.
     */
    @PutMapping("/forward")
    public ResponseEntity<ApiResponse<MailForwardDto>> saveForward(
            HttpServletRequest request,
            @Valid @RequestBody MailForwardSaveRequestDto body) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "자동전달 설정을 저장했습니다.", mailForwardService.save(body, uid)));
    }

    @GetMapping("/forward/rules")
    public ResponseEntity<ApiResponse<List<MailForwardRuleDto>>> listForwardRules(
            HttpServletRequest request) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "자동전달 예외 규칙 목록", mailForwardService.listRules(uid)));
    }

    /**
     * 예외 규칙 생성 — 특정 발신자만 다른 주소로.
     *
     * <p>{@code matchType=DOMAIN} 이면 하위 도메인까지 걸린다(세금계산서·고지서처럼 발신
     * 도메인이 고정된 시스템 메일이 주된 쓰임이다). 상한은 10개로 다우오피스와 같다.
     *
     * <p><b>예외 규칙은 전체 자동전달과 독립이다.</b> 전체 전달이 꺼져 있어도 동작하고,
     * 켜져 있으면 예외 규칙이 이긴다. 다만 <b>원본 삭제는 적용되지 않는다</b> —
     * "이 발신자는 다른 사람이 처리한다"가 "내 이력에서 지운다"는 뜻은 아니기 때문이다.
     */
    @PostMapping("/forward/rules")
    public ResponseEntity<ApiResponse<MailForwardRuleDto>> createForwardRule(
            HttpServletRequest request,
            @Valid @RequestBody MailForwardRuleSaveRequestDto body) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "예외 규칙을 만들었습니다.", mailForwardService.createRule(body, uid)));
    }

    @PatchMapping("/forward/rules/{ruleIdx}")
    public ResponseEntity<ApiResponse<MailForwardRuleDto>> updateForwardRule(
            HttpServletRequest request,
            @PathVariable long ruleIdx,
            @Valid @RequestBody MailForwardRuleSaveRequestDto body) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "예외 규칙을 수정했습니다.", mailForwardService.updateRule(ruleIdx, body, uid)));
    }

    @DeleteMapping("/forward/rules/{ruleIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteForwardRule(
            HttpServletRequest request,
            @PathVariable long ruleIdx) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        mailForwardService.deleteRule(ruleIdx, uid);
        return ResponseEntity.ok(ApiResponse.success("예외 규칙을 삭제했습니다.", null));
    }

    // ── 내부 헬퍼 ───────────────────────────────────────────────────────────

    /** 토큰에서 확인된 호출자. 요청 파라미터가 아니므로 사칭할 수 없다. */
    private static String callerId(HttpServletRequest request) {
        Object v = request.getAttribute(AuthTokenFilter.ATTR_CURRENT_USER_ID);
        return v == null ? "" : v.toString();
    }
}
