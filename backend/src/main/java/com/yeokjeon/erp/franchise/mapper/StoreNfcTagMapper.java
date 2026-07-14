package com.yeokjeon.erp.franchise.mapper;

import com.yeokjeon.erp.franchise.dto.StoreNfcTagJdbcRow;
import com.yeokjeon.erp.franchise.dto.StoreNfcTagLookupDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface StoreNfcTagMapper {

    StoreNfcTagJdbcRow selectByStoreIdx(@Param("storeIdx") Integer storeIdx);

    StoreNfcTagJdbcRow selectByTagUid(@Param("tagUid") String tagUid);

    StoreNfcTagLookupDto selectLookupByTagUid(@Param("tagUid") String tagUid);

    int upsert(
            @Param("storeIdx") Integer storeIdx,
            @Param("tagUid") String tagUid,
            @Param("registeredBy") String registeredBy);

    int deleteByStoreIdx(@Param("storeIdx") Integer storeIdx);
}
