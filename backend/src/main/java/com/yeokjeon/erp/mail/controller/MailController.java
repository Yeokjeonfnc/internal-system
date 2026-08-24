package com.yeokjeon.erp.mail.controller;

import com.yeokjeon.erp.auth.access.MenuAccessGuard;
import com.yeokjeon.erp.auth.access.MenuCodes;
import com.yeokjeon.erp.auth.token.AuthTokenFilter;
import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.mail.config.ResendProperties;
import com.yeokjeon.erp.mail.dto.MailAttachmentDto;
import com.yeokjeon.erp.mail.dto.MailBulkAction;
import com.yeokjeon.erp.mail.dto.MailBulkActionRequestDto;
import com.yeokjeon.erp.mail.dto.MailBulkActionResultDto;
import com.yeokjeon.erp.mail.dto.MailCountsDto;
import com.yeokjeon.erp.mail.dto.MailDetailDto;
import com.yeokjeon.erp.mail.dto.MailListItemDto;
import com.yeokjeon.erp.mail.dto.MailListQuery;
import com.yeokjeon.erp.mail.dto.MailReceiptDto;
import com.yeokjeon.erp.mail.dto.MailRecipientDto;
import com.yeokjeon.erp.mail.dto.MailSendRequestDto;
import com.yeokjeon.erp.mail.dto.MailSendResultDto;
import com.yeokjeon.erp.mail.dto.MailThreadDto;
import com.yeokjeon.erp.mail.dto.MailUpdateFlagsRequestDto;
import com.yeokjeon.erp.mail.service.MailAttachmentService;
import com.yeokjeon.erp.mail.service.MailBulkService;
import com.yeokjeon.erp.mail.service.MailFlagService;
import com.yeokjeon.erp.mail.service.MailQueryService;
import com.yeokjeon.erp.mail.service.MailReceiveService;
import com.yeokjeon.erp.mail.service.MailRecipientService;
import com.yeokjeon.erp.mail.service.MailSendService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;

/**
 * 메일(mal001) — ERP 내부 메일 송수신.
 *
 * <p>직원용 웹메일 대체가 아니라 거래처 응대 이력을 ERP 안에 남기기 위한 기능이다.
 * 그래서 조회·수정 권한을 개인 사서함이 아니라 {@code mal001} 메뉴 권한으로 판정한다
 * ({@link MenuAccessGuard}). "내 메일만" 은 권한이 아니라 필터이므로 {@code mine=true}
 * 쿼리로 표현한다.
 *
 * <p><b>{@code userId} 를 쿼리 파라미터 이름으로 쓰지 말 것</b> — {@code AuthTokenFilter}
 * 가 예약어로 잡아 토큰 주인과 다르면 무조건 403 이 되고, 원인이 화면에 드러나지 않는다.
 * 담당자 지정은 {@code ownerUserId} 를 쓴다.
 */
@Slf4j
@RestController
@RequestMapping("/mail")
@RequiredArgsConstructor
public class MailController {

    /** 목록 기본 조회 건수. 화면이 전량 로드 방식이라 넉넉히 준다. */
    private static final int DEFAULT_LIMIT = 100;

    /** 상한. 한 번에 더 달라고 해도 여기서 자른다(응답 크기·DB 부하 방어). */
    private static final int MAX_LIMIT = 500;

    /** 날짜 쿼리는 사용자가 보는 한국 날짜다. UTC 로 해석하면 하루 경계가 9시간 어긋난다. */
    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    private final MailQueryService mailQueryService;
    private final MailFlagService mailFlagService;
    private final MailSendService mailSendService;
    private final MailReceiveService mailReceiveService;
    private final MailAttachmentService mailAttachmentService;
    private final MailBulkService mailBulkService;
    private final MailRecipientService mailRecipientService;
    private final MenuAccessGuard menuAccessGuard;
    private final ResendProperties resendProperties;

    // ── 1. 상태 확인 ────────────────────────────────────────────────────────

    /**
     * 메일 기능 설정 상태.
     *
     * <p>키 미설정으로 메일만 조용히 안 도는 상태를 화면에서 구분하려고 둔다.
     * 키 <b>값</b>은 절대 내보내지 않고 설정 여부(boolean)만 알린다.
     */
    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Map<String, Object>>> health(HttpServletRequest request) {
        menuAccessGuard.ensure(callerId(request), MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "메일 API 정상",
                Map.of(
                        "service", "mail",
                        "status", "UP",
                        "resendConfigured", resendProperties.isApiKeyConfigured(),
                        "webhookConfigured", resendProperties.isWebhookConfigured(),
                        "syncEnabled", resendProperties.getSync().isEnabled())));
    }

    // ── 2~5. 목록 · 건수 ────────────────────────────────────────────────────

    @GetMapping("/messages")
    public ResponseEntity<ApiResponse<List<MailListItemDto>>> listMessages(
            HttpServletRequest request,
            @RequestParam(required = false, defaultValue = "inbox") String folder,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fromDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate toDate,
            @RequestParam(required = false, defaultValue = "" + DEFAULT_LIMIT) int limit,
            @RequestParam(required = false, defaultValue = "0") int offset,
            @RequestParam(required = false, defaultValue = "false") boolean mine) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        MailListQuery query = buildQuery(folder, keyword, fromDate, toDate, limit, offset, mine, uid);
        return ResponseEntity.ok(ApiResponse.success(
                "메일 목록", mailQueryService.listByFolder(query)));
    }

    @GetMapping("/messages/count")
    public ResponseEntity<ApiResponse<Integer>> countMessages(
            HttpServletRequest request,
            @RequestParam(required = false, defaultValue = "inbox") String folder,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fromDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate toDate,
            @RequestParam(required = false, defaultValue = "false") boolean mine) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        // count 쿼리는 LIMIT/OFFSET 을 쓰지 않는다. 레코드가 int 를 요구하므로 형식값만 채운다.
        MailListQuery query = buildQuery(folder, keyword, fromDate, toDate, 1, 0, mine, uid);
        return ResponseEntity.ok(ApiResponse.success(
                "메일 건수", mailQueryService.countByFolder(query)));
    }

    /** 사이드바 뱃지용 폴더별 건수. 기본이 {@code mine=true} 인 이유는 "내 미읽음" 이 기본 관심사라서다. */
    @GetMapping("/counts")
    public ResponseEntity<ApiResponse<MailCountsDto>> counts(
            HttpServletRequest request,
            @RequestParam(required = false, defaultValue = "true") boolean mine) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "메일함 건수", mailQueryService.counts(mine ? uid : null)));
    }

    /**
     * 메일 상세.
     *
     * <p>수신 메일을 열면 읽음으로 표시한다. 표시 후 상세를 <b>다시</b> 읽는 이유는
     * {@code MailDetailDto} 가 불변 record 라 읽음 플래그만 갈아 끼울 수 없기 때문이다.
     * 재조회는 첫 열람 때만 일어나므로 비용은 무시할 만하다.
     */
    @GetMapping("/messages/{mailIdx}")
    public ResponseEntity<ApiResponse<MailDetailDto>> getMessage(
            HttpServletRequest request,
            @PathVariable long mailIdx) {

        menuAccessGuard.ensure(callerId(request), MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        MailDetailDto detail = mailQueryService.findDetail(mailIdx);

        if ("IN".equals(detail.summary().direction()) && !detail.summary().read()) {
            mailFlagService.markRead(mailIdx, true);
            detail = mailQueryService.findDetail(mailIdx);
        }
        return ResponseEntity.ok(ApiResponse.success("메일 상세", detail));
    }

    /**
     * 수신확인 조회 (mal001-G).
     *
     * <p>보낸메일함의 "확인/미확인" 컬럼은 목록의 {@code openedAt}/{@code openCnt} 만으로
     * 그릴 수 있다. 이 API 는 그 옆의 <b>상세 팝업</b>용이다 — 누가 언제 열었고 누구에게
     * 반송됐는지를 수신자별로 준다.
     *
     * <p>응답에 {@code trackingConfigured} 가 들어 있다. false 면 서버에 추적 설정
     * ({@code RESEND_TRACKING_BASE_URL})이 없어 픽셀이 아예 안 심긴 상태이므로, 화면은
     * "미확인"이 아니라 "수신확인 기능이 꺼져 있습니다" 로 안내해야 한다. 그러지 않으면
     * 사용자가 상대방이 안 읽었다고 오해한다.
     */
    @GetMapping("/messages/{mailIdx}/receipt")
    public ResponseEntity<ApiResponse<MailReceiptDto>> getReceipt(
            HttpServletRequest request,
            @PathVariable long mailIdx) {

        menuAccessGuard.ensure(callerId(request), MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "수신확인 조회", mailQueryService.findReceipt(mailIdx)));
    }

    // ── 6~7. 플래그 · 삭제 ──────────────────────────────────────────────────

    @PatchMapping("/messages/{mailIdx}/flags")
    public ResponseEntity<ApiResponse<MailListItemDto>> updateFlags(
            HttpServletRequest request,
            @PathVariable long mailIdx,
            @Valid @RequestBody MailUpdateFlagsRequestDto body) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.UPDATE);
        return ResponseEntity.ok(ApiResponse.success(
                "메일 정보가 수정되었습니다.", mailFlagService.updateFlags(mailIdx, body, uid)));
    }

    /** 소프트 삭제. 거래처 응대 이력이라 물리 삭제하지 않는다(감사 추적 유지). */
    @DeleteMapping("/messages/{mailIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteMessage(
            HttpServletRequest request,
            @PathVariable long mailIdx) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.DELETE);
        mailFlagService.softDelete(mailIdx, uid);
        return ResponseEntity.ok(ApiResponse.success("메일이 삭제되었습니다.", null));
    }

    /**
     * 목록 일괄 동작 (mal001-B) — 다우오피스에서 가장 많이 쓰는 조작.
     *
     * <p>필요 권한이 동작마다 다르다. 완전삭제·휴지통 이동은 DELETE, 나머지는 UPDATE 다.
     * 컨트롤러에서 action 별 if 를 늘어놓지 않고 {@link MailBulkAction} 상수가 직접
     * 들고 있게 한 이유는, 항목이 추가될 때 권한 검사만 빠뜨리기 쉬워서다.
     *
     * <p>동작 문자열 파싱을 여기서 먼저 하는 것도 그 때문이다 — 권한을 정하려면
     * 무슨 동작인지 알아야 하고, 모르는 값은 권한 검사 전에 400 으로 끊는 편이 안전하다.
     */
    @PostMapping("/messages/bulk")
    public ResponseEntity<ApiResponse<MailBulkActionResultDto>> bulkAction(
            HttpServletRequest request,
            @Valid @RequestBody MailBulkActionRequestDto body) {

        String uid = callerId(request);
        MailBulkAction action = MailBulkAction.from(body.action());
        menuAccessGuard.ensure(uid, MenuCodes.MAL001,
                action.permission() == MailBulkAction.Permission.DELETE
                        ? MenuAccessGuard.Action.DELETE
                        : MenuAccessGuard.Action.UPDATE);

        MailBulkActionResultDto result = mailBulkService.execute(body, uid);
        return ResponseEntity.ok(ApiResponse.success(result.message(), result));
    }

    // ── 8~9. 작성 · 발송 ────────────────────────────────────────────────────

    /** 작성 저장. {@code sendNow=false} 면 DRAFT 로만 남겨 첨부를 붙일 수 있게 한다. */
    @PostMapping("/messages")
    public ResponseEntity<ApiResponse<MailSendResultDto>> compose(
            HttpServletRequest request,
            @Valid @RequestBody MailSendRequestDto body) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.CREATE);
        MailSendResultDto result = mailSendService.compose(body, uid);
        return ResponseEntity.ok(ApiResponse.success(result.message(), result));
    }

    /**
     * DRAFT → QUEUED.
     *
     * <p>여기서 Resend 를 직접 호출하지 않는다. 외부 HTTP 를 요청 스레드에서 하면 Resend 가
     * 느릴 때 화면이 그대로 멈추고, rate limit(10 req/s) 도 사용자 클릭 수에 좌우된다.
     * 실제 발송은 {@code MailSendWorker} 가 가져간다 — 즉 <b>어느 인스턴스에서든
     * {@code RESEND_SYNC_ENABLED=true} 가 하나는 켜져 있어야</b> 큐가 소진된다.
     */
    @PostMapping("/messages/{mailIdx}/send")
    public ResponseEntity<ApiResponse<MailSendResultDto>> send(
            HttpServletRequest request,
            @PathVariable long mailIdx) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.CREATE);
        MailSendResultDto result = mailSendService.queue(mailIdx, uid);
        return ResponseEntity.ok(ApiResponse.success(result.message(), result));
    }

    /**
     * 예약 발송 취소 (mal001-F).
     *
     * <p>Resend 는 예약 메일의 <b>시각만</b> 바꿀 수 있고 내용은 못 고친다. 그래서
     * "예약 수정" API 를 두지 않았다 — 내용을 바꾸려면 이 API 로 취소해 임시보관함으로
     * 되돌린 뒤 고쳐서 다시 보내는 흐름이다. 화면도 그렇게 안내해야 한다.
     *
     * <p>발송 계열이라 CREATE 권한으로 판정한다. DELETE 로 하면 "예약을 걸 수는 있는데
     * 취소는 못 하는" 사용자가 생긴다.
     */
    @PostMapping("/messages/{mailIdx}/cancel-schedule")
    public ResponseEntity<ApiResponse<MailSendResultDto>> cancelSchedule(
            HttpServletRequest request,
            @PathVariable long mailIdx) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.CREATE);
        MailSendResultDto result = mailSendService.cancelSchedule(mailIdx, uid);
        return ResponseEntity.ok(ApiResponse.success(result.message(), result));
    }

    // ── 10~12. 첨부 ─────────────────────────────────────────────────────────

    @PostMapping(value = "/messages/{mailIdx}/attachments",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<MailAttachmentDto>> uploadAttachment(
            HttpServletRequest request,
            @PathVariable long mailIdx,
            @RequestParam("file") MultipartFile file) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.CREATE);
        return ResponseEntity.ok(ApiResponse.success(
                "파일이 업로드되었습니다.", mailAttachmentService.upload(mailIdx, file, uid)));
    }

    /**
     * 첨부 다운로드.
     *
     * <p><b>경로가 반드시 {@code /download} 로 끝나야 한다.</b> {@code AuthTokenFilter} 는
     * 그 경우에만 {@code ?token=} 쿼리 토큰을 허용하는데, 브라우저 새 탭 다운로드는
     * Authorization 헤더를 실을 수 없어 이 규칙에 전적으로 의존한다. 경로를 바꾸면
     * 다운로드가 전부 401 이 된다.
     *
     * <p>이 응답만 {@code ApiResponse} 봉투를 쓰지 않는다 — 파일 바이트 자체가 본문이다.
     */
    @GetMapping("/attachments/{mailAttIdx}/download")
    public ResponseEntity<Resource> downloadAttachment(
            HttpServletRequest request,
            @PathVariable long mailAttIdx) {

        menuAccessGuard.ensure(callerId(request), MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        MailAttachmentService.DownloadPayload payload = mailAttachmentService.download(mailAttIdx);
        // 한글 파일명은 RFC 5987 형식으로 내보내야 브라우저에서 깨지지 않는다(BoardController 와 동일).
        String encoded =
                URLEncoder.encode(payload.fileName(), StandardCharsets.UTF_8).replace("+", "%20");
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename*=UTF-8''" + encoded)
                .contentType(
                        payload.contentType() != null
                                ? MediaType.parseMediaType(payload.contentType())
                                : MediaType.APPLICATION_OCTET_STREAM)
                .body(payload.resource());
    }

    @DeleteMapping("/attachments/{mailAttIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteAttachment(
            HttpServletRequest request,
            @PathVariable long mailAttIdx) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.DELETE);
        mailAttachmentService.delete(mailAttIdx, uid);
        return ResponseEntity.ok(ApiResponse.success("첨부 파일이 삭제되었습니다.", null));
    }

    // ── 13~15. 스레드 · 본문 재수집 · 거래처별 ──────────────────────────────

    @GetMapping("/threads/{threadIdx}")
    public ResponseEntity<ApiResponse<MailThreadDto>> getThread(
            HttpServletRequest request,
            @PathVariable long threadIdx) {

        menuAccessGuard.ensure(callerId(request), MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "메일 스레드", mailQueryService.findThread(threadIdx)));
    }

    /**
     * 본문 수동 재수집.
     *
     * <p>웹훅에는 본문이 없어 별도 API 로 채우는데, 그 호출이 실패하면 본문이 빈 채로
     * 남는다. 워커가 재시도하지만 {@code max-try-cnt} 를 넘기면 멈추므로 화면에서
     * 직접 다시 받을 수단을 열어 둔다. 이 호출만 요청 스레드에서 외부 API 를 탄다.
     */
    @PostMapping("/messages/{mailIdx}/refresh-body")
    public ResponseEntity<ApiResponse<MailDetailDto>> refreshBody(
            HttpServletRequest request,
            @PathVariable long mailIdx) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.UPDATE);
        log.info("메일 본문 재수집 요청: mailIdx={}, userId={}", mailIdx, uid);
        return ResponseEntity.ok(ApiResponse.success(
                "본문을 다시 가져왔습니다.", mailReceiveService.fetchBody(mailIdx)));
    }

    /** 거래처 상세 화면에서 "이 거래처와 주고받은 메일" 을 보여줄 때 쓴다. */
    @GetMapping("/partners/{partnerIdx}/messages")
    public ResponseEntity<ApiResponse<List<MailListItemDto>>> listByPartner(
            HttpServletRequest request,
            @PathVariable int partnerIdx,
            @RequestParam(required = false, defaultValue = "" + DEFAULT_LIMIT) int limit) {

        menuAccessGuard.ensure(callerId(request), MenuCodes.MAL001, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(
                "거래처 메일 목록", mailQueryService.listByPartner(partnerIdx, clampLimit(limit))));
    }

    // ── 16~17. 조직도 수신자 ────────────────────────────────────────────────

    /**
     * 조직도 수신자 검색 (mal001-J) — 사원 + 거래처 + 부서 통합.
     *
     * <p>발송 화면의 주소 선택기가 쓴다. 조회 권한이 아니라 <b>CREATE</b> 로 판정하는
     * 이유: 이 결과에는 전 직원 메일주소와 부서 구조가 담긴다. 메일을 보낼 수 없는
     * 사용자에게 조직 전체의 주소록을 열어 줄 이유가 없다.
     *
     * <p>검색어를 비우면 전체를 준다(대상이 73건뿐이라 첫 진입에서 조직도를 그대로 펼친다).
     */
    @GetMapping("/recipients")
    public ResponseEntity<ApiResponse<List<MailRecipientDto>>> searchRecipients(
            HttpServletRequest request,
            @RequestParam(name = "q", required = false) String q,
            @RequestParam(required = false, defaultValue = "0") int limit) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.CREATE);
        return ResponseEntity.ok(ApiResponse.success(
                "수신자 검색 결과", mailRecipientService.search(q, limit)));
    }

    /**
     * 부서원 메일주소 펼치기 (mal001-J).
     *
     * <p>부서 자체에는 주소가 없어서, 화면이 부서를 고르면 이 API 로 부서원 주소를 받는다.
     *
     * <p>{@code includeSub} 기본값이 false 인 이유: 상위 부서를 잘못 고르면 전 직원에게
     * 나가는 사고가 난다. 하위 포함은 사용자가 명시적으로 켤 때만 동작해야 한다.
     *
     * <p>50명을 넘어도 막지 않는다 — 발송 단계가 50명씩 나눠 여러 통으로 보낸다.
     * 다만 응답 건수를 보고 화면이 미리 안내하는 편이 좋다.
     */
    @GetMapping("/recipients/dept/{deptIdx}")
    public ResponseEntity<ApiResponse<List<MailRecipientDto>>> deptRecipients(
            HttpServletRequest request,
            @PathVariable int deptIdx,
            @RequestParam(required = false, defaultValue = "false") boolean includeSub) {

        String uid = callerId(request);
        menuAccessGuard.ensure(uid, MenuCodes.MAL001, MenuAccessGuard.Action.CREATE);
        return ResponseEntity.ok(ApiResponse.success(
                "부서 수신자 목록", mailRecipientService.deptMembers(deptIdx, includeSub)));
    }

    // ── 내부 헬퍼 ───────────────────────────────────────────────────────────

    private static MailListQuery buildQuery(
            String folder,
            String keyword,
            LocalDate fromDate,
            LocalDate toDate,
            int limit,
            int offset,
            boolean mine,
            String callerUserId) {

        return new MailListQuery(
                folder,
                // 사용자 정의 메일함은 folder="folder:12" 형태로 들어온다.
                // 여기서 쪼개지 않고 MailQueryService.normalize 가 한다 — 목록과 카운트가
                // 반드시 같은 정규화를 거쳐야 "목록 3건 / 카운트 5건" 사고가 안 난다.
                null,
                mine ? callerUserId : null,
                keyword,
                startOfDay(fromDate),
                endOfDayExclusive(toDate),
                clampLimit(limit),
                Math.max(offset, 0));
    }

    /** 한국 시각 자정. */
    private static OffsetDateTime startOfDay(LocalDate date) {
        return date == null ? null : date.atStartOfDay(SEOUL).toOffsetDateTime();
    }

    /**
     * 종료일 <b>다음날</b> 한국 시각 자정.
     *
     * <p>조회 조건이 {@code mail_at < toDate} 인 상한 배타 방식이라, 종료일 자정을 그대로
     * 넣으면 사용자가 지정한 그 날 하루가 통째로 빠진다.
     */
    private static OffsetDateTime endOfDayExclusive(LocalDate date) {
        return date == null ? null : date.plusDays(1).atStartOfDay(SEOUL).toOffsetDateTime();
    }

    private static int clampLimit(int limit) {
        if (limit < 1) {
            return DEFAULT_LIMIT;
        }
        return Math.min(limit, MAX_LIMIT);
    }

    /** 토큰에서 확인된 호출자. 요청 파라미터가 아니므로 사칭할 수 없다. */
    private static String callerId(HttpServletRequest request) {
        Object v = request.getAttribute(AuthTokenFilter.ATTR_CURRENT_USER_ID);
        return v == null ? "" : v.toString();
    }
}
