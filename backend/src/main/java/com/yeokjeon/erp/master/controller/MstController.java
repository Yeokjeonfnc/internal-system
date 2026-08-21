package com.yeokjeon.erp.master.controller;

import com.yeokjeon.erp.auth.access.MenuAccessGuard;
import com.yeokjeon.erp.auth.access.MenuCodes;
import com.yeokjeon.erp.auth.service.AuthService;
import com.yeokjeon.erp.auth.token.AuthTokenFilter;
import com.yeokjeon.erp.auth.token.TokenInvalidationRegistry;
import com.yeokjeon.erp.common.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import com.yeokjeon.erp.master.dto.DeptMstNodeDto;
import com.yeokjeon.erp.master.dto.DeptSortOrderUpdateRequestDto;
import com.yeokjeon.erp.master.dto.EmpNoDto;
import com.yeokjeon.erp.master.dto.UserIdAvailabilityDto;
import com.yeokjeon.erp.master.dto.UserMstCreateRequestDto;
import com.yeokjeon.erp.master.dto.UserMstDto;
import com.yeokjeon.erp.master.dto.UserMstUpdateRequestDto;
import com.yeokjeon.erp.master.dto.UserResignRequestDto;
import com.yeokjeon.erp.master.mapper.EmpNoMapper;
import com.yeokjeon.erp.master.service.MstService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/** 사원·부서 — `/users`, `/dept` 유지. */
@Slf4j
@RestController
@RequiredArgsConstructor
public class MstController {

    private final MstService mstService;
    private final MenuAccessGuard menuAccessGuard;
    private final TokenInvalidationRegistry tokenInvalidationRegistry;
    private final AuthService authService;
    private final EmpNoMapper empNoMapper;

    /** 토큰에서 확인된 호출자 — 요청 파라미터가 아니므로 사칭할 수 없다. */
    private static String callerId(HttpServletRequest request) {
        Object v = request.getAttribute(AuthTokenFilter.ATTR_CURRENT_USER_ID);
        return v == null ? null : v.toString();
    }

    /**
     * 로그인ID 중복 확인 — 사원·가맹점주 신규 등록 화면에서 쓴다.
     *
     * <p><b>파라미터 이름이 {@code userId} 이면 안 된다.</b> {@code AuthTokenFilter} 는
     * {@code userId} 라는 이름의 요청 파라미터를 "호출자가 주장하는 신분"으로 보고
     * 토큰 주인과 다르면 403 을 던진다. 그런데 여기서 넘어오는 값은 정의상
     * "아직 존재하지 않는 새 ID" 라 절대 호출자 본인일 수 없다 — 실제로 이 이름
     * 충돌 때문에 신규 계정 생성이 운영에서 전면 불가였다. 이름을 분리해 둔다.
     */
    @GetMapping("/users/check-user-id")
    public ResponseEntity<ApiResponse<UserIdAvailabilityDto>> checkUserId(
            @RequestParam("candidateUserId") String candidateUserId) {
        boolean available = mstService.isUserIdAvailable(candidateUserId);
        return ResponseEntity.ok(ApiResponse.success(new UserIdAvailabilityDto(available)));
    }

    @GetMapping("/users")
    public ResponseEntity<ApiResponse<List<UserMstDto>>> userList(
            @RequestParam(required = false) Integer deptIdx) {
        List<UserMstDto> users = mstService.getAll(deptIdx);
        return ResponseEntity.ok(ApiResponse.success(users));
    }

    @GetMapping("/users/resigned")
    public ResponseEntity<ApiResponse<List<UserMstDto>>> resignedUserList(HttpServletRequest request) {
        menuAccessGuard.ensureSuperAdmin(callerId(request));
        return ResponseEntity.ok(ApiResponse.success(mstService.getResigned()));
    }

    @GetMapping("/users/{userIdx}")
    public ResponseEntity<ApiResponse<UserMstDto>> userOne(@PathVariable Integer userIdx) {
        UserMstDto user = mstService.get(userIdx);
        return ResponseEntity.ok(ApiResponse.success(user));
    }

    /*
     * 아래 3개는 계정 자체를 만들고 바꾸고 지우는 작업이다. 권한 검사가 없으면
     * 로그인한 아무 직원이나 남의 비밀번호를 재설정하거나, 자기 로그인ID 를
     * 'admin' 으로 바꿔 슈퍼관리자가 될 수 있다. 사원관리(mst001) 권한을 요구한다.
     */

    @PostMapping("/users")
    public ResponseEntity<ApiResponse<UserMstDto>> userCreate(
            @Valid @RequestBody UserMstCreateRequestDto body, HttpServletRequest request) {
        menuAccessGuard.ensure(callerId(request), MenuCodes.MST001, MenuAccessGuard.Action.CREATE);
        UserMstDto created = mstService.save(body);

        // 계정 생성 트랜잭션이 커밋된 **뒤에** 강제변경 플래그를 세운다.
        // 생성 트랜잭션 안에서 세우면, pwd_reset_yn 컬럼이 없는 DB 에서 그 UPDATE 가
        // 트랜잭션을 오염시켜 방금 만든 계정이 통째로 롤백되면서도 응답은 성공으로
        // 나갔다(신규 사원 등록이 조용히 전부 실패). 여기로 옮겨 그 고리를 끊는다.
        if (MstService.usesDefaultPassword(body)
                && created != null
                && created.userId() != null
                && !created.userId().isBlank()) {
            authService.markPasswordResetRequired(created.userId());
        }
        return ResponseEntity.ok(ApiResponse.success("사용자가 생성되었습니다.", created));
    }

    @PutMapping("/users/{userIdx}")
    public ResponseEntity<ApiResponse<UserMstDto>> userUpdate(
            @PathVariable Integer userIdx,
            @RequestBody UserMstUpdateRequestDto body,
            HttpServletRequest request) {
        menuAccessGuard.ensure(callerId(request), MenuCodes.MST001, MenuAccessGuard.Action.UPDATE);
        UserMstDto updated = mstService.save(userIdx, body);
        // 관리자가 비밀번호를 재설정했다면 그 계정으로 이미 발급된 토큰도 끊는다.
        // (끊지 않으면 잠긴 계정을 쓰던 쪽이 만료까지 그대로 접속 가능하다.)
        boolean passwordReset =
                body.getUserPassword() != null && !body.getUserPassword().isBlank();
        if (passwordReset && updated != null) {
            tokenInvalidationRegistry.invalidateAll(updated.userId());
        }
        return ResponseEntity.ok(ApiResponse.success("사용자가 수정되었습니다.", updated));
    }

    @DeleteMapping("/users/{userIdx}")
    public ResponseEntity<ApiResponse<Void>> userDelete(
            @PathVariable Integer userIdx, HttpServletRequest request) {
        menuAccessGuard.ensureSuperAdmin(callerId(request));
        // 삭제 전에 로그인 ID 를 확보해 둔다 — 지운 뒤에는 조회할 수 없다.
        UserMstDto target = mstService.get(userIdx);
        mstService.remove(userIdx);
        if (target != null) {
            tokenInvalidationRegistry.invalidateAll(target.userId());
        }
        return ResponseEntity.ok(ApiResponse.success("사용자가 삭제되었습니다.", null));
    }

    /**
     * 퇴사 처리 — 관리자(admin_yn) 전용. 계정 행은 유지하고 재직 플래그만 내린다.
     * 발급된 토큰도 전부 끊는다.
     */
    @PostMapping("/users/{userIdx}/resign")
    public ResponseEntity<ApiResponse<UserMstDto>> userResign(
            @PathVariable Integer userIdx,
            @RequestBody(required = false) UserResignRequestDto body,
            HttpServletRequest request) {
        menuAccessGuard.ensureSuperAdmin(callerId(request));
        LocalDate leaveDt = body != null ? body.leaveDt() : null;
        UserMstDto updated = mstService.resign(userIdx, leaveDt);
        if (updated != null && updated.userId() != null && !updated.userId().isBlank()) {
            tokenInvalidationRegistry.invalidateAll(updated.userId());
        }
        return ResponseEntity.ok(ApiResponse.success("퇴사 처리되었습니다.", updated));
    }

    /**
     * 비밀번호 초기화 — 사원관리 목록의 "비밀번호 초기화" 버튼에서 호출한다.
     * 초기 비밀번호로 되돌리고, 다음 로그인 때 반드시 바꾸도록 표시하며,
     * 이미 발급된 토큰을 전부 끊는다(초기화 이유가 대개 "계정이 걱정돼서"이므로).
     */
    @PostMapping("/users/{userIdx}/reset-password")
    public ResponseEntity<ApiResponse<Void>> resetPassword(
            @PathVariable Integer userIdx, HttpServletRequest request) {
        menuAccessGuard.ensure(callerId(request), MenuCodes.MST001, MenuAccessGuard.Action.UPDATE);
        UserMstDto target = mstService.get(userIdx);
        String userId = target.userId();
        if (userId == null || userId.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("로그인ID가 없어 비밀번호를 초기화할 수 없습니다."));
        }
        authService.resetPasswordToDefault(userId);
        tokenInvalidationRegistry.invalidateAll(userId);
        return ResponseEntity.ok(ApiResponse.success("초기 비밀번호로 재설정되었습니다.", null));
    }

    /*
     * 사번(emp_no) — 일괄 업로드·로그인 매칭에 쓰는 내부 토큰번호(userIdx)와는
     * 별개의, 회사가 실제로 관리하는 사원번호다. 선택 컬럼이라 미적용 DB 에서는
     * 예외가 나므로, 사원 목록/조회의 핵심 경로(MstService)와 완전히 분리해
     * 여기서만 다루고 실패해도 그 사실만 알려준다.
     */

    @GetMapping("/users/{userIdx}/emp-no")
    public ResponseEntity<ApiResponse<EmpNoDto>> getEmpNo(@PathVariable int userIdx) {
        try {
            return ResponseEntity.ok(ApiResponse.success(new EmpNoDto(empNoMapper.selectEmpNo(userIdx))));
        } catch (Exception e) {
            log.warn("사번 조회 생략(컬럼 미적용 가능): userIdx={}, {}", userIdx, e.getMessage());
            return ResponseEntity.ok(ApiResponse.success(new EmpNoDto(null)));
        }
    }

    @PutMapping("/users/{userIdx}/emp-no")
    public ResponseEntity<ApiResponse<Void>> updateEmpNo(
            @PathVariable int userIdx, @RequestBody EmpNoDto body, HttpServletRequest request) {
        menuAccessGuard.ensure(callerId(request), MenuCodes.MST001, MenuAccessGuard.Action.UPDATE);
        try {
            empNoMapper.upsertEmpNo(userIdx, body.empNo());
        } catch (Exception e) {
            log.warn("사번 저장 실패(컬럼 미적용 가능): userIdx={}, {}", userIdx, e.getMessage());
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(ApiResponse.error("사번 항목이 아직 이 서버에 준비되지 않았습니다."));
        }
        return ResponseEntity.ok(ApiResponse.success("사번이 저장되었습니다.", null));
    }

    @GetMapping("/dept/list")
    public ResponseEntity<ApiResponse<List<DeptMstNodeDto>>> deptList() {
        log.info("부서 트리 목록 조회 요청");
        return ResponseEntity.ok(ApiResponse.success(mstService.getDeptTree()));
    }

    @PutMapping("/dept/sort-order")
    public ResponseEntity<ApiResponse<Void>> deptSortOrder(
            @Valid @RequestBody DeptSortOrderUpdateRequestDto body) {
        log.info("부서 정렬 순서 변경 요청: {}건", body.items() != null ? body.items().size() : 0);
        mstService.updateSortOrder(body);
        return ResponseEntity.ok(ApiResponse.success("부서 순서가 변경되었습니다", null));
    }
}
