package com.yeokjeon.erp.auth.service;

import com.yeokjeon.erp.common.RequestMapUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final JdbcTemplate jdbcTemplate;

    public Map<String, Object> login(Map<String, Object> body) {
        String userId = RequestMapUtil.reqStr(body, "userId");
        String userPassword = RequestMapUtil.reqStr(body, "userPassword");
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
            return jdbcTemplate.queryForObject(sql, this::profileRowFromRs,
                    userId,
                    userPassword
            );
        } catch (Exception e) {
            log.error("로그인 실패: userId={}, error={}", userId, e.getMessage());
            return null;
        }
    }

    @Transactional
    public Map<String, Object> updateUserProfile(String userId, Map<String, Object> body) {
        StringBuilder sql = new StringBuilder("UPDATE user_mst SET updated_at = CURRENT_TIMESTAMP");
        List<Object> params = new ArrayList<>();

        String userName = RequestMapUtil.optStr(body, "userName");
        if (userName != null && !userName.isBlank()) {
            sql.append(", user_name = ?");
            params.add(userName);
        }
        String userPassword = RequestMapUtil.optStr(body, "userPassword");
        if (userPassword != null && !userPassword.isBlank()) {
            sql.append(", user_password = ?");
            params.add(userPassword);
        }
        if (body.containsKey("deptIdx")) {
            sql.append(", dept_idx = ?");
            params.add(RequestMapUtil.optInt(body, "deptIdx"));
        }
        if (body.containsKey("userPhone")) {
            sql.append(", user_phone = ?");
            String phone = RequestMapUtil.optStr(body, "userPhone");
            params.add(phone != null && phone.trim().isEmpty() ? null : phone);
        }
        if (body.containsKey("joinDt")) {
            sql.append(", join_dt = ?");
            params.add(RequestMapUtil.optLocalDate(body, "joinDt"));
        }
        if (body.containsKey("svYn")) {
            sql.append(", sv_yn = ?");
            params.add(RequestMapUtil.optChar(body, "svYn"));
        }
        if (body.containsKey("positionCd")) {
            sql.append(", position_cd = ?");
            String pc = RequestMapUtil.optStr(body, "positionCd");
            params.add(pc != null && pc.trim().isEmpty() ? null : pc);
        }
        if (body.containsKey("tagYn")) {
            sql.append(", tag_yn = ?");
            params.add(RequestMapUtil.optChar(body, "tagYn"));
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

    public Map<String, Object> getUserProfile(String userId) {
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
            return jdbcTemplate.queryForObject(sql, this::profileRowFromRs, userId);
        } catch (Exception e) {
            log.error("사용자 정보 조회 실패: userId={}, error={}", userId, e.getMessage());
            return null;
        }
    }

    private Map<String, Object> profileRowFromRs(ResultSet rs, int rowNum) throws SQLException {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("userId", rs.getString("user_id"));
        m.put("userNm", rs.getString("user_name"));
        m.put("email", rs.getString("user_email"));
        m.put("deptIdx", rs.getObject("dept_idx", Integer.class));
        m.put("userPhone", rs.getString("user_phone"));
        m.put("deptNm", rs.getString("dept_nm"));
        m.put("positionCd", rs.getString("position_cd"));
        m.put("positionNm", rs.getString("position_nm"));
        String sv = rs.getString("sv_yn");
        m.put("svYn", sv != null && !sv.isEmpty() ? sv.charAt(0) : null);
        String tag = rs.getString("tag_yn");
        m.put("tagYn", tag != null && !tag.isEmpty() ? tag.charAt(0) : null);
        m.put("joinDt", rs.getObject("join_dt", java.time.LocalDate.class));
        return m;
    }
}
