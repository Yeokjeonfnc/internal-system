package com.yeokjeon.erp.active.mapper;

import com.yeokjeon.erp.active.dto.ActAttachmentInsertParam;
import com.yeokjeon.erp.active.dto.ActAttachmentJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface ActAttachmentMapper {

    List<ActAttachmentJdbcRow> selectByActIdx(@Param("actIdx") int actIdx);

    ActAttachmentJdbcRow selectByAttIdxAndActIdx(
            @Param("actAttIdx") int actAttIdx, @Param("actIdx") int actIdx);

    long sumFileSizeByActIdx(@Param("actIdx") int actIdx);

    void insert(ActAttachmentInsertParam param);

    int markDeleted(@Param("actAttIdx") int actAttIdx, @Param("actIdx") int actIdx);
}
