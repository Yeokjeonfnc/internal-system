package com.yeokjeon.erp.development.mapper;

import com.yeokjeon.erp.development.dto.PropertyDocumentInsertParam;
import com.yeokjeon.erp.development.dto.PropertyDocumentJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface PropertyDocumentMapper {

    List<PropertyDocumentJdbcRow> selectByPropIdx(@Param("propIdx") int propIdx);

    PropertyDocumentJdbcRow selectByDocIdxAndPropIdx(
            @Param("propertyDocIdx") int propertyDocIdx,
            @Param("propIdx") int propIdx);

    int insert(PropertyDocumentInsertParam param);

    int markDeleted(
            @Param("propertyDocIdx") int propertyDocIdx,
            @Param("propIdx") int propIdx);
}
