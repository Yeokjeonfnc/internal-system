package com.yeokjeon.erp.franchise.dto;

/**
 * 가맹점 삭제를 막는 참조 건수 — `store_mst.store_idx` 를 가리키는 FK 중
 * ON DELETE 동작이 없는 것들.
 *
 * <p>삭제를 그냥 시도하면 DB 가 23503 을 던지고 화면에는 "연결된 데이터가 있어
 * 처리할 수 없습니다" 같은 뭉뚱그린 문구만 남아, 사용자는 무엇을 먼저 정리해야
 * 하는지 알 수 없다. 미리 세어서 사유를 알려주려고 쓴다.
 */
public record StoreDeleteBlockerRow(
        Integer ownerUserCnt,
        Integer nfcTagCnt,
        Integer bbsPostCnt,
        Integer planStoreCnt) {}
