package com.yeokjeon.erp.eap.mapper;

import com.yeokjeon.erp.eap.dto.EapApprovalMappingInsertParam;
import com.yeokjeon.erp.eap.dto.EapApprovalMappingJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface EapApprovalMappingMapper {

    List<EapApprovalMappingJdbcRow> selectByFolder(@Param("folder") String folder);

    EapApprovalMappingJdbcRow selectByDocumentId(@Param("documentId") String documentId);

    EapApprovalMappingJdbcRow selectById(@Param("id") long id);

    int insert(EapApprovalMappingInsertParam param);

    int updateStatusByDocumentId(
            @Param("documentId") String documentId,
            @Param("status") String status);

    /**
     * docId / ERP-{id} / 매핑 id 등 여러 키로 상태 반영.
     * {@code newDaouDocumentId} 가 있으면 daou_document_id 도 동기화.
     */
    int updateStatusByLookup(
            @Param("lookupId") String lookupId,
            @Param("status") String status,
            @Param("newDaouDocumentId") String newDaouDocumentId);

    int updateDaouDocument(
            @Param("id") long id,
            @Param("daouDocumentId") String daouDocumentId,
            @Param("status") String status);
}
