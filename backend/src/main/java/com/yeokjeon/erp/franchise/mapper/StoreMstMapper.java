package com.yeokjeon.erp.franchise.mapper;

import com.yeokjeon.erp.franchise.dto.StoreMstDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface StoreMstMapper {

    List<StoreMstDto> selectStoreListOrdered();

    /** {@code pattern} 예: {@code "%검색어%"} — Spring Data {@code Containing} 과 동일한 LIKE 검색. */
    List<StoreMstDto> selectStoresByStoreNmLike(@Param("pattern") String pattern);

    int countStoreNmDuplicate(@Param("nm") String nm);

    int countStoreNmDuplicateExclude(@Param("nm") String nm, @Param("excludeIdx") int excludeStoreIdx);

    int countAddressDuplicate(@Param("addr") String addr, @Param("zip") String zip);

    int countAddressDuplicateExclude(
            @Param("addr") String addr,
            @Param("zip") String zip,
            @Param("excludeIdx") int excludeStoreIdx);
}
