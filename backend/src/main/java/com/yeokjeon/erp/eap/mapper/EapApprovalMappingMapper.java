package com.yeokjeon.erp.eap.mapper;

import com.yeokjeon.erp.eap.dto.EapApprovalMappingInsertParam;
import com.yeokjeon.erp.eap.dto.EapApprovalMappingJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface EapApprovalMappingMapper {

    List<EapApprovalMappingJdbcRow> selectByFolder(
            @Param("folder") String folder,
            @Param("userId") String userId);

    /** 전체 문서(관리자) — 사용자 필터 없음 */
    List<EapApprovalMappingJdbcRow> selectAllDocuments();

    EapApprovalMappingJdbcRow selectByDocumentId(@Param("documentId") String documentId);

    EapApprovalMappingJdbcRow selectById(@Param("id") long id);

    int insert(EapApprovalMappingInsertParam param);

    int updateDaouDocument(
            @Param("id") long id,
            @Param("daouDocumentId") String daouDocumentId,
            @Param("status") String status);

    /** 작성중 문서 제목·본문 수정 (updated_at 갱신) */
    int updateDraftContent(
            @Param("id") long id,
            @Param("title") String title,
            @Param("contentHtml") String contentHtml,
            @Param("status") String status);

    int deleteById(@Param("id") long id);
}
