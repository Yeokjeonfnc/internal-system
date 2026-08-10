package com.yeokjeon.erp.development.repository;

import com.yeokjeon.erp.development.entity.Partner;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface PartnerRepository extends JpaRepository<Partner, Integer> {

    /**
     * 이메일 중복 여부 — TRIM + 대소문자 무시.
     * {@code excludePartnerIdx} 가 있으면 해당 건(본인)은 제외(수정 시).
     */
    @Query("""
            select case when count(p) > 0 then true else false end
            from Partner p
            where p.partnerEmail is not null
              and lower(trim(p.partnerEmail)) = lower(trim(:email))
              and (:excludePartnerIdx is null or p.partnerIdx <> :excludePartnerIdx)
            """)
    boolean existsDuplicateEmail(
            @Param("email") String email,
            @Param("excludePartnerIdx") Integer excludePartnerIdx);
}
