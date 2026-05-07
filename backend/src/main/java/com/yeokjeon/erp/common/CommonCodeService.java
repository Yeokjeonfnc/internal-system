package com.yeokjeon.erp.common;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CommonCodeService {

    private final JdbcTemplate jdbcTemplate;

    public List<Map<String, Object>> getCodesByGroup(int grpCd) {
        return jdbcTemplate.query(
                """
                select code_cd, code_nm
                from code_mst
                where grp_cd = ?
                  and (use_yn is null or use_yn = 'Y')
                order by code_cd
                """,
                (rs, rowNum) -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("codeCd", rs.getString("code_cd"));
                    m.put("codeNm", rs.getString("code_nm"));
                    return m;
                },
                grpCd);
    }
}
