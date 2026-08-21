package com.yeokjeon.erp.eap.mapper;

import com.yeokjeon.erp.eap.dto.EapDocLineInsertParam;
import com.yeokjeon.erp.eap.dto.EapDocLineJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface EapDocLineMapper {

    List<EapDocLineJdbcRow> selectByMappingId(@Param("mappingId") long mappingId);

    int deleteByMappingId(@Param("mappingId") long mappingId);

    int insert(EapDocLineInsertParam param);

    int updateLineStatus(
            @Param("lineId") long lineId,
            @Param("lineStatus") String lineStatus);
}
