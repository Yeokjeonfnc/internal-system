package com.yeokjeon.erp.master.controller;

import com.yeokjeon.erp.auth.access.AccessDeniedException;
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
import com.yeokjeon.erp.master.mapper.EmpNoMapper;
import com.yeokjeon.erp.master.service.MenuPermissionService;
import com.yeokjeon.erp.master.service.MstService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** 사원·부서 — `/users`, `/dept` 유지. */
@Slf4j
@RestController
@RequiredArgsConstructor
public class MstController {

    private final MstService mstService;
    private final MenuAccessGuard menuAccessGuard;
    private final MenuPermissionService menuPermissionService;
    private final TokenInvalidationRegistry tokenInvalidationRegistry;
    private final AuthService authService;
    private final EmpNoMapper empNoMapper;

    /** 토큰에서 확인된 호출자 — 요청 파라미터가 아니므로 사칭할 수 없다. */
    private static String callerId(HttpServletRequest request) {
        Object v = request.getAttribute(AuthTokenFilter.ATTR_CURRENT_USER_ID);
        return v == null ? null : v.toString();
    }

    /**
     * 호출자가 사원관리(mst001) 조회 권한을 가졌는지 — 없다고 예외를 던지지는 않는다.
     *
     * <p>{@code GET /users} 는 사원관리 화면 전용이 아니다. 결재선 지정(act002)·부서관리
     * (mst002)·메뉴권한(mst003)이 모두 이 API 를 "사원 디렉터리"로 쓰기 때문에 여기서
     * 권한을 요구하면 일반 직원이 결재를 올리지 못한다. 그래서 접근 자체는 막지 않고
     * 연락처 같은 개인정보만 가린다 — 그 판정에 쓰는 검사다.
     */
    private boolean canReadUserContactInfo(HttpServletRequest request) {
        try {
            menuAccessGuard.ensure(
                    callerId(request), MenuCodes.MST001, MenuAccessGuard.Action.VIEW);
            return true;
        } catch (AccessDeniedException denied) {
            return false;
        }
    }

    /**
     * 가맹점주 계정은 사원 명부 자체를 못 보게 한다.
     *
     * <p>메뉴 권한 검사만으로는 걸러지지 않는다 — 기준선 스크립트가 사이드바를 그대로
     * 유지하려고 전 계정·전 메뉴에 {@code can_view='Y'} 를 넣어 뒀기 때문이다. 가맹점주
     * 에게 열려 있는 화면은 게시판뿐이고 사원 목록을 쓰는 화면은 하나도 없으므로,
     * 여기서만 신분으로 끊는다.
     */
    private void ensureNotFranchiseOwner(String caller) {
        if (mstService.isFranchiseOwner(caller)) {
            throw new AccessDeniedException("사원 정보를 조회할 권한이 없습니다.");
        }
    }

    /**
     * 슈퍼관리자 계정은 슈퍼관리자만 건드릴 수 있게 한다.
     *
     * <p>초기 비밀번호는 설정 하나로 고정된 공개값이라, 사원관리 수정 권한만 받은
     * 직원이 admin 계정을 초기화한 뒤 그 값으로 로그인하면 전권을 가져갈 수 있었다.
     * 비밀번호를 직접 실어 보내는 {@code PUT /users/{userIdx}} 도 같은 경로라
     * 대상·신규 로그인ID 양쪽에 이 검사를 건다(로그인ID 를 슈퍼관리자 ID 로 바꿔
     * 올라서는 우회도 함께 막는다).
     */
    private void ensureNotSuperAdminTarget(String caller, String targetUserId) {
        if (targetUserId == null || targetUserId.isBlank()) {
            return;
        }
        if (!menuPermissionService.isSuperAdmin(targetUserId)) {
            return;
        }
        if (menuPermissionService.isSuperAdmin(caller)) {
            return;
        }
        throw new AccessDeniedException("관리자 계정은 관리자만 변경할 수 있습니다.");
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

    /**
     * 사원 목록.
     *
     * <p>사원관리(mst001) 조회 권한이 없는 호출자에게는 휴대전화·이메일·입사일을 지운
     * 사본을 내려보낸다. 쓰기만 잠그고 읽기를 열어 뒀던 탓에, 사원관리 메뉴가 보이지도
     * 않는 일반 직원·가맹점주가 API 를 직접 불러 전 직원 연락처를 통째로 긁어갈 수
     * 있었다. 결재선 지정 등 다른 화면이 이름·부서·직급만으로 동작하므로 그 값만 남긴다.
     * 본인 행은 자기 정보이므로 가리지 않는다.
     */
    @GetMapping("/users")
    public ResponseEntity<ApiResponse<List<UserMstDto>>> userList(
            @RequestParam(required = false) Integer deptIdx, HttpServletRequest request) {
        String caller = callerId(request);
        ensureNotFranchiseOwner(caller);
        List<UserMstDto> users = mstService.getAll(deptIdx);
        if (!canReadUserContactInfo(request)) {
            users = MstService.hideContactInfoExceptSelf(users, caller);
        }
        return ResponseEntity.ok(ApiResponse.success(users));
    }

    /**
     * 사원 한 명 상세 — 사원관리 화면 전용이라 목록과 달리 아예 막는다.
     * 본인 조회는 허용한다(내 정보 확인은 권한과 무관하다).
     */
    @GetMapping("/users/{userIdx}")
    public ResponseEntity<ApiResponse<UserMstDto>> userOne(
            @PathVariable Integer userIdx, HttpServletRequest request) {
        String caller = callerId(request);
        try {
            menuAccessGuard.ensureSelfUserIdx(caller, userIdx);
        } catch (AccessDeniedException notSelf) {
            ensureNotFranchiseOwner(caller);
            menuAccessGuard.ensure(caller, MenuCodes.MST001, MenuAccessGuard.Action.VIEW);
        }
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
        String caller = callerId(request);
        menuAccessGuard.ensure(caller, MenuCodes.MST001, MenuAccessGuard.Action.CREATE);
        // 설정에만 있고 계정은 아직 없는 슈퍼관리자 ID 로 새 계정을 만들어 올라서는 것도 막는다.
        ensureNotSuperAdminTarget(caller, body.userId());
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
        String caller = callerId(request);
        menuAccessGuard.ensure(caller, MenuCodes.MST001, MenuAccessGuard.Action.UPDATE);
        ensureNotSuperAdminTarget(caller, mstService.get(userIdx).userId());
        if (body.isUserIdPresent()) {
            ensureNotSuperAdminTarget(caller, body.getUserId());
        }
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
        String caller = callerId(request);
        menuAccessGuard.ensure(caller, MenuCodes.MST001, MenuAccessGuard.Action.DELETE);
        // 삭제 전에 로그인 ID 를 확보해 둔다 — 지운 뒤에는 조회할 수 없다.
        UserMstDto target = mstService.get(userIdx);
        ensureNotSuperAdminTarget(caller, target.userId());
        mstService.remove(userIdx);
        if (target != null) {
            tokenInvalidationRegistry.invalidateAll(target.userId());
        }
        return ResponseEntity.ok(ApiResponse.success("사용자가 삭제되었습니다.", null));
    }

    /**
     * 비밀번호 초기화 — 사원관리 목록의 "비밀번호 초기화" 버튼에서 호출한다.
     * 초기 비밀번호로 되돌리고, 다음 로그인 때 반드시 바꾸도록 표시하며,
     * 이미 발급된 토큰을 전부 끊는다(초기화 이유가 대개 "계정이 걱정돼서"이므로).
     */
    @PostMapping("/users/{userIdx}/reset-password")
    public ResponseEntity<ApiResponse<Void>> resetPassword(
            @PathVariable Integer userIdx, HttpServletRequest request) {
        String caller = callerId(request);
        menuAccessGuard.ensure(caller, MenuCodes.MST001, MenuAccessGuard.Action.UPDATE);
        UserMstDto target = mstService.get(userIdx);
        ensureNotSuperAdminTarget(caller, target.userId());
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
