package com.yeokjeon.erp.act001.repository;

import com.yeokjeon.erp.act001.entity.Act001Active;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface Act001Repository extends JpaRepository<Act001Active, Integer> {

    @Query("SELECT a FROM Act001Active a ORDER BY a.creatDt DESC, a.actIdx DESC")
    List<Act001Active> findAllActivities();

    List<Act001Active> findByApprStatusOrderByCreatDtDescActIdxDesc(String apprStatus);

    List<Act001Active> findByStoreIdxOrderByActDtDescActIdxDesc(Integer storeIdx);

    List<Act001Active> findByChkYnOrderByCreatDtDescActIdxDesc(Character chkYn);
}
