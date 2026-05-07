package com.yeokjeon.erp.mst001.repository;

import com.yeokjeon.erp.mst001.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Integer> {

    Optional<User> findByUserId(String userId);

    @Query(value = """
            SELECT u.user_idx AS userIdx,
                   u.user_name AS userName,
                   u.user_id AS userId,
                   u.dept_idx AS deptIdx,
                   d.dept_nm AS deptNm,
                   u.user_phone AS userPhone,
                   u.user_email AS userEmail,
                   CAST(u.sv_yn AS text) AS svYn,
                   u.position_cd AS positionCd,
                   pos.code_nm AS positionNm,
                   CAST(u.tag_yn AS text) AS tagYn,
                   u.join_dt AS joinDt,
                   u.created_at AS createdAt,
                   u.updated_at AS updatedAt
            FROM user_mst u
            LEFT JOIN dept_mst d ON d.dept_idx = u.dept_idx
            LEFT JOIN code_mst pos ON pos.grp_cd = '60' AND pos.code_cd = u.position_cd
            WHERE (:deptIdx IS NULL OR u.dept_idx = :deptIdx)
            ORDER BY u.user_idx DESC
            """, nativeQuery = true)
    List<UserListRow> findAllEnriched(@Param("deptIdx") Integer deptIdx);

    @Query(value = """
            SELECT u.user_idx AS userIdx,
                   u.user_name AS userName,
                   u.user_id AS userId,
                   u.dept_idx AS deptIdx,
                   d.dept_nm AS deptNm,
                   u.user_phone AS userPhone,
                   u.user_email AS userEmail,
                   CAST(u.sv_yn AS text) AS svYn,
                   u.position_cd AS positionCd,
                   pos.code_nm AS positionNm,
                   CAST(u.tag_yn AS text) AS tagYn,
                   u.join_dt AS joinDt,
                   u.created_at AS createdAt,
                   u.updated_at AS updatedAt
            FROM user_mst u
            LEFT JOIN dept_mst d ON d.dept_idx = u.dept_idx
            LEFT JOIN code_mst pos ON pos.grp_cd = '60' AND pos.code_cd = u.position_cd
            WHERE u.user_idx = :userIdx
            """, nativeQuery = true)
    Optional<UserListRow> findEnrichedById(@Param("userIdx") Integer userIdx);
}
