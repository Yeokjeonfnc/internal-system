package com.yeokjeon.erp.franchise.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 가맹점 {@code POST /stores}·{@code PUT /stores/{id}} 공통 요청 본문 — JSON 필드명은 기존과 동일.
 * <ul>
 *     <li>생성({@code POST}): 서비스에서 {@code storeNm}, {@code svId}, {@code contManager} 비어 있음 검증.</li>
 *     <li>수정({@code PUT}): 값이 {@code null}인 항목은 변경하지 않음.</li>
 *     <li>{@code partnerIdx}: 생성 시에만 사용, 수정 시 무시.</li>
 *     <li>{@code propIdx}: 물건 마스터 연결(선택). 수정 시 {@code null}이면 변경 없음.</li>
 * </ul>
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record StoreMstWriteRequestDto(
        Integer storeIdx,
        String storeCd,
        String storeNm,
        String ownerNm,
        String regionCd,
        String storeTel,
        String address,
        BigDecimal latitude,
        BigDecimal longitude,
        String storeStatus,
        LocalDate contEndDt,
        Boolean autoRenewalYn,
        String storeType,
        String svId,
        String svNm,
        String adressDetail,
        String zipCd,
        String brandCd,
        LocalDate contStartDt,
        String businessNumber,
        LocalDate firstContDt,
        LocalDate transferDate,
        BigDecimal frFee,
        BigDecimal eduFee,
        BigDecimal insuDeposit,
        BigDecimal contDeposit,
        String contManager,
        String contManagerNm,
        String eduManager,
        String eduManagerNm,
        BigDecimal contArea,
        BigDecimal realArea,
        Integer floor,
        Integer parkingCount,
        Integer premiumFee,
        Integer monthlyRent,
        Integer rentDeposit,
        String notes,
        Integer partnerIdx,
        Integer propIdx) {}
