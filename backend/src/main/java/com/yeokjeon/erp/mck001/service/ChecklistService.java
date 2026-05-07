package com.yeokjeon.erp.mck001.service;

import com.yeokjeon.erp.common.RequestMapUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ChecklistService {

    private final JdbcTemplate jdbcTemplate;

    @Transactional
    public Map<String, Object> createChecklist(Map<String, Object> body) {
        Character useYnRaw = RequestMapUtil.optChar(body, "useYn");
        Character useYn = useYnRaw == null ? 'N' : Character.toUpperCase(useYnRaw);
        Integer baseScore = RequestMapUtil.optInt(body, "baseScore");
        if (baseScore == null) {
            baseScore = 0;
        }
        String brandCd = RequestMapUtil.reqStr(body, "brandCd").trim();
        String chkType = RequestMapUtil.reqStr(body, "chkType").trim();
        String chkContent = RequestMapUtil.reqStr(body, "chkContent").trim();
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
                brandCd,
                chkType,
                chkContent,
                baseScore,
                useYn);
        return getChecklist(chkIdx);
    }

    @Transactional
    public Map<String, Object> updateChecklist(Integer chkIdx, Map<String, Object> body) {
        Character useYnRaw = RequestMapUtil.optChar(body, "useYn");
        Character useYn = useYnRaw == null ? 'N' : Character.toUpperCase(useYnRaw);
        Integer baseScore = RequestMapUtil.optInt(body, "baseScore");
        if (baseScore == null) {
            baseScore = 0;
        }
        String brandCd = RequestMapUtil.reqStr(body, "brandCd").trim();
        String chkType = RequestMapUtil.reqStr(body, "chkType").trim();
        String chkContent = RequestMapUtil.reqStr(body, "chkContent").trim();
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
                brandCd,
                chkType,
                chkContent,
                baseScore,
                useYn,
                chkIdx);
        return getChecklist(chkIdx);
    }

    public List<Map<String, Object>> getChecklists(String brandCd, String chkType) {
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
                (rs, rowNum) -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("chkIdx", rs.getInt("chk_idx"));
                    m.put("brandCd", rs.getString("brand_cd"));
                    m.put("chkType", rs.getString("chk_type"));
                    m.put("chkTypeNm", rs.getString("chk_type_nm"));
                    m.put("chkContent", rs.getString("chk_content"));
                    m.put("baseScore", rs.getObject("base_score", Integer.class));
                    String uy = rs.getString("use_yn");
                    m.put("useYn", uy == null ? null : uy.charAt(0));
                    m.put("displayOrder", rs.getObject("display_order", Integer.class));
                    return m;
                },
                params.toArray());
    }

    private Map<String, Object> getChecklist(Integer chkIdx) {
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
                (rs, rowNum) -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("chkIdx", rs.getInt("chk_idx"));
                    m.put("brandCd", rs.getString("brand_cd"));
                    m.put("chkType", rs.getString("chk_type"));
                    m.put("chkTypeNm", rs.getString("chk_type_nm"));
                    m.put("chkContent", rs.getString("chk_content"));
                    m.put("baseScore", rs.getObject("base_score", Integer.class));
                    String uy = rs.getString("use_yn");
                    m.put("useYn", uy == null ? null : uy.charAt(0));
                    m.put("displayOrder", rs.getObject("display_order", Integer.class));
                    return m;
                },
                chkIdx);
    }
}
