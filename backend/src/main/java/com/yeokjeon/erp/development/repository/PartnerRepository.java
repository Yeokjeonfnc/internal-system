package com.yeokjeon.erp.development.repository;

import com.yeokjeon.erp.development.entity.Partner;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PartnerRepository extends JpaRepository<Partner, Integer> {
}
