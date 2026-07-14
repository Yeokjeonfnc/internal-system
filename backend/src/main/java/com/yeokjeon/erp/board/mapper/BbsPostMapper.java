package com.yeokjeon.erp.board.mapper;

import com.yeokjeon.erp.board.dto.BbsPostDetailJdbcRow;
import com.yeokjeon.erp.board.dto.BbsPostInsertParam;
import com.yeokjeon.erp.board.dto.BbsPostListJdbcRow;
import com.yeokjeon.erp.board.dto.BbsPostSaveRequestDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface BbsPostMapper {

    List<BbsPostListJdbcRow> selectPosts(
            @Param("folderIdx") Integer folderIdx,
            @Param("keyword") String keyword,
            @Param("viewerUserId") String viewerUserId,
            @Param("viewerIsOwner") boolean viewerIsOwner);

    BbsPostDetailJdbcRow selectPostById(@Param("postIdx") int postIdx);

    int insertPost(BbsPostInsertParam param);

    int updatePost(
            @Param("postIdx") int postIdx,
            @Param("body") BbsPostSaveRequestDto body,
            @Param("storeIdx") Integer storeIdx);

    int softDeletePost(@Param("postIdx") int postIdx, @Param("userId") String userId);

    int incrementViewCnt(@Param("postIdx") int postIdx);

    long countAllByFolder(@Param("folderIdx") int folderIdx);
}
