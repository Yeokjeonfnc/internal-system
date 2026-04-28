package com.yeokjeon.erp.store.repository;

import com.yeokjeon.erp.store.entity.Store;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StoreRepository extends JpaRepository<Store, Integer> {
    
    @Query("SELECT s FROM Store s ORDER BY s.storeIdx DESC")
    List<Store> findAllStores();
    
    List<Store> findByStoreNmContaining(String storeNm);
    
    List<Store> findByBrandCd(String brandCd);
    
    List<Store> findByRegionCd(String regionCd);
    
    List<Store> findByStoreStatus(String storeStatus);
    
    List<Store> findByStoreType(String storeType);

    Optional<Store> findByStoreIdx(Integer storeIdx);
}
