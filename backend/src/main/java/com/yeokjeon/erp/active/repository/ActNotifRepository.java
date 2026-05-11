package com.yeokjeon.erp.active.repository;

import com.yeokjeon.erp.active.entity.ActNotif;
import org.springframework.data.jpa.repository.JpaRepository;

/** 알림 CUD·단건 조회 — 목록·결재일 조회는 {@link com.yeokjeon.erp.active.mapper.ActMstMapper}. */
public interface ActNotifRepository extends JpaRepository<ActNotif, Long> {}
