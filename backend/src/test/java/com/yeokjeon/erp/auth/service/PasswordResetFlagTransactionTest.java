package com.yeokjeon.erp.auth.service;

import com.yeokjeon.erp.master.service.MstService;
import org.junit.jupiter.api.Test;
import org.springframework.transaction.annotation.Transactional;

import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * {@code pwd_reset_yn} 갱신이 다른 작업과 같은 트랜잭션에 묶이지 않도록 강제한다.
 *
 * <p><b>왜 동작 테스트가 아니라 구조를 검사하나:</b> 이 결함의 본질은 "PostgreSQL 이
 * 문장 오류 시 트랜잭션 전체를 abort 시킨다"인데, 테스트 DB(H2)는 그렇게 동작하지 않아
 * <b>동작 기반 테스트로는 잡히지 않는다</b> — 실제로 버그를 일부러 되돌려 놓고 돌려도
 * 전부 통과하는 것을 확인했다. 그래서 결함을 만들어내는 구조(트랜잭션 경계) 자체를
 * 직접 검사한다. 이 테스트는 버그를 되돌리면 반드시 실패한다.
 *
 * <p>배경: {@code pwd_reset_yn} 은 아직 없는 DB 가 있는 선택 컬럼이라 그 UPDATE 가
 * 실패하는 것 자체는 정상이고 무시해도 된다. 문제는 그것이 <b>같은 트랜잭션 안</b>에
 * 있을 때인데, 그러면 이미 성공한 계정 생성·비밀번호 변경까지 롤백되면서 응답은
 * 성공으로 나간다. 실제로 신규 사원 등록과 비밀번호 초기화가 이 이유로 조용히
 * 전부 실패했다(성공 메시지만 표시).
 */
class PasswordResetFlagTransactionTest {

    @Test
    void resetPasswordToDefault_는_트랜잭션_경계를_만들지_않아야_한다() throws Exception {
        Method m = AuthService.class.getDeclaredMethod("resetPasswordToDefault", String.class);
        assertThat(m.isAnnotationPresent(Transactional.class))
                .as("resetPasswordToDefault 에 @Transactional 이 붙으면 pwd_reset_yn 갱신 실패가 "
                        + "직전의 비밀번호 변경까지 롤백시킨다(관리자에겐 성공으로 보인다)")
                .isFalse();
    }

    @Test
    void markPasswordResetRequired_는_트랜잭션_경계를_만들지_않아야_한다() throws Exception {
        Method m = AuthService.class.getDeclaredMethod("markPasswordResetRequired", String.class);
        assertThat(m.isAnnotationPresent(Transactional.class)).isFalse();
    }

    @Test
    void AuthService_에_클래스_레벨_트랜잭션이_없어야_한다() {
        assertThat(AuthService.class.isAnnotationPresent(Transactional.class))
                .as("클래스 레벨 @Transactional 은 위 두 메서드에도 적용되어 같은 문제를 만든다")
                .isFalse();
    }

    /** 주석을 걷어낸 소스 — 설명 문구에 적힌 메서드명을 호출로 오인하지 않도록. */
    private static String codeWithoutComments(String path) throws Exception {
        Path src = Path.of(path);
        assertThat(Files.exists(src)).as("검사 대상 소스: " + path).isTrue();
        String s = Files.readString(src);
        s = s.replaceAll("(?s)/\\*.*?\\*/", ""); // 블록 주석 · javadoc
        s = s.replaceAll("(?m)//.*$", ""); // 줄 주석
        return s;
    }

    @Test
    void 계정생성_서비스는_강제변경_플래그를_직접_건드리지_않아야_한다() throws Exception {
        // 플래그 설정은 계정 INSERT 가 커밋된 뒤 컨트롤러가 한다. 서비스(@Transactional)
        // 안에서 부르면 그 실패가 방금 만든 계정을 통째로 되돌린다.
        String code = codeWithoutComments(
                "src/main/java/com/yeokjeon/erp/master/service/MstService.java");
        assertThat(code)
                .as("MstService 는 markPasswordResetRequired 를 호출하면 안 된다 "
                        + "(MstController 가 트랜잭션 커밋 후 호출한다)")
                .doesNotContain("markPasswordResetRequired");
    }

    @Test
    void 계정생성_컨트롤러가_커밋_이후_플래그를_세워야_한다() throws Exception {
        String code = codeWithoutComments(
                "src/main/java/com/yeokjeon/erp/master/controller/MstController.java");
        assertThat(code)
                .as("초기 비밀번호로 만든 계정은 최초 로그인 시 변경을 강제해야 하므로, "
                        + "플래그 설정이 컨트롤러에 남아 있어야 한다")
                .contains("markPasswordResetRequired");
        // MstService 에 판별 헬퍼가 남아 있어야 컨트롤러가 조건을 재현할 수 있다.
        assertThat(MstService.class.getDeclaredMethod(
                        "usesDefaultPassword",
                        com.yeokjeon.erp.master.dto.UserMstCreateRequestDto.class))
                .isNotNull();
    }
}
