package com.yeokjeon.erp.franchise.mapper;

import com.yeokjeon.erp.franchise.dto.StoreDocumentInsertParam;
import com.yeokjeon.erp.franchise.dto.StoreDocumentJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface StoreDocumentMapper {

    List<StoreDocumentJdbcRow> selectByStoreIdx(@Param("storeIdx") int storeIdx);

    StoreDocumentJdbcRow selectByDocIdxAndStoreIdx(
            @Param("storeDocIdx") int storeDocIdx, @Param("storeIdx") int storeIdx);

    void insert(StoreDocumentInsertParam param);

    int markDeleted(
            @Param("storeDocIdx") int storeDocIdx, @Param("storeIdx") int storeIdx);
}
