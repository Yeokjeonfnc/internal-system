package com.yeokjeon.erp.master.service;

import com.yeokjeon.erp.auth.mapper.AuthProfileMapper;
import com.yeokjeon.erp.auth.password.PasswordHasher;
import com.yeokjeon.erp.auth.service.AuthService;
import com.yeokjeon.erp.master.dto.UserMstCreateRequestDto;
import com.yeokjeon.erp.master.dto.UserMstDto;
import com.yeokjeon.erp.master.entity.MstUser;
import com.yeokjeon.erp.master.mapper.EmpNoMapper;
import com.yeokjeon.erp.master.repository.MstUserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 초기 비밀번호 자동 설정 + 관리자의 "비밀번호 초기화" 회귀 테스트.
 *
 * <p>테스트 DB(H2, {@code ddl-auto: create-drop})는 JPA {@code @Entity} 로만
 * 스키마를 만든다. {@code pwd_reset_yn} 은 의도적으로 엔티티에 없으므로,
 * 이 테스트 환경 자체가 "컬럼 미적용 운영 DB" 상황을 그대로 재현한다 — 즉
 * 여기서 통과하면 실제 운영 DB(마이그레이션 전)에서도 비밀번호 관련 기능
 * 자체는 깨지지 않는다는 뜻이다.
 */
@SpringBootTest
@ActiveProfiles("test")
class MstServiceDefaultPasswordTest {

    @Autowired private MstService mstService;
    @Autowired private AuthService authService;
    @Autowired private AuthProfileMapper authProfileMapper;
    @Autowired private PasswordHasher passwordHasher;
    @Autowired private MstUserRepository mstUserRepository;
    @Autowired private EmpNoMapper empNoMapper;

    @Test
    void 비밀번호를_비워서_등록하면_초기비밀번호로_생성된다() {
        UserMstCreateRequestDto body = new UserMstCreateRequestDto(
                "테스트사원", "", "test.user.001", null, null, null, "N", null, "N",
                LocalDate.now());

        UserMstDto created = mstService.save(body);
        try {
            String stored = authProfileMapper.selectPasswordHash("test.user.001");
            assertThat(passwordHasher.matches(authService.defaultPassword(), stored)).isTrue();
        } finally {
            mstUserRepository.deleteById(created.userIdx());
        }
    }

    @Test
    void 비밀번호를_직접_입력하면_그값이_그대로_쓰인다() {
        UserMstCreateRequestDto body = new UserMstCreateRequestDto(
                "테스트사원2", "myOwnPw1234", "test.user.002", null, null, null, "N", null,
                "N", LocalDate.now());

        UserMstDto created = mstService.save(body);
        try {
            String stored = authProfileMapper.selectPasswordHash("test.user.002");
            assertThat(passwordHasher.matches("myOwnPw1234", stored)).isTrue();
            assertThat(passwordHasher.matches(authService.defaultPassword(), stored)).isFalse();
        } finally {
            mstUserRepository.deleteById(created.userIdx());
        }
    }

    @Test
    void 관리자가_비밀번호를_초기화하면_초기비밀번호로_바뀐다() {
        MstUser user = MstUser.builder()
                .userName("초기화대상")
                .userId("test.user.003")
                .userPassword(passwordHasher.hash("oldPassword1"))
                .svYn('N')
                .ownerYn('N')
                .build();
        MstUser saved = mstUserRepository.save(user);

        try {
            // H2 테스트 DB 에는 pwd_reset_yn 컬럼이 없다 — 그래도 비밀번호
            // 자체는 예외 없이 바뀌어야 한다(강제변경 플래그는 조용히 건너뜀).
            authService.resetPasswordToDefault("test.user.003");
            String stored = authProfileMapper.selectPasswordHash("test.user.003");
            assertThat(passwordHasher.matches(authService.defaultPassword(), stored)).isTrue();
            assertThat(passwordHasher.matches("oldPassword1", stored)).isFalse();
        } finally {
            mstUserRepository.deleteById(saved.getUserIdx());
        }
    }

    /**
     * 회귀 방지 — 트랜잭션 오염.
     *
     * <p>pwd_reset_yn 컬럼이 없는 DB(=이 테스트 환경, =현재 실 운영 DB)에서
     * 계정 생성이 실제로 **커밋되어 남아 있는지** 확인한다. 예전에는 생성
     * 트랜잭션 안에서 그 컬럼을 UPDATE 하다 실패해 트랜잭션이 abort 되었고,
     * 방금 만든 계정이 통째로 사라지면서도 응답은 200 이었다.
     */
    @Test
    void 초기비밀번호로_만든_계정이_커밋되어_실제로_조회된다() {
        UserMstCreateRequestDto body = new UserMstCreateRequestDto(
                "롤백검증", "", "test.user.004", null, null, null, "N", null, "N",
                LocalDate.now());

        UserMstDto created = mstService.save(body);
        // 컨트롤러가 커밋 후 하는 일을 그대로 재현한다(여기서 터져도 위는 살아야 한다).
        authService.markPasswordResetRequired("test.user.004");
        try {
            assertThat(mstUserRepository.findById(created.userIdx())).isPresent();
            assertThat(mstUserRepository.findByUserId("test.user.004")).isPresent();
            String stored = authProfileMapper.selectPasswordHash("test.user.004");
            assertThat(stored).isNotNull();
            assertThat(passwordHasher.matches(authService.defaultPassword(), stored)).isTrue();
        } finally {
            mstUserRepository.deleteById(created.userIdx());
        }
    }

    /** 회귀 방지 — 비밀번호 초기화가 플래그 실패에 휩쓸려 롤백되면 안 된다. */
    @Test
    void 비밀번호_초기화가_플래그_실패에도_실제로_반영된다() {
        MstUser user = MstUser.builder()
                .userName("초기화검증")
                .userId("test.user.005")
                .userPassword(passwordHasher.hash("beforeReset1"))
                .svYn('N')
                .ownerYn('N')
                .build();
        MstUser saved = mstUserRepository.save(user);
        try {
            authService.resetPasswordToDefault("test.user.005");
            // 같은 트랜잭션에 묶여 있었다면 여기서 옛 비밀번호가 그대로 남는다.
            String stored = authProfileMapper.selectPasswordHash("test.user.005");
            assertThat(passwordHasher.matches(authService.defaultPassword(), stored)).isTrue();
            assertThat(passwordHasher.matches("beforeReset1", stored)).isFalse();
        } finally {
            mstUserRepository.deleteById(saved.getUserIdx());
        }
    }

    @Test
    void 사번_컬럼이_없는_DB_에서는_조회가_예외를_던진다() {
        // MstController.getEmpNo/updateEmpNo 가 이 예외를 try/catch 로 감싸고
        // 있다는 전제를 검증한다 — 여기서 예외가 안 나면 그 방어 코드가 실제로는
        // 아무 것도 막아주지 못하고 있다는 뜻이므로 오히려 테스트가 실패해야 한다.
        org.junit.jupiter.api.Assertions.assertThrows(
                Exception.class, () -> empNoMapper.selectEmpNo(999_999));
    }
}
