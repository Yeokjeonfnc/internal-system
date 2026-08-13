package com.yeokjeon.erp.master.service;

import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.master.dto.DeptFlatRow;
import com.yeokjeon.erp.master.dto.DeptManagerRow;
import com.yeokjeon.erp.master.dto.DeptMstNodeDto;
import com.yeokjeon.erp.master.dto.DeptSortItemDto;
import com.yeokjeon.erp.master.dto.DeptSortOrderUpdateRequestDto;
import com.yeokjeon.erp.master.dto.DeptUserCountRow;
import com.yeokjeon.erp.master.dto.UserMstCreateRequestDto;
import com.yeokjeon.erp.master.dto.UserMstDto;
import com.yeokjeon.erp.master.dto.UserMstUpdateRequestDto;
import com.yeokjeon.erp.master.entity.MstUser;
import com.yeokjeon.erp.master.dto.MstUserListJdbcRow;
import com.yeokjeon.erp.master.mapper.DeptMstMapper;
import com.yeokjeon.erp.master.mapper.MstUserMapper;
import com.yeokjeon.erp.master.repository.MstUserRepository;
import com.yeokjeon.erp.auth.password.PasswordHasher;
import com.yeokjeon.erp.auth.service.AuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MstService {

    private static final String[] USER_TABLE_CANDIDATES = {
            "user_mst", "usr_mst", "employee_mst", "emp_mst", "users"
    };

    private final MstUserRepository mstUserRepository;
    private final DeptMstMapper deptMstMapper;
    private final MstUserMapper mstUserMapper;
    private final PasswordHasher passwordHasher;
    private final AuthService authService;

    public List<UserMstDto> getAll(Integer deptIdx) {
        return mstUserMapper.selectUsersEnriched(deptIdx).stream()
                .map(UserMstDto::fromJdbcRow)
                .collect(Collectors.toList());
    }

    public UserMstDto get(int userIdx) {
        MstUserListJdbcRow row = mstUserMapper.selectUserEnrichedById(userIdx);
        if (row == null) {
            throw new ResourceNotFoundException("사용자", "userIdx", userIdx);
        }
        return UserMstDto.fromJdbcRow(row);
    }

    public boolean isUserIdAvailable(String userId) {
        if (userId == null || userId.isBlank()) {
            return true;
        }
        return mstUserRepository.findByUserId(userId.trim()).isEmpty();
    }

    @Transactional
    public UserMstDto save(UserMstCreateRequestDto body) {
        Character sv = firstCharOrNull(body.svYn());
        Character owner = firstCharOrNull(body.ownerYn());

        // 비밀번호를 비워 두고 등록하면(로그인ID만 우선 부여하는 경우 등) 초기
        // 비밀번호로 계정을 만든다 — 로그인ID 는 있는데 로그인이 안 되는 "반쪽
        // 계정"이 생기지 않게 하기 위함이다. 최초 로그인 시 변경을 강제한다.
        String rawPassword = usesDefaultPassword(body)
                ? authService.defaultPassword()
                : body.userPassword();

        MstUser user = MstUser.builder()
                .userName(body.userName().trim())
                .userId(trimToNull(body.userId()))
                // 비밀번호는 절대 평문으로 저장하지 않는다.
                .userPassword(passwordHasher.hash(rawPassword))
                .deptIdx(body.deptIdx())
                .userPhone(trimToNull(body.userPhone()))
                .userEmail(trimToNull(body.userEmail()))
                .svYn(sv != null ? sv : 'N')
                .ownerYn(owner != null ? owner : 'N')
                .positionCd(trimToNull(body.positionCd()))
                .joinDt(body.joinDt())
                .build();
        normalize(user);
        MstUser saved = mstUserRepository.save(user);
        // 강제변경 플래그(pwd_reset_yn)는 **여기서 세우면 안 된다.** 이 메서드는
        // @Transactional 이라, 컬럼이 없는 DB 에서 그 UPDATE 가 실패하면 PostgreSQL 이
        // 트랜잭션을 abort 시켜 방금 INSERT 한 계정까지 사라진다(응답은 성공으로 나감).
        // 커밋 이후에 MstController 가 authService.markPasswordResetRequired 를 부른다.
        log.info("사용자 생성 완료: {}", saved.getUserIdx());
        return loadUserDtoAfterSave(saved);
    }

    /** 등록 요청이 초기 비밀번호로 계정을 만들었는지 — 컨트롤러가 커밋 후 처리를 결정할 때 쓴다. */
    public static boolean usesDefaultPassword(UserMstCreateRequestDto body) {
        return body.userPassword() == null || body.userPassword().isBlank();
    }

    @Transactional
    public UserMstDto save(int userIdx, UserMstUpdateRequestDto body) {
        MstUser user = mstUserRepository.findById(userIdx)
                .orElseThrow(() -> new ResourceNotFoundException("사용자", "userIdx", userIdx));
        if (body.isUserNamePresent()) {
            user.setUserName(trimToNull(body.getUserName()));
        }
        if (body.isUserIdPresent()) {
            user.setUserId(trimToNull(body.getUserId()));
        }
        String pw = body.getUserPassword();
        if (pw != null && !pw.isBlank()) {
            user.setUserPassword(passwordHasher.hash(pw));
        }
        if (body.isDeptIdxPresent()) {
            user.setDeptIdx(body.getDeptIdx());
        }
        if (body.isUserPhonePresent()) {
            user.setUserPhone(trimToNull(body.getUserPhone()));
        }
        if (body.isUserEmailPresent()) {
            user.setUserEmail(trimToNull(body.getUserEmail()));
        }
        if (body.isSvYnPresent()) {
            user.setSvYn(firstCharOrNull(body.getSvYn()));
        }
        if (body.isPositionCdPresent()) {
            user.setPositionCd(trimToNull(body.getPositionCd()));
        }
        if (body.isOwnerYnPresent()) {
            user.setOwnerYn(firstCharOrNull(body.getOwnerYn()));
        }
        if (body.isJoinDtPresent()) {
            user.setJoinDt(body.getJoinDt());
        }
        normalize(user);
        MstUser saved = mstUserRepository.save(user);
        log.info("사용자 수정 완료: {}", saved.getUserIdx());
        return loadUserDtoAfterSave(saved);
    }

    private UserMstDto loadUserDtoAfterSave(MstUser saved) {
        try {
            return get(saved.getUserIdx());
        } catch (RuntimeException ex) {
            log.warn("사용자 저장 후 JOIN 조회 실패 — 엔티티 기준 응답: userIdx={}", saved.getUserIdx(), ex);
            return UserMstDto.fromEntity(saved);
        }
    }

    @Transactional
    public void remove(int userIdx) {
        MstUser user = mstUserRepository.findById(userIdx)
                .orElseThrow(() -> new ResourceNotFoundException("사용자", "userIdx", userIdx));
        mstUserRepository.delete(user);
        log.info("사용자 삭제 완료: {}", userIdx);
    }

    private static String trimToNull(String s) {
        if (s == null) {
            return null;
        }
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }

    private static Character firstCharOrNull(String s) {
        if (s == null || s.isEmpty()) {
            return null;
        }
        return s.charAt(0);
    }

    private void normalize(MstUser user) {
        if (user.getSvYn() == null) {
            user.setSvYn('N');
        }
        if (user.getOwnerYn() == null) {
            user.setOwnerYn('N');
        }
    }

    // --- departments ---

    public List<DeptMstNodeDto> getDeptTree() {
        boolean hasSortOrder = hasColumn("dept_mst", "sort_order");
        Map<Integer, Integer> userCounts = loadUserCounts();
        Map<Integer, String> managerNames = loadManagerNames();

        List<DeptMstNodeDto> rows = new ArrayList<>();
        for (DeptFlatRow r : deptMstMapper.selectDeptFlat(hasSortOrder)) {
            rows.add(DeptMstNodeDto.leaf(
                    r.deptIdx(),
                    r.upperDeptIdx(),
                    r.deptNm(),
                    r.deptLevel(),
                    r.sortOrder(),
                    managerNames.get(r.deptIdx()),
                    userCounts.getOrDefault(r.deptIdx(), 0)));
        }

        Map<Integer, DeptMstNodeDto> byId = new LinkedHashMap<>();
        for (DeptMstNodeDto row : rows) {
            byId.put(row.deptIdx(), row);
        }

        List<DeptMstNodeDto> roots = new ArrayList<>();
        for (DeptMstNodeDto row : rows) {
            Integer parentId = row.upperDeptIdx();
            DeptMstNodeDto parent = parentId == null ? null : byId.get(parentId);
            if (parent == null) {
                roots.add(row);
            } else {
                parent.children().add(row);
            }
        }
        return roots;
    }

    @Transactional
    public void updateSortOrder(DeptSortOrderUpdateRequestDto body) {
        List<DeptSortItemDto> items = body.items();
        if (items == null || items.isEmpty()) {
            throw new IllegalArgumentException("정렬 대상 부서가 없습니다");
        }
        boolean hasSortOrder = hasColumn("dept_mst", "sort_order");
        for (DeptSortItemDto item : items) {
            Integer deptIdx = item.deptIdx();
            if (deptIdx == null) {
                throw new IllegalArgumentException("deptIdx은(는) 필수입니다.");
            }
            Integer upperDeptIdx = item.upperDeptIdx();
            Integer sortOrder = item.sortOrder();
            if (hasSortOrder) {
                deptMstMapper.updateDeptSortAndUpper(upperDeptIdx, sortOrder, deptIdx);
            } else {
                deptMstMapper.updateDeptUpperOnly(upperDeptIdx, deptIdx);
            }
        }
    }

    private Map<Integer, Integer> loadUserCounts() {
        Map<Integer, Integer> result = new HashMap<>();
        for (DeptUserCountRow row : deptMstMapper.selectDeptUserCounts()) {
            result.put(row.deptIdx(), row.userCount());
        }
        return result;
    }

    private Map<Integer, String> loadManagerNames() {
        String tableName = findUserTableWithColumn("dept_idx");
        if (tableName == null) return Map.of();

        String nameColumn = firstExistingColumn(tableName, "user_nm", "user_name", "emp_nm", "name");
        String managerColumn = firstExistingColumn(tableName, "manager_yn", "leader_yn", "dept_manager_yn", "responsible_yn");
        if (nameColumn == null || managerColumn == null) return Map.of();

        Map<Integer, String> result = new HashMap<>();
        for (DeptManagerRow row : deptMstMapper.selectManagerNames(tableName, nameColumn, managerColumn)) {
            result.put(row.deptIdx(), row.managerNm());
        }
        return result;
    }

    private String findUserTableWithColumn(String columnName) {
        for (String tableName : USER_TABLE_CANDIDATES) {
            if (hasColumn(tableName, columnName)) return tableName;
        }
        return null;
    }

    private String firstExistingColumn(String tableName, String... columnNames) {
        for (String columnName : columnNames) {
            if (hasColumn(tableName, columnName)) return columnName;
        }
        return null;
    }

    private boolean hasColumn(String tableName, String columnName) {
        return deptMstMapper.countInformationSchemaColumns(tableName, columnName) > 0;
    }
}
