package com.yeokjeon.erp.board.mapper;

import com.yeokjeon.erp.board.dto.BbsFolderInsertParam;
import com.yeokjeon.erp.board.dto.BbsFolderJdbcRow;
import com.yeokjeon.erp.board.dto.BbsFolderSaveRequestDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface BbsFolderMapper {

    List<BbsFolderJdbcRow> selectFoldersForViewer(@Param("viewerIsOwner") boolean viewerIsOwner);

    long countPostsByFolderForViewer(
            @Param("folderIdx") int folderIdx,
            @Param("viewerUserId") String viewerUserId,
            @Param("viewerIsOwner") boolean viewerIsOwner);

    BbsFolderJdbcRow selectFolderById(@Param("folderIdx") int folderIdx);

    int insertFolder(BbsFolderInsertParam param);

    int updateFolder(
            @Param("folderIdx") int folderIdx,
            @Param("body") BbsFolderSaveRequestDto body,
            @Param("userId") String userId);

    int deleteFolder(@Param("folderIdx") int folderIdx);
}
