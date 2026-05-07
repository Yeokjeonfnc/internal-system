package com.yeokjeon.erp.prp001.repository;

import com.yeokjeon.erp.prp001.entity.Property;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PropertyRepository extends JpaRepository<Property, Integer> {

    @Query("SELECT p FROM Property p ORDER BY p.propIdx DESC")
    List<Property> findAllProperties();
}
