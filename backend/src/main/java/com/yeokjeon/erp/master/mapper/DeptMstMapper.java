package com.yeokjeon.erp.master.mapper;

import com.yeokjeon.erp.master.dto.DeptFlatRow;
import com.yeokjeon.erp.master.dto.DeptManagerRow;
import com.yeokjeon.erp.master.dto.DeptUserCountRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface DeptMstMapper {

    int countInformationSchemaColumns(
            @Param("tableName") String tableName, @Param("columnName") String columnName);

    List<DeptFlatRow> selectDeptFlat(@Param("hasSortOrder") boolean hasSortOrder);

    List<DeptUserCountRow> selectDeptUserCounts();

    List<DeptManagerRow> selectManagerNames(
            @Param("tableName") String tableName,
            @Param("nameColumn") String nameColumn,
            @Param("managerColumn") String managerColumn);

    int updateDeptSortAndUpper(
            @Param("upperDeptIdx") Integer upperDeptIdx,
            @Param("sortOrder") Integer sortOrder,
            @Param("deptIdx") Integer deptIdx);

    int updateDeptUpperOnly(@Param("upperDeptIdx") Integer upperDeptIdx, @Param("deptIdx") Integer deptIdx);
}
