package com.yeokjeon.erp.partner.repository;

import com.yeokjeon.erp.partner.entity.Partner;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PartnerRepository extends JpaRepository<Partner, Integer> {

    @Query("SELECT p FROM Partner p ORDER BY p.partnerIdx DESC")
    List<Partner> findAllPartners();
}
