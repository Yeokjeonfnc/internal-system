package com.yeokjeon.erp.mail.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.yeokjeon.erp.auth.access.AccessDeniedException;
import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.mail.dto.resend.ResendWebhookEventDto;
import com.yeokjeon.erp.mail.service.MailWebhookService;
import com.yeokjeon.erp.mail.webhook.SvixSignatureVerifier;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Resend 웹훅 수신 엔드포인트(mal001).
 *
 * <p><b>이 컨트롤러만 인증 없이 열려 있다.</b> Resend 서버가 직접 POST 하므로 우리 로그인
 * 토큰을 실을 방법이 없어 {@code AuthTokenFilter.PUBLIC_PATHS} 에 {@code /mail/webhook} 을
 * 넣었다. 대신 Svix 서명이 유일한 방어선이다 — {@link SvixSignatureVerifier} 검증을
 * 우회하는 분기를 절대 추가하지 말 것.
 *
 * <p><b>경로를 늘리지 말 것</b> — {@code PUBLIC_PATHS} 는 {@code contains} 완전일치라
 * {@code /mail/webhook/xxx} 같은 하위 경로를 만들면 그 경로는 인증이 걸려 Resend 가
 * 401 만 받고 이벤트를 영영 못 넘긴다.
 */
@Slf4j
@RestController
@RequestMapping("/mail")
@RequiredArgsConstructor
public class MailWebhookController {

    private final SvixSignatureVerifier svixSignatureVerifier;
    private final MailWebhookService mailWebhookService;
    private final ObjectMapper objectMapper;

    /**
     * 웹훅 1건 수신.
     *
     * <p>본문을 {@code @RequestBody String} 으로 받는 것이 필수다. DTO 로 바인딩하면 원문
     * 바이트가 사라져 서명 검증이 구조적으로 불가능해진다(Jackson 이 재직렬화한 JSON 은
     * 공백·키 순서가 달라 HMAC 이 절대 안 맞는다).
     *
     * <p>응답은 서명 검증과 {@code svix-id} 확인만 통과하면 <b>언제나 200</b> 이다. 처리 실패로 4xx/5xx 를 주면
     * Resend 가 재시도를 계속 쌓아 같은 이벤트가 폭주하고, 그 사이 정상 이벤트까지 밀린다.
     * 실패건은 {@code mail_webhook_log} 에 FAILED 로 남고 유지보수 워커가 다시 처리한다.
     */
    @PostMapping("/webhook")
    public ResponseEntity<ApiResponse<Void>> receive(
            @RequestHeader(value = "svix-id", required = false) String svixId,
            @RequestHeader(value = "svix-timestamp", required = false) String svixTimestamp,
            @RequestHeader(value = "svix-signature", required = false) String svixSignature,
            @RequestBody String rawBody) {

        if (!svixSignatureVerifier.verify(svixId, svixTimestamp, svixSignature, rawBody)) {
            // 서명이 틀렸다는 건 우리가 보낸 적 없는 요청이라는 뜻이다. 본문은 로그에 남기지 않는다.
            throw new AccessDeniedException("웹훅 서명 검증에 실패했습니다.");
        }

        // svix-id 가 없으면 400 으로 거부한다. 예전에는 여기서 UUID 를 만들어 넣었는데,
        // 그러면 svix_id 가 매번 달라 원장 PK 충돌도 mail_event_log 의 ON CONFLICT 도
        // 걸리지 않아 같은 페이로드를 N회 던지면 이벤트가 그대로 N배로 쌓인다.
        // "중복 판별 불가"를 "중복 판별 생략"으로 바꿔치기하는 셈이라, 멱등성이 조용히 사라진다.
        // (MailWebhookService.handle 도 빈 svixId 를 거부하도록 쓰여 있는데, 그 가드가
        //  이 대체 키 때문에 도달 불가능한 죽은 코드가 돼 있었다.)
        // Resend/Svix 는 항상 이 헤더를 싣는다. 로컬에서 흉내 낼 때만 임의 값을 직접 주면 된다.
        if (svixId == null || svixId.isBlank()) {
            throw new IllegalArgumentException("svix-id 헤더가 없어 중복 처리를 막을 수 없습니다.");
        }

        try {
            ResendWebhookEventDto event = objectMapper.readValue(rawBody, ResendWebhookEventDto.class);
            MailWebhookService.Result result = mailWebhookService.handle(svixId, rawBody, event);
            log.info("메일 웹훅 수신: type={}, svixId={}, result={}", event.type(), svixId, result);
        } catch (Exception e) {
            // 파싱 실패든 처리 실패든 200 을 돌려준다(위 주석의 재시도 폭주 방지).
            // 원장 기록은 handle() 안에서 하므로, 여기까지 예외가 올라왔다면 트랜잭션이
            // 롤백돼 원장에도 안 남는다. 그때는 svixId 로 Resend 대시보드에서 재전송한다.
            log.error("메일 웹훅 처리 실패: svixId={}, 원인={}", svixId, e.toString());
        }

        return ResponseEntity.ok(ApiResponse.success("수신했습니다.", null));
    }
}
