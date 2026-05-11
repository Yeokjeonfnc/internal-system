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
        Character tag = firstCharOrNull(body.tagYn());
        MstUser user = MstUser.builder()
                .userName(body.userName().trim())
                .userId(trimToNull(body.userId()))
                .userPassword(body.userPassword())
                .deptIdx(body.deptIdx())
                .userPhone(trimToNull(body.userPhone()))
                .userEmail(trimToNull(body.userEmail()))
                .svYn(sv != null ? sv : 'N')
                .positionCd(trimToNull(body.positionCd()))
                .tagYn(tag != null ? tag : 'N')
                .joinDt(body.joinDt())
                .build();
        normalize(user);
        MstUser saved = mstUserRepository.save(user);
        log.info("사용자 생성 완료: {}", saved.getUserIdx());
        return get(saved.getUserIdx());
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
            user.setUserPassword(pw);
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
        if (body.isTagYnPresent()) {
            user.setTagYn(firstCharOrNull(body.getTagYn()));
        }
        if (body.isJoinDtPresent()) {
            user.setJoinDt(body.getJoinDt());
        }
        normalize(user);
        MstUser saved = mstUserRepository.save(user);
        log.info("사용자 수정 완료: {}", saved.getUserIdx());
        return get(saved.getUserIdx());
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
        if (user.getTagYn() == null) {
            user.setTagYn('N');
        }
        // tag_yn = 'Y' 이면 sv_yn 도 'Y' 로 맞춤(클라이언트가 svYn만 빠뜨려도 일관 저장).
        if (user.getTagYn() != null && user.getTagYn() == 'Y') {
            user.setSvYn('Y');
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
