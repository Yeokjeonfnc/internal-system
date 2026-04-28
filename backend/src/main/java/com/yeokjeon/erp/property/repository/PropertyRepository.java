package com.yeokjeon.erp.property.repository;

import com.yeokjeon.erp.property.entity.Property;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PropertyRepository extends JpaRepository<Property, Integer> {

    @Query("SELECT p FROM Property p ORDER BY p.propIdx DESC")
    List<Property> findAllProperties();
}
