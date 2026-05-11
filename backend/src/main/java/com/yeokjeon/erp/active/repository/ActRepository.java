package com.yeokjeon.erp.active.repository;

import com.yeokjeon.erp.active.entity.ActActive;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ActRepository extends JpaRepository<ActActive, Integer> {
}
