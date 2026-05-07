package com.yeokjeon.erp.mst001.repository;

import java.time.LocalDate;
import java.time.ZonedDateTime;

/**
 * Native JOIN 조회 결과 — {@link UserRepository} 전용.
 */
public interface UserListRow {

    Integer getUserIdx();

    String getUserName();

    String getUserId();

    Integer getDeptIdx();

    String getDeptNm();

    String getUserPhone();

    String getUserEmail();

    String getSvYn();

    String getPositionCd();

    String getPositionNm();

    String getTagYn();

    LocalDate getJoinDt();

    ZonedDateTime getCreatedAt();

    ZonedDateTime getUpdatedAt();
}
