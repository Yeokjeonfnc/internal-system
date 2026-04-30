package com.yeokjeon.erp.user.repository;

import com.yeokjeon.erp.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Integer> {

    Optional<User> findByUserId(String userId);

    @Query("SELECT u FROM User u ORDER BY u.userIdx DESC")
    List<User> findAllUsersOrderByIdxDesc();
}
