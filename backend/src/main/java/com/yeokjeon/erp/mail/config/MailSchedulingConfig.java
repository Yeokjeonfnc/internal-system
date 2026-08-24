package com.yeokjeon.erp.mail.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * 메일 워커용 스케줄러 활성화.
 *
 * <p><b>{@code YeokjeonErpApplication} 에 {@code @EnableScheduling} 을 붙이지 않은 이유</b> —
 * 거기에 붙이면 스케줄러가 앱 전체에서 무조건 켜지고, 나중에 다른 모듈이 {@code @Scheduled}
 * 를 추가하면 메일 설정과 무관하게 같이 돌아버린다. 여기서 조건부로 켜면 메일 동기화를
 * 끈 인스턴스는 스케줄러 스레드조차 만들지 않는다.
 *
 * <p><b>스레드 풀을 따로 두지 않은 이유</b> — Boot 기본 스케줄러는 단일 스레드라 워커 4개가
 * 순차 실행된다. 이건 실수가 아니라 의도다. Resend rate limit 은 팀 단위 10 req/s 이므로
 * 워커들이 동시에 외부 호출을 쏘지 않고 줄을 서는 편이 안전하다. 각 워커는 {@code fixedRate}
 * 가 아닌 {@code fixedDelay} 를 쓰므로 이전 실행이 끝나야 다음 실행이 잡힌다(자기 자신과의
 * 중첩 실행 없음).
 */
@Configuration
@EnableScheduling
@ConditionalOnProperty(prefix = "resend.sync", name = "enabled", havingValue = "true")
public class MailSchedulingConfig {
}
