package com.yeokjeon.erp.mail.service;

import com.yeokjeon.erp.mail.config.ResendProperties;
import com.yeokjeon.erp.mail.mapper.MailMstMapper;
import com.yeokjeon.erp.mail.support.MailOpenTokenCodec;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 수신확인(추적픽셀) 처리 (mal001-G).
 *
 * <p><b>이 서비스는 인증 없이 열린 엔드포인트가 부른다.</b> 수신자의 메일 클라이언트가
 * 이미지를 불러오는 요청이라 우리 로그인 토큰이 실릴 수 없다. 그래서 지켜야 할 규칙이 있다.
 * <ul>
 *   <li>어떤 입력에도 <b>예외를 밖으로 던지지 않는다</b> — 500 이 나가면 수신자 본문에
 *       깨진 이미지 아이콘이 뜬다. 우리 쪽 사정이 상대 화면을 망쳐서는 안 된다.</li>
 *   <li>유효/무효를 응답으로 구분하지 않는다 — 무엇을 주든 1x1 GIF 다. 응답이 갈리면
 *       그 차이가 토큰 유효성 판별기(oracle)가 된다.</li>
 *   <li>정보를 돌려주지 않는다 — 제목·수신자 같은 것은 한 글자도 나가면 안 된다.</li>
 * </ul>
 *
 * <p><b>정확도 한계</b>(반드시 화면 문구에 반영할 것): 대부분의 웹메일이 외부 이미지를
 * 기본 차단하므로 <b>읽어도 안 잡히고</b>, 반대로 Gmail 이미지 프록시나 보안 스캐너가
 * 배달 시점에 미리 받아 가면 <b>안 읽어도 잡힌다</b>. 즉 "수신확인 안 됨"은 "안 읽음"이
 * 아니다. 다우오피스도 같은 한계를 FAQ 로 안내한다. 자세한 내용은
 * {@code MailTrackingPixel} 클래스 주석 참고.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailOpenTrackingService {

    private final MailMstMapper mailMstMapper;
    private final ResendProperties properties;

    /**
     * 픽셀 호출 1건 처리.
     *
     * <p>실패해도 조용히 넘긴다. 열람 기록 하나를 못 남기는 것보다 수신자 본문이
     * 깨지는 쪽이 훨씬 나쁘다.
     *
     * <p><b>{@code @Transactional} 을 일부러 붙이지 않았다.</b> UPDATE 한 문장이라 트랜잭션이
     * 필요 없기도 하지만, 더 중요한 이유가 있다 — 트랜잭션 안에서 예외를 잡아 삼키면
     * 스프링이 rollback-only 로 표시된 트랜잭션을 커밋하려다
     * {@code UnexpectedRollbackException} 을 던진다. 즉 "조용히 실패한다"는 이 메서드의
     * 전제가 깨지고 결국 픽셀 응답이 500 이 된다.
     *
     * @return 실제로 기록됐으면 true(로그·테스트용). 컨트롤러는 이 값과 무관하게 GIF 를 준다.
     */
    public boolean recordOpen(String token) {
        if (!properties.isTrackingConfigured()) {
            // 키나 주소가 없으면 우리가 만든 적 없는 토큰이다. 검증 자체가 불가능하다.
            return false;
        }
        Long mailIdx;
        try {
            mailIdx = MailOpenTokenCodec.decode(token, properties.resolveTrackingSecret());
        } catch (RuntimeException e) {
            // 키가 중간에 비워지는 등 서명 계산 자체가 실패한 경우.
            log.debug("추적픽셀 토큰 해석 실패", e);
            return false;
        }
        if (mailIdx == null) {
            // 서명 불일치 또는 형식 오류. 스캐너 트래픽이 흔해 로그를 남기지 않는다 —
            // 남기면 공개 엔드포인트 하나로 로그를 무한정 부풀릴 수 있다.
            return false;
        }

        try {
            // 매퍼가 direction='OUT' 조건을 걸고 있어 수신 메일에는 기록되지 않는다.
            // opened_at 은 COALESCE 로 최초 1회만, open_cnt 는 매번 올라간다.
            int updated = mailMstMapper.markOpened(mailIdx);
            if (updated > 0) {
                log.debug("수신확인 기록 mailIdx={}", mailIdx);
                return true;
            }
            // 메일이 완전삭제됐거나 발신 메일이 아닌 경우. 정상 상황이라 warn 이 아니다.
            return false;
        } catch (RuntimeException e) {
            // DB 오류로 픽셀 응답이 500 이 되면 안 된다.
            log.warn("수신확인 기록 실패 mailIdx={}", mailIdx, e);
            return false;
        }
    }
}
