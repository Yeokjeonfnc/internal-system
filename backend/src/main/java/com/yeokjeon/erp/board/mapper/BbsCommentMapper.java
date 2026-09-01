package com.yeokjeon.erp.board.mapper;

import com.yeokjeon.erp.board.dto.BbsCommentInsertParam;
import com.yeokjeon.erp.board.dto.BbsCommentJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface BbsCommentMapper {

    List<BbsCommentJdbcRow> selectByPostIdx(@Param("postIdx") int postIdx);

    BbsCommentJdbcRow selectByIdx(
            @Param("commentIdx") int commentIdx, @Param("postIdx") int postIdx);

    int insert(BbsCommentInsertParam param);

    int softDelete(
            @Param("commentIdx") int commentIdx,
            @Param("postIdx") int postIdx,
            @Param("userId") String userId);
}
