package com.yeokjeon.erp.checklist.service;

import com.yeokjeon.erp.checklist.dto.ChecklistResponseDto;
import com.yeokjeon.erp.checklist.dto.ChecklistRequestDto;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ChecklistService {

    private final JdbcTemplate jdbcTemplate;

    @Transactional
    public ChecklistResponseDto createChecklist(ChecklistRequestDto dto) {
        Character useYn = dto.getUseYn() == null ? 'N' : Character.toUpperCase(dto.getUseYn());
        Integer baseScore = dto.getBaseScore() == null ? 0 : dto.getBaseScore();
        Integer chkIdx = jdbcTemplate.queryForObject(
                """
                insert into chk_mst (
                    brand_cd,
                    chk_type,
                    chk_content,
                    base_score,
                    use_yn,
                    display_order
                )
                values (
                    ?,
                    ?,
                    ?,
                    ?,
                    ?,
                    coalesce((select max(display_order) + 1 from chk_mst), 1)
                )
                returning chk_idx
                """,
                Integer.class,
                dto.getBrandCd().trim(),
                dto.getChkType().trim(),
                dto.getChkContent().trim(),
                baseScore,
                useYn);
        return getChecklist(chkIdx);
    }

    @Transactional
    public ChecklistResponseDto updateChecklist(Integer chkIdx, ChecklistRequestDto dto) {
        Character useYn = dto.getUseYn() == null ? 'N' : Character.toUpperCase(dto.getUseYn());
        Integer baseScore = dto.getBaseScore() == null ? 0 : dto.getBaseScore();
        jdbcTemplate.update(
                """
                update chk_mst
                   set brand_cd = ?,
                       chk_type = ?,
                       chk_content = ?,
                       base_score = ?,
                       use_yn = ?,
                       update_dt = CURRENT_TIMESTAMP
                 where chk_idx = ?
                """,
                dto.getBrandCd().trim(),
                dto.getChkType().trim(),
                dto.getChkContent().trim(),
                baseScore,
                useYn,
                chkIdx);
        return getChecklist(chkIdx);
    }

    public List<ChecklistResponseDto> getChecklists(String brandCd, String chkType) {
        StringBuilder sql = new StringBuilder("""
                select c.chk_idx,
                       c.brand_cd,
                       c.chk_type,
                       coalesce(cm.code_nm, c.chk_type) as chk_type_nm,
                       c.chk_content,
                       c.base_score,
                       c.use_yn,
                       c.display_order
                from chk_mst c
                left join code_mst cm
                  on cm.grp_cd = 50
                 and cm.code_cd = c.chk_type
                where c.use_yn = 'Y'
                """);
        List<Object> params = new ArrayList<>();

        if (brandCd != null && !brandCd.isBlank()) {
            sql.append(" and c.brand_cd = ?");
            params.add(brandCd.trim());
        }
        if (chkType != null && !chkType.isBlank()) {
            sql.append(" and c.chk_type = ?");
            params.add(chkType.trim());
        }

        sql.append(" order by c.display_order nulls last, c.chk_idx");

        return jdbcTemplate.query(
                sql.toString(),
                (rs, rowNum) -> ChecklistResponseDto.builder()
                        .chkIdx(rs.getInt("chk_idx"))
                        .brandCd(rs.getString("brand_cd"))
                        .chkType(rs.getString("chk_type"))
                        .chkTypeNm(rs.getString("chk_type_nm"))
                        .chkContent(rs.getString("chk_content"))
                        .baseScore(rs.getObject("base_score", Integer.class))
                        .useYn(rs.getString("use_yn") == null ? null : rs.getString("use_yn").charAt(0))
                        .displayOrder(rs.getObject("display_order", Integer.class))
                        .build(),
                params.toArray());
    }

    private ChecklistResponseDto getChecklist(Integer chkIdx) {
        return jdbcTemplate.queryForObject(
                """
                select c.chk_idx,
                       c.brand_cd,
                       c.chk_type,
                       coalesce(cm.code_nm, c.chk_type) as chk_type_nm,
                       c.chk_content,
                       c.base_score,
                       c.use_yn,
                       c.display_order
                from chk_mst c
                left join code_mst cm
                  on cm.grp_cd = 50
                 and cm.code_cd = c.chk_type
                where c.chk_idx = ?
                """,
                (rs, rowNum) -> ChecklistResponseDto.builder()
                        .chkIdx(rs.getInt("chk_idx"))
                        .brandCd(rs.getString("brand_cd"))
                        .chkType(rs.getString("chk_type"))
                        .chkTypeNm(rs.getString("chk_type_nm"))
                        .chkContent(rs.getString("chk_content"))
                        .baseScore(rs.getObject("base_score", Integer.class))
                        .useYn(rs.getString("use_yn") == null ? null : rs.getString("use_yn").charAt(0))
                        .displayOrder(rs.getObject("display_order", Integer.class))
                        .build(),
                chkIdx);
    }
}
