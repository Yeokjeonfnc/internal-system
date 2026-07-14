package com.yeokjeon.erp.board.mapper;

import com.yeokjeon.erp.board.dto.BbsDocumentInsertParam;
import com.yeokjeon.erp.board.dto.BbsDocumentJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface BbsDocumentMapper {

    List<BbsDocumentJdbcRow> selectByPostIdx(@Param("postIdx") int postIdx);

    BbsDocumentJdbcRow selectByDocIdxAndPostIdx(
            @Param("bbsDocIdx") int bbsDocIdx, @Param("postIdx") int postIdx);

    int insert(BbsDocumentInsertParam param);

    int markDeleted(@Param("bbsDocIdx") int bbsDocIdx, @Param("postIdx") int postIdx);
}
