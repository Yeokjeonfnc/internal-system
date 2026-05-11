package com.yeokjeon.erp.master.repository;

import com.yeokjeon.erp.master.entity.MstUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MstUserRepository extends JpaRepository<MstUser, Integer> {

    Optional<MstUser> findByUserId(String userId);
}
