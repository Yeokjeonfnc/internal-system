package com.yeokjeon.erp.dept.service;

import com.yeokjeon.erp.dept.dto.DeptSortOrderRequestDto;
import com.yeokjeon.erp.dept.dto.DeptTreeResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowCallbackHandler;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DeptService {

    private static final String[] USER_TABLE_CANDIDATES = {
            "user_mst", "usr_mst", "employee_mst", "emp_mst", "users"
    };

    private final JdbcTemplate jdbcTemplate;

    public List<DeptTreeResponseDto> getDeptTree() {
        boolean hasSortOrder = hasColumn("dept_mst", "sort_order");
        Map<Integer, Integer> userCounts = loadUserCounts();
        Map<Integer, String> managerNames = loadManagerNames();

        String sortSelect = hasSortOrder ? "d.sort_order" : "null::integer as sort_order";
        String orderBy = hasSortOrder
                ? "coalesce(d.upper_dept_idx, 0), d.dept_level nulls first, d.sort_order nulls last, d.dept_idx"
                : "coalesce(d.upper_dept_idx, 0), d.dept_level nulls first, d.dept_idx";

        List<DeptTreeResponseDto> rows = jdbcTemplate.query(
                """
                select d.dept_idx,
                       d.upper_dept_idx,
                       d.dept_nm,
                       d.dept_level,
                       %s
                from dept_mst d
                order by %s
                """.formatted(sortSelect, orderBy),
                (rs, rowNum) -> DeptTreeResponseDto.builder()
                        .deptIdx(rs.getObject("dept_idx", Integer.class))
                        .upperDeptIdx(rs.getObject("upper_dept_idx", Integer.class))
                        .deptNm(rs.getString("dept_nm"))
                        .deptLevel(rs.getObject("dept_level", Integer.class))
                        .sortOrder(rs.getObject("sort_order", Integer.class))
                        .managerNm(managerNames.get(rs.getObject("dept_idx", Integer.class)))
                        .userCount(userCounts.getOrDefault(rs.getObject("dept_idx", Integer.class), 0))
                        .children(new ArrayList<>())
                        .build());

        Map<Integer, DeptTreeResponseDto> byId = new LinkedHashMap<>();
        for (DeptTreeResponseDto row : rows) {
            byId.put(row.getDeptIdx(), row);
        }

        List<DeptTreeResponseDto> roots = new ArrayList<>();
        for (DeptTreeResponseDto row : rows) {
            Integer parentId = row.getUpperDeptIdx();
            DeptTreeResponseDto parent = parentId == null ? null : byId.get(parentId);
            if (parent == null) {
                roots.add(row);
            } else {
                parent.addChild(row);
            }
        }
        return roots;
    }

    @Transactional
    public void updateSortOrder(DeptSortOrderRequestDto dto) {
        boolean hasSortOrder = hasColumn("dept_mst", "sort_order");
        for (DeptSortOrderRequestDto.Item item : dto.getItems()) {
            if (hasSortOrder) {
                jdbcTemplate.update(
                        """
                        update dept_mst
                           set upper_dept_idx = ?,
                               sort_order = ?
                         where dept_idx = ?
                        """,
                        item.getUpperDeptIdx(),
                        item.getSortOrder(),
                        item.getDeptIdx());
            } else {
                jdbcTemplate.update(
                        "update dept_mst set upper_dept_idx = ? where dept_idx = ?",
                        item.getUpperDeptIdx(),
                        item.getDeptIdx());
            }
        }
    }

    private Map<Integer, Integer> loadUserCounts() {
        Map<Integer, Integer> result = new HashMap<>();
        jdbcTemplate.query(
                """
                select d.dept_idx,
                       (
                           select count(*)
                           from user_mst u
                           where u.dept_idx in (
                               with recursive sub_depts as (
                                   select dept_idx
                                   from dept_mst
                                   where dept_idx = d.dept_idx
                                   union
                                   select m.dept_idx
                                   from dept_mst m
                                            join sub_depts s on m.upper_dept_idx = s.dept_idx
                               )
                               select dept_idx
                               from sub_depts
                           )
                       ) as user_count
                from dept_mst d
                """,
                (RowCallbackHandler) rs -> result.put(rs.getInt("dept_idx"), rs.getInt("user_count")));
        return result;
    }

    private Map<Integer, String> loadManagerNames() {
        String tableName = findUserTableWithColumn("dept_idx");
        if (tableName == null) return Map.of();

        String nameColumn = firstExistingColumn(tableName, "user_nm", "user_name", "emp_nm", "name");
        String managerColumn = firstExistingColumn(tableName, "manager_yn", "leader_yn", "dept_manager_yn", "responsible_yn");
        if (nameColumn == null || managerColumn == null) return Map.of();

        Map<Integer, String> result = new HashMap<>();
        jdbcTemplate.query(
                """
                select dept_idx, min(%s) as manager_nm
                from %s
                where dept_idx is not null
                  and upper(coalesce(%s::text, 'N')) in ('Y', 'TRUE', '1')
                group by dept_idx
                """.formatted(nameColumn, tableName, managerColumn),
                (RowCallbackHandler) rs -> result.put(rs.getInt("dept_idx"), rs.getString("manager_nm")));
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
        Integer count = jdbcTemplate.queryForObject(
                """
                select count(*)
                from information_schema.columns
                where table_schema = 'public'
                  and table_name = ?
                  and column_name = ?
                """,
                Integer.class,
                tableName,
                columnName);
        return count != null && count > 0;
    }
}
