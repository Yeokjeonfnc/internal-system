package com.yeokjeon.erp.franchise.repository;

import com.yeokjeon.erp.franchise.entity.Store;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface StoreRepository extends JpaRepository<Store, Integer> {

    Optional<Store> findByStoreIdx(Integer storeIdx);

    Optional<Store> findByPropIdx(Integer propIdx);
}
