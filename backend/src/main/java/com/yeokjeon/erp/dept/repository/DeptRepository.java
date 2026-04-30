package com.yeokjeon.erp.dept.repository;

import com.yeokjeon.erp.dept.entity.Dept;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeptRepository extends JpaRepository<Dept, Integer> {
}
