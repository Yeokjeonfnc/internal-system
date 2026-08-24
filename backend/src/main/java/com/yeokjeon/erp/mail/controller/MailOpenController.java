package com.yeokjeon.erp.mail.controller;

import com.yeokjeon.erp.mail.service.MailOpenTrackingService;
import com.yeokjeon.erp.mail.support.MailTrackingPixel;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 수신확인 추적픽셀 엔드포인트 (mal001-G).
 *
 * <p><b>이 컨트롤러는 인증 없이 열려야 한다.</b> 수신자의 메일 클라이언트가 이미지를
 * 불러오는 요청이라 우리 로그인 토큰을 실을 방법이 없다.
 *
 * <p><b>⚠ 다른 담당자 작업 필요</b> — {@code AuthTokenFilter.PUBLIC_PATHS} 에 이 경로를
 * 넣어야 한다. 그런데 지금 그 집합은 {@code Set.contains} <b>완전일치</b>라
 * {@code /mail/webhook} 처럼 고정 경로만 담을 수 있고, 여기는 토큰이 경로에 들어가므로
 * 완전일치로는 절대 맞지 않는다. 즉 <b>필터를 접두사 매칭으로 고쳐야 한다</b>:
 * <pre>
 *   // AuthTokenFilter.shouldNotFilter
 *   String path = pathWithinApi(request);
 *   return PUBLIC_PATHS.contains(path) || path.startsWith("/mail/open/");
 * </pre>
 * 이 작업 전까지 픽셀 요청은 전부 401 을 받고 수신확인이 하나도 잡히지 않는다
 * (수신자 화면에는 깨진 이미지가 뜬다).
 *
 * <p>보안상 이 경로가 열려도 위험하지 않은 이유: 토큰은 mail_idx 의 HMAC 서명이라
 * 서버 비밀키 없이는 만들 수 없고({@code MailOpenTokenCodec}), 응답은 언제나 1x1 GIF 라
 * 어떤 정보도 돌려주지 않는다. 할 수 있는 일은 "이미 발송된 특정 메일의 열람수를 올리는 것"
 * 하나뿐이며 그건 토큰을 이미 받은 수신자만 가능하다.
 *
 * <p><b>경로를 늘리지 말 것</b> — 접두사 매칭이 적용되면 {@code /mail/open/} 아래가 전부
 * 공개된다. 여기에 다른 API 를 추가하면 그것도 인증 없이 열린다.
 */
@Slf4j
@RestController
@RequestMapping("/mail")
@RequiredArgsConstructor
public class MailOpenController {

    private final MailOpenTrackingService mailOpenTrackingService;

    /**
     * 픽셀 호출.
     *
     * <p><b>무슨 일이 있어도 200 + 1x1 GIF 를 돌려준다.</b>
     * <ul>
     *   <li>토큰이 틀려도 404 를 주지 않는다 — 응답이 갈리면 그 차이가 토큰 유효성
     *       판별기(oracle)가 되고, 수신자 본문에는 깨진 이미지가 뜬다.</li>
     *   <li>DB 오류로 500 이 나가도 마찬가지다. 서비스가 예외를 안으로 삼키지만
     *       여기서도 한 번 더 막는다.</li>
     * </ul>
     *
     * <p>캐시를 막는 것이 기능상 필수다. 캐시되면 두 번째 열람부터 요청 자체가 오지 않아
     * open_cnt 가 1 에서 멈춘다. 프록시 캐시까지 막으려고 no-store 와 Pragma 를 함께 넣는다.
     */
    @GetMapping(value = "/open/{token}.gif", produces = MediaType.IMAGE_GIF_VALUE)
    public ResponseEntity<byte[]> open(@PathVariable String token) {
        try {
            mailOpenTrackingService.recordOpen(token);
        } catch (RuntimeException e) {
            // 서비스가 이미 삼키지만, 새 코드가 예외를 흘려도 픽셀은 깨지지 않아야 한다.
            log.debug("수신확인 처리 중 오류(무시하고 GIF 반환)", e);
        }
        byte[] gif = MailTrackingPixel.transparentGif();
        return ResponseEntity.ok()
                .contentType(MediaType.IMAGE_GIF)
                .cacheControl(CacheControl.noStore().mustRevalidate())
                .header(HttpHeaders.PRAGMA, "no-cache")
                .header(HttpHeaders.EXPIRES, "0")
                .contentLength(gif.length)
                .body(gif);
    }
}
