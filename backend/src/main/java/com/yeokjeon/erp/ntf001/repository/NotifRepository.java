package com.yeokjeon.erp.ntf001.repository;

import com.yeokjeon.erp.ntf001.entity.Notif;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface NotifRepository extends JpaRepository<Notif, Long> {

    @Query("SELECT n FROM Notif n WHERE n.userId = :userId ORDER BY n.creatDt DESC, n.notifIdx DESC")
    List<Notif> findForUser(@Param("userId") String userId);

    long countByUserIdAndReadYn(String userId, Character readYn);

    List<Notif> findByUserIdAndActIdxAndNotifTyp(String userId, Integer actIdx, String notifTyp);

    List<Notif> findByActIdxAndNotifTypAndApprYnOrderByNotifIdxAsc(Integer actIdx, String notifTyp, String apprYn);
}
