package com.yeokjeon.erp.mail.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.OffsetDateTime;
import java.util.List;

/**
 * 메일 작성/발송 요청.
 *
 * <p>수신자 목록에 50건 상한을 둔 이유는 Resend 자체 제한이 아니라 우리 쪽 방어다.
 * 실수로 전체 거래처 주소를 통째로 밀어 넣으면 무료 한도(하루 100통)를 한 번에
 * 태우고, 그 뒤 모든 메일이 조용히 실패한다.
 *
 * <p>{@code @JsonIgnoreProperties(ignoreUnknown = true)} 는 프런트가 화면 상태값을
 * 같이 실어 보내도 400 으로 튕기지 않게 하려는 것이다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record MailSendRequestDto(
        /**
         * 비우면 resend.from-email 을 쓴다.
         *
         * <p>여기 값을 그대로 믿으면 안 된다 — Resend 는 "검증된 도메인인가"만 보므로
         * <b>도메인 밖 사칭은 막히지만 도메인 안 사칭(ceo@, finance@)은 통과한다</b>.
         * 그래서 서버가 resend.from-email + resend.allowed-from-emails 목록과 대조해
         * 허용되지 않은 주소는 거부한다({@code MailSendService.resolveFromEmail}).
         * 여기 @Email 은 형식 방어일 뿐 권한 검사가 아니다.
         */
        @Email @Size(max = 320) String fromEmail,
        /**
         * 비우면 resend.from-name. 표시이름은 자유 입력이지만 실제 발신 주소는 위 목록으로
         * 고정되므로, 수신자 메일 클라이언트에서 주소를 보면 사칭 여부를 확인할 수 있다.
         */
        @Size(max = 255) String fromNm,
        /**
         * 받는 사람. <b>Resend 는 한 요청의 to 를 최대 50명까지만 받는다.</b>
         *
         * <p>그런데 조직도에서 부서를 통째로 고르면 50명을 넘길 수 있어서(우리 부서
         * 하나가 이미 그 언저리다) 여기서 50 으로 막아 버리면 "부서 전체 발송"이
         * 아예 불가능해진다. 그래서 요청은 200명까지 받고, <b>발송 단계에서 50명씩
         * 나눠 여러 통으로 보낸다</b>({@code MailSendService.compose}).
         *
         * <p>200 이라는 상한은 Resend 제한이 아니라 우리 쪽 방어다 — 실수로 전체 주소록을
         * 밀어 넣으면 무료 한도(하루 100통)를 한 번에 태우고 그 뒤 모든 메일이 조용히 실패한다.
         */
        @NotEmpty @Size(max = 200, message = "받는 사람은 한 번에 200명까지 지정할 수 있습니다.")
        List<@NotBlank @Email @Size(max = 320) String> to,
        @Size(max = 50) List<@Email @Size(max = 320) String> cc,
        @Size(max = 50) List<@Email @Size(max = 320) String> bcc,
        @Size(max = 50) List<@Email @Size(max = 320) String> replyTo,
        @NotBlank @Size(max = 500) String subject,
        String bodyHtml,
        String bodyText,
        /** 답장일 때 원본 mail_idx — 스레드·In-Reply-To 를 여기서 잇는다 */
        Long replyToMailIdx,
        Integer partnerIdx,
        Long mappingId,
        /** true(기본)=즉시 QUEUED, false=DRAFT 로만 저장(첨부 붙일 때) */
        Boolean sendNow,

        // ── 2차 확장 ────────────────────────────────────────────────────────

        /**
         * 예약발송 시각. 값이 있으면 {@code sendNow} 와 무관하게 예약으로 저장된다.
         *
         * <p>Resend 는 최대 30일 뒤까지만 예약을 받고, <b>예약된 뒤에는 시각만 바꿀 수 있다</b>
         * (본문·수신자 변경 불가). 그래서 화면 흐름은 "수정"이 아니라
         * "취소({@code POST /mail/messages/{idx}/cancel-schedule}) → 다시 작성" 이다.
         *
         * <p>과거 시각은 서비스가 거부한다 — Resend 에 넘기면 즉시 발송돼 버려서
         * 사용자가 "예약했는데 바로 나갔다"고 느낀다.
         */
        OffsetDateTime scheduledAt,

        /**
         * 수신확인 요청. true 면 본문 끝에 1x1 추적픽셀을 심는다.
         *
         * <p><b>정확도에 한계가 있다.</b> 수신자 메일 클라이언트가 원격 이미지를 차단하면
         * 읽어도 잡히지 않고, 반대로 보안 스캐너가 미리 받아 가면 안 읽어도 잡힌다.
         * 자세한 내용은 {@code MailTrackingPixel} 클래스 주석 참고.
         */
        Boolean readReceipt,

        /**
         * 중요도 H(높음)/N(보통)/L(낮음). 비우면 N.
         *
         * <p>H 면 발송 시 {@code X-Priority: 1} 계열 헤더가 붙는다. 다만 이 헤더를
         * 존중할지는 전적으로 수신자 클라이언트에 달렸다(무시하는 웹메일이 많다).
         */
        // 긴 표기(HIGH/NORMAL/LOW)도 받는다.
        //
        // 서비스의 normalizeImportance 는 "모르는 값이면 보통으로 본다 — 발송을 막을
        // 만한 사안이 아니다"라고 되어 있는데, 이 @Pattern 이 그보다 먼저 400 을 냈다.
        // 실제로 화면이 HIGH 를 보내면서 중요 체크만 하면 발송이 통째로 막혔다.
        @Pattern(regexp = "(?i)[HNL]|HIGH|NORMAL|LOW",
                message = "중요도는 H(높음), N(보통), L(낮음) 중 하나여야 합니다.")
        String importance) {
}
