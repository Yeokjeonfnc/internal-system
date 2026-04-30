package com.yeokjeon.erp.activity.repository;

import com.yeokjeon.erp.activity.entity.Active;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ActiveRepository extends JpaRepository<Active, Integer> {

    @Query("SELECT a FROM Active a ORDER BY a.creatDt DESC, a.actIdx DESC")
    List<Active> findAllActivities();

    List<Active> findByApprStatusOrderByCreatDtDescActIdxDesc(String apprStatus);

    List<Active> findByStoreIdxOrderByActDtDescActIdxDesc(Integer storeIdx);
}
