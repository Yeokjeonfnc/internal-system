
package com.yeokjeon.erp.user.service;

import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.user.dto.UserRequestDto;
import com.yeokjeon.erp.user.dto.UserResponseDto;
import com.yeokjeon.erp.user.entity.User;
import com.yeokjeon.erp.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final JdbcTemplate jdbcTemplate;

    public List<UserResponseDto> getAllUsers() {
        List<User> users = userRepository.findAllUsersOrderByIdxDesc();
        Map<Integer, String> deptNames = loadDepartmentNames(users);
        Map<String, String> positionNames = loadPositionNames(users);

        return users.stream()
                .map(user -> toDto(user, deptNames, positionNames))
                .collect(Collectors.toList());
    }

    public List<UserResponseDto> getUsersByDept(Integer deptIdx) {
        List<User> users = userRepository.findAllUsersOrderByIdxDesc().stream()
                .filter(user -> deptIdx.equals(user.getDeptIdx()))
                .collect(Collectors.toList());
        
        Map<Integer, String> deptNames = loadDepartmentNames(users);
        Map<String, String> positionNames = loadPositionNames(users);

        return users.stream()
                .map(user -> toDto(user, deptNames, positionNames))
                .collect(Collectors.toList());
    }

    public UserResponseDto getUser(Integer userIdx) {
        User user = userRepository.findById(userIdx)
                .orElseThrow(() -> new ResourceNotFoundException("사용자", "userIdx", userIdx));

        Map<Integer, String> deptNames = new HashMap<>();
        Map<String, String> positionNames = new HashMap<>();

        if (user.getDeptIdx() != null) {
            deptNames.put(user.getDeptIdx(), loadDepartmentName(user.getDeptIdx()));
        }
        if (user.getPositionCd() != null) {
            positionNames.put(user.getPositionCd(), loadPositionName(user.getPositionCd()));
        }

        return toDto(user, deptNames, positionNames);
    }

    @Transactional
    public UserResponseDto createUser(UserRequestDto dto) {
        User user = dto.toEntity();
        normalizeForSave(user);
        User saved = userRepository.save(user);
        log.info("사용자 생성 완료: {}", saved.getUserIdx());
        return getUser(saved.getUserIdx());
    }

    @Transactional
    public UserResponseDto updateUser(Integer userIdx, UserRequestDto dto) {
        User user = userRepository.findById(userIdx)
                .orElseThrow(() -> new ResourceNotFoundException("사용자", "userIdx", userIdx));

        user.setUserName(dto.getUserName());
        user.setUserId(dto.getUserId());
        if (dto.getUserPassword() != null && !dto.getUserPassword().isBlank()) {
            user.setUserPassword(dto.getUserPassword());
        }
        user.setDeptIdx(dto.getDeptIdx());
        user.setUserPhone(dto.getUserPhone());
        user.setUserEmail(dto.getUserEmail());
        user.setSvYn(dto.getSvYn());
        user.setPositionCd(dto.getPositionCd());
        user.setTagYn(dto.getTagYn());
        normalizeForSave(user);

        User saved = userRepository.save(user);
        log.info("사용자 수정 완료: {}", saved.getUserIdx());
        return getUser(saved.getUserIdx());
    }

    @Transactional
    public void deleteUser(Integer userIdx) {
        User user = userRepository.findById(userIdx)
                .orElseThrow(() -> new ResourceNotFoundException("사용자", "userIdx", userIdx));
        userRepository.delete(user);
        log.info("사용자 삭제 완료: {}", userIdx);
    }

    private void normalizeForSave(User user) {
        if (user.getSvYn() == null) {
            user.setSvYn('N');
        }
        if (user.getTagYn() == null) {
            user.setTagYn('N');
        }
    }

    private Map<Integer, String> loadDepartmentNames(List<User> users) {
        List<Integer> deptIds = users.stream()
                .map(User::getDeptIdx)
                .filter(id -> id != null)
                .distinct()
                .collect(Collectors.toList());

        if (deptIds.isEmpty()) {
            return new HashMap<>();
        }

        Map<Integer, String> result = new HashMap<>();
        String placeholders = deptIds.stream()
                .map(id -> "?")
                .collect(Collectors.joining(","));
        String sql = "SELECT dept_idx, dept_nm FROM dept_mst WHERE dept_idx IN (" + placeholders + ")";
        try {
            jdbcTemplate.query(sql, rs -> {
                result.put(rs.getInt("dept_idx"), rs.getString("dept_nm"));
            }, deptIds.toArray());
        } catch (Exception e) {
            log.warn("부서명 조회 실패", e);
        }
        return result;
    }

    private String loadDepartmentName(Integer deptIdx) {
        if (deptIdx == null) return null;
        try {
            return jdbcTemplate.queryForObject(
                    "SELECT dept_nm FROM dept_mst WHERE dept_idx = ?",
                    String.class,
                    deptIdx
            );
        } catch (Exception e) {
            log.warn("부서명 조회 실패: {}", deptIdx, e);
            return null;
        }
    }

    private Map<String, String> loadPositionNames(List<User> users) {
        List<String> positionCds = users.stream()
                .map(User::getPositionCd)
                .filter(cd -> cd != null && !cd.isBlank())
                .distinct()
                .collect(Collectors.toList());

        if (positionCds.isEmpty()) {
            return new HashMap<>();
        }

        Map<String, String> result = new HashMap<>();
        String placeholders = positionCds.stream()
                .map(cd -> "?")
                .collect(Collectors.joining(","));
        String sql = "SELECT code_cd, code_nm FROM code_mst WHERE grp_cd = 60 AND code_cd IN (" + placeholders + ")";
        try {
            jdbcTemplate.query(sql, rs -> {
                result.put(rs.getString("code_cd"), rs.getString("code_nm"));
            }, positionCds.toArray());
        } catch (Exception e) {
            log.warn("직급명 조회 실패", e);
        }
        return result;
    }

    private String loadPositionName(String positionCd) {
        if (positionCd == null || positionCd.isBlank()) return null;
        try {
            return jdbcTemplate.queryForObject(
                    "SELECT code_nm FROM code_mst WHERE grp_cd = 60 AND code_cd = ?",
                    String.class,
                    positionCd
            );
        } catch (Exception e) {
            log.warn("직급명 조회 실패: {}", positionCd, e);
            return null;
        }
    }

    private UserResponseDto toDto(User user, Map<Integer, String> deptNames, Map<String, String> positionNames) {
        return UserResponseDto.builder()
                .userIdx(user.getUserIdx())
                .userName(user.getUserName())
                .userId(user.getUserId())
                .deptIdx(user.getDeptIdx())
                .deptNm(user.getDeptIdx() != null ? deptNames.get(user.getDeptIdx()) : null)
                .userPhone(user.getUserPhone())
                .userEmail(user.getUserEmail())
                .svYn(user.getSvYn())
                .positionCd(user.getPositionCd())
                .positionNm(user.getPositionCd() != null ? positionNames.get(user.getPositionCd()) : null)
                .tagYn(user.getTagYn())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }
}
