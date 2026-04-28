package com.yeokjeon.erp.store.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.store.dto.StoreCreateDto;
import com.yeokjeon.erp.store.dto.StoreHistoryResponseDto;
import com.yeokjeon.erp.store.dto.StoreResponseDto;
import com.yeokjeon.erp.store.entity.Store;
import com.yeokjeon.erp.store.repository.StoreRepository;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StoreService {

    private final StoreRepository storeRepository;
    private final EntityManager entityManager;
    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper;

    public List<StoreResponseDto> getAllStores() {
        return storeRepository.findAllStores()
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public StoreResponseDto getStoreByIdx(Integer storeIdx) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        return toDto(store);
    }

    public List<StoreHistoryResponseDto> getStoreHistories(Integer storeIdx) {
        storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        return jdbcTemplate.query(
                """
                select his_idx, store_idx, chg_type, chg_dt, chg_user_id, store_nm, chg_content::text as chg_content
                from store_history
                where store_idx = ?
                order by chg_dt desc, his_idx desc
                """,
                (rs, rowNum) -> StoreHistoryResponseDto.builder()
                        .historyIdx(rs.getLong("his_idx"))
                        .storeIdx(rs.getInt("store_idx"))
                        .chgType(rs.getString("chg_type"))
                        .storeNm(rs.getString("store_nm"))
                        .chgContent(toJsonNode(rs.getString("chg_content")))
                        .content(toHistoryContent(
                                rs.getString("chg_type"),
                                rs.getString("store_nm"),
                                rs.getString("chg_content")))
                        .chgUserId(rs.getString("chg_user_id"))
                        .chgDt(rs.getTimestamp("chg_dt").toLocalDateTime())
                        .build(),
                storeIdx);
    }
    
    private StoreResponseDto toDto(Store store) {
        log.debug("Converting store: {}, name: {}", store.getStoreIdx(), store.getStoreNm());
        
        return StoreResponseDto.builder()
                .storeIdx(store.getStoreIdx())
                .storeCd(store.getStoreCd())
                .storeNm(store.getStoreNm())
                .ownerNm(store.getOwnerNm())
                .regionCd(store.getRegionCd())
                .regionNm(toCodeName(store.getRegionCd(), store.getRegionNm()))
                .storeTel(store.getStoreTel())
                .address(store.getAddress())
                .latitude(store.getLatitude())
                .longitude(store.getLongitude())
                .storeStatus(store.getStoreStatus())
                .storeStatusNm(toCodeName(store.getStoreStatus(), store.getStoreStatusNm()))
                .contEndDt(store.getContEndDt())
                .autoRenewalYn(store.getAutoRenewalYn())
                .storeType(store.getStoreType())
                .storeTypeNm(toCodeName(store.getStoreType(), store.getStoreTypeNm()))
                .svId(store.getSvId())
                .createdAt(store.getCreatedAt())
                .updatedAt(store.getUpdatedAt())
                .adressDetail(store.getAdressDetail())
                .zipCd(store.getZipCd())
                .brandCd(store.getBrandCd())
                .brandNm(toCodeName(store.getBrandCd(), store.getBrandNm()))
                .contStartDt(store.getContStartDt())
                .businessNumber(store.getBusinessNumber())
                .firstContDt(store.getFirstContDt())
                .frFee(store.getFrFee())
                .eduFee(store.getEduFee())
                .insuDeposit(store.getInsuDeposit())
                .contDeposit(store.getContDeposit())
                .contManager(store.getContManager())
                .eduManager(store.getEduManager())
                .contArea(store.getContArea())
                .realArea(store.getRealArea())
                .floor(store.getFloor())
                .parkingCount(store.getParkingCount())
                .premiumFee(store.getPremiumFee())
                .monthlyRent(store.getMonthlyRent())
                .rentDeposit(store.getRentDeposit())
                .notes(store.getNotes())
                .build();
    }

    private String toCodeName(String code, String name) {
        return name != null ? name : code;
    }

    private String toHistoryContent(String chgType, String storeNm, String chgContent) {
        String action = switch (chgType) {
            case "INSERT" -> "가맹점 신규 생성";
            case "UPDATE" -> "가맹점 정보 수정";
            case "DELETE" -> "가맹점 삭제";
            default -> "가맹점 변경";
        };
        if (storeNm != null && !storeNm.isBlank()) {
            return action + ": " + storeNm;
        }
        return chgContent != null ? chgContent : action;
    }

    private JsonNode toJsonNode(String rawJson) {
        if (rawJson == null || rawJson.isBlank()) {
            return objectMapper.createArrayNode();
        }
        try {
            return objectMapper.readTree(rawJson);
        } catch (JsonProcessingException e) {
            log.warn("히스토리 JSON 파싱 실패: {}", rawJson, e);
            return objectMapper.createArrayNode();
        }
    }

    @Transactional
    public StoreResponseDto createStore(StoreCreateDto dto) {
        if (dto.getStoreIdx() != null && storeRepository.findByStoreIdx(dto.getStoreIdx()).isPresent()) {
            throw new IllegalArgumentException("이미 존재하는 가맹점 인덱스입니다: " + dto.getStoreIdx());
        }

        Store store = dto.toEntity();
        Store savedStore = storeRepository.saveAndFlush(store);
        entityManager.refresh(savedStore);
        saveHistory(savedStore.getStoreIdx(), "INSERT", savedStore.getStoreNm(),
                String.format("가맹점 신규 생성: %s", savedStore.getStoreNm()));

        log.info("가맹점 생성 완료: {}", savedStore.getStoreIdx());
        return toDto(savedStore);
    }

    @Transactional
    public StoreResponseDto updateStore(Integer storeIdx, StoreCreateDto dto) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));

        if (dto.getStoreNm() != null) store.setStoreNm(dto.getStoreNm());
        if (dto.getOwnerNm() != null) store.setOwnerNm(dto.getOwnerNm());
        if (dto.getRegionCd() != null) store.setRegionCd(dto.getRegionCd());
        if (dto.getStoreTel() != null) store.setStoreTel(dto.getStoreTel());
        if (dto.getAddress() != null) store.setAddress(dto.getAddress());
        if (dto.getLatitude() != null) store.setLatitude(dto.getLatitude());
        if (dto.getLongitude() != null) store.setLongitude(dto.getLongitude());
        if (dto.getStoreStatus() != null) store.setStoreStatus(dto.getStoreStatus());
        if (dto.getContEndDt() != null) store.setContEndDt(dto.getContEndDt());
        if (dto.getAutoRenewalYn() != null) store.setAutoRenewalYn(dto.getAutoRenewalYn());
        if (dto.getStoreType() != null) store.setStoreType(dto.getStoreType());
        if (dto.getSvId() != null) store.setSvId(dto.getSvId());
        if (dto.getAdressDetail() != null) store.setAdressDetail(dto.getAdressDetail());
        if (dto.getZipCd() != null) store.setZipCd(dto.getZipCd());
        if (dto.getBrandCd() != null) store.setBrandCd(dto.getBrandCd());
        if (dto.getContStartDt() != null) store.setContStartDt(dto.getContStartDt());
        if (dto.getBusinessNumber() != null) store.setBusinessNumber(dto.getBusinessNumber());
        if (dto.getNotes() != null) store.setNotes(dto.getNotes());
        if (dto.getFirstContDt() != null) store.setFirstContDt(dto.getFirstContDt());
        if (dto.getFrFee() != null) store.setFrFee(dto.getFrFee());
        if (dto.getEduFee() != null) store.setEduFee(dto.getEduFee());
        if (dto.getInsuDeposit() != null) store.setInsuDeposit(dto.getInsuDeposit());
        if (dto.getContDeposit() != null) store.setContDeposit(dto.getContDeposit());
        if (dto.getContManager() != null) store.setContManager(dto.getContManager());
        if (dto.getEduManager() != null) store.setEduManager(dto.getEduManager());
        if (dto.getContArea() != null) store.setContArea(dto.getContArea());
        if (dto.getRealArea() != null) store.setRealArea(dto.getRealArea());
        if (dto.getFloor() != null) store.setFloor(dto.getFloor());
        if (dto.getParkingCount() != null) store.setParkingCount(dto.getParkingCount());
        if (dto.getPremiumFee() != null) store.setPremiumFee(dto.getPremiumFee());
        if (dto.getMonthlyRent() != null) store.setMonthlyRent(dto.getMonthlyRent());
        if (dto.getRentDeposit() != null) store.setRentDeposit(dto.getRentDeposit());
        Store updatedStore = storeRepository.save(store);
        saveHistory(updatedStore.getStoreIdx(), "UPDATE", updatedStore.getStoreNm(),
                String.format("가맹점 정보 수정: %s", updatedStore.getStoreNm()));
        
        log.info("가맹점 수정 완료: {}", updatedStore.getStoreCd());
        return toDto(updatedStore);
    }

    @Transactional
    public void deleteStore(Integer storeIdx) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));

        dropStoreHistoryForeignKeyIfExists();
        saveHistory(store.getStoreIdx(), "DELETE", store.getStoreNm(),
                String.format("가맹점 삭제: %s", store.getStoreNm()));
        storeRepository.delete(store);
        log.info("가맹점 삭제 완료: {}", storeIdx);
    }

    private void dropStoreHistoryForeignKeyIfExists() {
        jdbcTemplate.execute("alter table store_history drop constraint if exists fk_his_store_idx");
    }

    private void saveHistory(Integer storeIdx, String chgType, String storeNm, String content) {
        if (storeIdx == null) {
            log.warn("가맹점 히스토리 저장 건너뜀: storeIdx 없음, chgType={}, content={}", chgType, content);
            return;
        }
        jdbcTemplate.update(
                """
                insert into store_history (store_idx, chg_type, chg_user_id, store_nm, chg_content)
                values (?, ?, ?, ?, jsonb_build_array(jsonb_build_object(
                    'column_nm', 'store',
                    'column_desc', '가맹점',
                    'before_value', null,
                    'after_value', ?
                )))
                """,
                storeIdx,
                chgType,
                "system",
                storeNm,
                content);
    }

    public List<StoreResponseDto> searchStoresByName(String storeNm) {
        return storeRepository.findByStoreNmContaining(storeNm)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }
}
