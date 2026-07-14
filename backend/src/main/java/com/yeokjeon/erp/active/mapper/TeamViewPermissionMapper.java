package com.yeokjeon.erp.active.mapper;

import com.yeokjeon.erp.active.dto.TeamViewPermissionDto;
import com.yeokjeon.erp.active.dto.TeamViewPermissionItemDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface TeamViewPermissionMapper {

    List<TeamViewPermissionDto> selectByViewerUserIdx(@Param("viewerUserIdx") int viewerUserIdx);

    int deleteByViewerUserIdx(@Param("viewerUserIdx") int viewerUserIdx);

    int insertBatch(
            @Param("viewerUserIdx") int viewerUserIdx,
            @Param("grantedBy") String grantedBy,
            @Param("items") List<TeamViewPermissionItemDto> items);
}
