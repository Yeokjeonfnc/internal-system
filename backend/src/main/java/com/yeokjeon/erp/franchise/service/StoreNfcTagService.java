package com.yeokjeon.erp.franchise.service;

import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.franchise.dto.StoreNfcTagDto;
import com.yeokjeon.erp.franchise.dto.StoreNfcTagJdbcRow;
import com.yeokjeon.erp.franchise.dto.StoreNfcTagLookupDto;
import com.yeokjeon.erp.franchise.mapper.StoreNfcTagMapper;
import com.yeokjeon.erp.franchise.repository.StoreRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StoreNfcTagService {

    public static final int MAX_ENTRY_DISTANCE_M = 200;

    private final StoreRepository storeRepository;
    private final StoreNfcTagMapper storeNfcTagMapper;

    public StoreNfcTagDto findByStoreIdx(Integer storeIdx) {
        ensureStoreExists(storeIdx);
        StoreNfcTagJdbcRow row = storeNfcTagMapper.selectByStoreIdx(storeIdx);
        return row == null ? null : toDto(row);
    }

    public StoreNfcTagLookupDto lookupByTagUid(String rawTagUid) {
        String tagUid = normalizeTagUid(rawTagUid);
        if (!StringUtils.hasText(tagUid)) {
            throw new IllegalArgumentException("NFC 태그 UID를 확인할 수 없습니다.");
        }
        StoreNfcTagLookupDto found = storeNfcTagMapper.selectLookupByTagUid(tagUid);
        if (found == null) {
            throw new ResourceNotFoundException("NFC 태그", "tagUid", tagUid);
        }
        return found;
    }

    @Transactional
    public StoreNfcTagDto register(Integer storeIdx, String rawTagUid, String registeredBy) {
        ensureStoreExists(storeIdx);
        String tagUid = normalizeTagUid(rawTagUid);
        if (!StringUtils.hasText(tagUid)) {
            throw new IllegalArgumentException("NFC 태그 UID를 입력해 주세요.");
        }
        if (tagUid.length() < 8) {
            throw new IllegalArgumentException("NFC 태그 UID 형식이 올바르지 않습니다.");
        }

        StoreNfcTagJdbcRow existing = storeNfcTagMapper.selectByTagUid(tagUid);
        if (existing != null && !storeIdx.equals(existing.getStoreIdx())) {
            throw new IllegalArgumentException("이미 다른 가맹점에 등록된 NFC 태그입니다.");
        }

        String by = StringUtils.hasText(registeredBy) ? registeredBy.trim() : null;
        storeNfcTagMapper.upsert(storeIdx, tagUid, by);
        StoreNfcTagJdbcRow row = storeNfcTagMapper.selectByStoreIdx(storeIdx);
        return toDto(row);
    }

    @Transactional
    public void remove(Integer storeIdx) {
        ensureStoreExists(storeIdx);
        storeNfcTagMapper.deleteByStoreIdx(storeIdx);
    }

    public static String normalizeTagUid(String raw) {
        if (raw == null) {
            return "";
        }
        return raw.replace(":", "").replace("-", "").replace(" ", "").trim().toUpperCase();
    }

    private void ensureStoreExists(Integer storeIdx) {
        if (storeIdx == null || storeIdx <= 0) {
            throw new IllegalArgumentException("유효한 가맹점이 아닙니다.");
        }
        if (!storeRepository.existsById(storeIdx)) {
            throw new ResourceNotFoundException("가맹점", "storeIdx", storeIdx);
        }
    }

    private static StoreNfcTagDto toDto(StoreNfcTagJdbcRow row) {
        return new StoreNfcTagDto(
                row.getStoreIdx(),
                row.getTagUid(),
                row.getUseYn(),
                row.getRegisteredAt(),
                row.getRegisteredBy());
    }
}
