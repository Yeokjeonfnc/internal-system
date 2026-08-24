package com.yeokjeon.erp.mail.config;

import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * "저장 직후 즉시 한 건 처리" 전용 실행기 (mal001-M).
 *
 * <p><b>왜 필요한가.</b> 메일 송수신은 전부 폴링이다 — 발송은 QUEUED 로 저장만 하고 워커가
 * 집어갈 때까지, 수신은 웹훅이 메타만 넣고({@code body_status='PENDING'}) 워커가 집어갈
 * 때까지 아무 일도 일어나지 않는다. 주기를 줄여도 평균 대기시간이 반으로 줄 뿐이고,
 * 주기를 더 줄이면 빈 조회만 늘어난다. 근본 해법은 <b>저장 직후 그 한 건을 즉시 시도</b>
 * 하는 것이다.
 *
 * <p><b>즉시 트리거는 최적화이지 유일 경로가 아니다.</b> 여기서 실패하거나 큐가 넘쳐
 * 버려져도 데이터는 QUEUED/PENDING 그대로 남고 기존 워커가 다음 주기에 집어 간다.
 * 그래서 이 클래스는 <b>어떤 경우에도 예외를 밖으로 던지지 않는다</b> — 호출부(웹훅
 * 응답, 작성 API 응답)를 즉시 트리거 실패로 망가뜨리면 안 된다.
 *
 * <p><b>스프링 {@code @Async} 를 쓰지 않는 이유.</b> {@code @EnableAsync} 는 앱 전체에
 * 프록시를 켜는 전역 스위치라 메일과 무관한 빈의 동작까지 바뀔 수 있고, 기본
 * {@code SimpleAsyncTaskExecutor} 는 요청마다 스레드를 새로 만들어 폭주를 못 막는다.
 * 무엇보다 {@code @Async} 는 프록시 기반이라 <b>같은 빈 안에서 호출하면 그냥 동기 실행</b>
 * 이 되는데, 이 기능의 호출부는 전부 자기 서비스 안이라 그 함정에 정확히 걸린다.
 * 그래서 실행기를 직접 들고 명시적으로 제출한다.
 *
 * <p><b>{@code resend.sync.enabled} 로 끄지 않는다.</b> 워커들은 그 플래그로 한 인스턴스
 * 에서만 돌게 막혀 있다(현장 3001 / 운영 3011 이 같은 JAR 로 뜬다). 즉시 트리거까지 같은
 * 조건을 붙이면, <b>사용자 요청을 받는 인스턴스가 워커를 끈 쪽일 때 이 기능이 통째로
 * 죽는다</b> — 그것도 조용히. 그래서 켜 두되 안전성은 다른 곳에서 보장한다:
 * 각 인스턴스는 자기가 방금 만든 건만 트리거하고, 워커와 겹치면
 * {@code claimSendQueued}/{@code claimBodyPending} 의 조건부 UPDATE 가 한 쪽만 통과시키며,
 * 그래도 뚫리면 Resend {@code Idempotency-Key} 가 마지막으로 막는다.
 *
 * <p><b>풀 크기와 큐를 작게 잡는다.</b> 이 실행기의 일감은 전부 Resend 외부 호출로
 * 이어지고, Resend rate limit 은 팀 단위 10 req/s 다. 스레드를 늘리면 즉시 트리거가
 * 워커 몫의 rate limit 까지 태워 버린다. 큐가 차면 {@link ThreadPoolExecutor.DiscardPolicy}
 * 로 <b>조용히 버린다</b> — 버려도 워커가 처리하므로 안전하고, 여기서 호출 스레드를
 * 블로킹하면(CallerRuns) 웹훅 응답이 늦어져 Resend 재전송을 부른다.
 */
@Slf4j
@Component
public class MailImmediateExecutor {

    /**
     * 동시에 나갈 수 있는 즉시 호출 수.
     *
     * <p>2 로 고정한다. 워커(단일 스레드 스케줄러)와 합쳐도 동시 외부 호출이 3을 넘지
     * 않아 10 req/s 안에 넉넉히 들어간다.
     */
    private static final int POOL_SIZE = 2;

    /** 대기 큐 길이. 넘치면 버린다(워커가 처리한다). */
    private static final int QUEUE_CAPACITY = 100;

    /**
     * 즉시 호출 사이의 최소 간격.
     *
     * <p>기존 코드에는 전용 rate limiter 가 없다. 지금까지의 스로틀은 "단일 스레드
     * 스케줄러 + 배치 크기"였고, 즉시 트리거는 그 통제 밖에서 돌기 때문에 이 경로에만
     * 최소 간격을 둔다. 200ms 면 이 경로가 최대 5 req/s 라 워커 몫이 남는다.
     *
     * <p>간격 대기는 <b>풀 스레드 안에서만</b> 일어난다. 호출 스레드(요청·웹훅)는
     * 제출만 하고 즉시 돌아간다.
     */
    private static final long MIN_GAP_NANOS = TimeUnit.MILLISECONDS.toNanos(200);

    private final ThreadPoolExecutor executor;

    /** 다음 호출이 허용되는 시각(System.nanoTime 기준). 스로틀 게이트가 이 값만 공유한다. */
    private final Object gate = new Object();
    private long nextAllowedAtNanos = System.nanoTime();

    public MailImmediateExecutor() {
        ThreadFactory factory = new ThreadFactory() {
            private final AtomicInteger seq = new AtomicInteger(1);

            @Override
            public Thread newThread(Runnable r) {
                Thread t = new Thread(r, "mail-now-" + seq.getAndIncrement());
                // 데몬으로 둔다. 즉시 트리거는 없어도 되는 최적화라, 종료할 때
                // 남은 일감 때문에 JVM 이 안 내려가는 상황을 만들지 않는다.
                t.setDaemon(true);
                return t;
            }
        };
        this.executor = new ThreadPoolExecutor(
                POOL_SIZE, POOL_SIZE,
                0L, TimeUnit.MILLISECONDS,
                new ArrayBlockingQueue<>(QUEUE_CAPACITY),
                factory,
                new ThreadPoolExecutor.DiscardPolicy());
    }

    /**
     * 지금 바로 비동기 실행한다(트랜잭션과 무관한 경로용).
     *
     * <p>이 메서드는 절대 예외를 던지지 않는다. 큐가 가득 차면 조용히 버려진다.
     *
     * @param label 로그용 이름. 어떤 즉시 트리거가 돌았는지 추적할 수 있어야 한다.
     */
    public void run(String label, Runnable task) {
        if (task == null) {
            return;
        }
        try {
            executor.execute(() -> execute(label, task));
        } catch (RejectedExecutionException e) {
            // DiscardPolicy 라 정상 경로에서는 오지 않는다. 종료 중일 때만 가능하다.
            log.debug("즉시 트리거 제출 거부(무시) label={}", label);
        } catch (RuntimeException e) {
            log.warn("즉시 트리거 제출 실패(무시) label={}", label, e);
        }
    }

    /**
     * <b>커밋된 뒤에</b> 비동기 실행한다.
     *
     * <p>즉시 트리거의 일감은 방금 저장한 행을 다시 읽는다. 트랜잭션이 아직 커밋되지
     * 않은 채로 다른 스레드가 조회하면 그 행은 <b>보이지 않는다</b>(READ COMMITTED).
     * 그러면 즉시 트리거는 매번 헛돌고 결국 워커가 다 처리하게 되어, 기능이 있으나 마나
     * 한 상태가 조용히 만들어진다. 그래서 트랜잭션이 열려 있으면 커밋 이후로 미룬다.
     *
     * <p>트랜잭션이 없으면 이미 커밋된 상태이므로 곧바로 제출한다
     * (수신 웹훅 경로가 여기 해당한다 — {@code MailWebhookService} 는 의도적으로
     * 트랜잭션 밖에서 돈다).
     *
     * <p>롤백되면 아무 것도 하지 않는다. {@code afterCommit} 만 구현했으므로 별도
     * 분기가 필요 없다.
     */
    public void runAfterCommit(String label, Runnable task) {
        if (task == null) {
            return;
        }
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            run(label, task);
            return;
        }
        try {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    run(label, task);
                }
            });
        } catch (RuntimeException e) {
            // 동기화 등록 실패로 본 트랜잭션을 깨뜨리지 않는다. 워커가 처리한다.
            log.warn("즉시 트리거 커밋후 등록 실패(무시) label={}", label, e);
        }
    }

    /** 풀 스레드에서 실제로 도는 부분 — 스로틀 통과 → 실행 → 예외 삼킴. */
    private void execute(String label, Runnable task) {
        try {
            awaitSlot();
            task.run();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (Exception e) {
            // 여기서 예외가 새어 나가면 풀 스레드만 죽고 원인은 어디에도 안 남는다.
            // 즉시 트리거 실패는 정상 시나리오다(워커가 다시 집는다). 기록만 한다.
            log.warn("즉시 트리거 실패 — 워커가 다시 처리한다. label={}", label, e);
        }
    }

    /** 최소 간격을 지킬 때까지 기다린다. 대기는 풀 스레드에서만 일어난다. */
    private void awaitSlot() throws InterruptedException {
        long waitNanos;
        synchronized (gate) {
            long now = System.nanoTime();
            // nextAllowedAtNanos 가 과거면 지금 바로 나가고, 다음 슬롯을 now 기준으로 잡는다.
            long start = Math.max(now, nextAllowedAtNanos);
            waitNanos = start - now;
            nextAllowedAtNanos = start + MIN_GAP_NANOS;
        }
        if (waitNanos > 0) {
            TimeUnit.NANOSECONDS.sleep(waitNanos);
        }
    }

    @PreDestroy
    void shutdown() {
        // 남은 대기 일감은 버린다 — 어차피 워커가 다시 집어 간다. 종료를 붙잡지 않는다.
        executor.shutdownNow();
    }
}
