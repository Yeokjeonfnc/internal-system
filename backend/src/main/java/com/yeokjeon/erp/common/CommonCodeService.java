package com.yeokjeon.erp.common;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CommonCodeService {

    private final JdbcTemplate jdbcTemplate;

    public List<CodeOptionDto> getCodesByGroup(int grpCd) {
        return jdbcTemplate.query(
                """
                select code_cd, code_nm
                from code_mst
                where grp_cd = ?
                  and use_yn = 'Y'
                order by code_cd
                """,
                (rs, rowNum) -> CodeOptionDto.builder()
                        .codeCd(rs.getString("code_cd"))
                        .codeNm(rs.getString("code_nm"))
                        .build(),
                grpCd);
    }
}
