package com.yeokjeon.erp.auth.service;

import com.yeokjeon.erp.auth.dto.LoginRequestDto;
import com.yeokjeon.erp.auth.dto.LoginResponseDto;
import com.yeokjeon.erp.auth.dto.UserProfileUpdateDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final JdbcTemplate jdbcTemplate;

    public LoginResponseDto login(LoginRequestDto dto) {
        String sql = """
                SELECT 
                    um.user_id,
                    um.user_name,
                    um.user_email,
                    um.dept_idx,
                    um.user_phone,
                    dm.dept_nm,
                    um.position_cd,
                    cm.code_nm as position_nm,
                    um.sv_yn,
                    um.tag_yn,
                    um.join_dt
                FROM user_mst um
                LEFT OUTER JOIN dept_mst dm ON um.dept_idx = dm.dept_idx
                LEFT OUTER JOIN code_mst cm ON um.position_cd = cm.code_cd AND cm.grp_cd = '60'
                WHERE um.user_id = ? AND um.user_password = ?
                """;

        try {
            return jdbcTemplate.queryForObject(sql, (rs, rowNum) -> 
                LoginResponseDto.builder()
                    .userId(rs.getString("user_id"))
                    .userNm(rs.getString("user_name"))
                    .email(rs.getString("user_email"))
                    .deptIdx(rs.getObject("dept_idx", Integer.class))
                    .userPhone(rs.getString("user_phone"))
                    .deptNm(rs.getString("dept_nm"))
                    .positionCd(rs.getString("position_cd"))
                    .positionNm(rs.getString("position_nm"))
                    .svYn(rs.getString("sv_yn") != null ? rs.getString("sv_yn").charAt(0) : null)
                    .tagYn(rs.getString("tag_yn") != null ? rs.getString("tag_yn").charAt(0) : null)
                    .joinDt(rs.getObject("join_dt", java.time.LocalDate.class))
                    .build(),
                dto.getUserId(), 
                dto.getUserPassword()
            );
        } catch (Exception e) {
            log.error("로그인 실패: userId={}, error={}", dto.getUserId(), e.getMessage());
            return null;
        }
    }

    @Transactional
    public LoginResponseDto updateUserProfile(String userId, UserProfileUpdateDto dto) {
        StringBuilder sql = new StringBuilder("UPDATE user_mst SET updated_at = CURRENT_TIMESTAMP");
        java.util.List<Object> params = new java.util.ArrayList<>();

        if (dto.getUserName() != null && !dto.getUserName().isBlank()) {
            sql.append(", user_name = ?");
            params.add(dto.getUserName());
        }
        if (dto.getUserPassword() != null && !dto.getUserPassword().isBlank()) {
            sql.append(", user_password = ?");
            params.add(dto.getUserPassword());
        }
        if (dto.getDeptIdx() != null) {
            sql.append(", dept_idx = ?");
            params.add(dto.getDeptIdx());
        }
        if (dto.getUserPhone() != null) {
            sql.append(", user_phone = ?");
            params.add(dto.getUserPhone().trim().isEmpty() ? null : dto.getUserPhone());
        }
        if (dto.getSvYn() != null) {
            sql.append(", sv_yn = ?");
            params.add(dto.getSvYn());
        }
        if (dto.getPositionCd() != null) {
            sql.append(", position_cd = ?");
            params.add(dto.getPositionCd().trim().isEmpty() ? null : dto.getPositionCd());
        }
        if (dto.getTagYn() != null) {
            sql.append(", tag_yn = ?");
            params.add(dto.getTagYn());
        }

        sql.append(" WHERE user_id = ?");
        params.add(userId);

        int updated = jdbcTemplate.update(sql.toString(), params.toArray());
        
        if (updated > 0) {
            log.info("사용자 정보 수정 완료: userId={}", userId);
            return getUserProfile(userId);
        }
        
        log.error("사용자 정보 수정 실패: userId={}", userId);
        return null;
    }

    public LoginResponseDto getUserProfile(String userId) {
        String sql = """
                SELECT 
                    um.user_id,
                    um.user_name,
                    um.user_email,
                    um.dept_idx,
                    um.user_phone,
                    dm.dept_nm,
                    um.position_cd,
                    cm.code_nm as position_nm,
                    um.sv_yn,
                    um.tag_yn,
                    um.join_dt
                FROM user_mst um
                LEFT OUTER JOIN dept_mst dm ON um.dept_idx = dm.dept_idx
                LEFT OUTER JOIN code_mst cm ON um.position_cd = cm.code_cd AND cm.grp_cd = '60'
                WHERE um.user_id = ?
                """;

        try {
            return jdbcTemplate.queryForObject(sql, (rs, rowNum) -> 
                LoginResponseDto.builder()
                    .userId(rs.getString("user_id"))
                    .userNm(rs.getString("user_name"))
                    .email(rs.getString("user_email"))
                    .deptIdx(rs.getObject("dept_idx", Integer.class))
                    .userPhone(rs.getString("user_phone"))
                    .deptNm(rs.getString("dept_nm"))
                    .positionCd(rs.getString("position_cd"))
                    .positionNm(rs.getString("position_nm"))
                    .svYn(rs.getString("sv_yn") != null ? rs.getString("sv_yn").charAt(0) : null)
                    .tagYn(rs.getString("tag_yn") != null ? rs.getString("tag_yn").charAt(0) : null)
                    .joinDt(rs.getObject("join_dt", java.time.LocalDate.class))
                    .build(),
                userId
            );
        } catch (Exception e) {
            log.error("사용자 정보 조회 실패: userId={}, error={}", userId, e.getMessage());
            return null;
        }
    }
}
