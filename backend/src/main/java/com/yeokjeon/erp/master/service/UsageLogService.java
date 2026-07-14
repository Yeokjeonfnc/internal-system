package com.yeokjeon.erp.master.service;

import com.yeokjeon.erp.auth.dto.AuthProfileRowDto;
import com.yeokjeon.erp.common.GeoDistance;
import com.yeokjeon.erp.franchise.dto.StoreNfcTagLookupDto;
import com.yeokjeon.erp.franchise.service.StoreNfcTagService;
import com.yeokjeon.erp.master.dto.UsageLogMenuRequestDto;
import com.yeokjeon.erp.master.dto.UsageLogRowDto;
import com.yeokjeon.erp.master.dto.UsageLogTagRequestDto;
import com.yeokjeon.erp.master.mapper.UsageLogMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class UsageLogService {

    private final UsageLogMapper usageLogMapper;
    private final StoreNfcTagService storeNfcTagService;

    @Transactional
    public void recordLogin(AuthProfileRowDto row) {
        if (row == null) {
            return;
        }
        try {
            usageLogMapper.insertLogin(
                    row.userId(),
                    row.userNm(),
                    row.deptNm(),
                    row.positionNm(),
                    normalizeSvYn(row.svYn()));
        } catch (Exception e) {
            log.warn("로그인 사용기록 저장 실패: userId={}, {}", row.userId(), e.getMessage());
        }
    }

    @Transactional
    public void recordMenu(UsageLogMenuRequestDto body) {
        if (body == null || !StringUtils.hasText(body.userId())) {
            return;
        }
        final String label = body.menuLabel().trim();
        if (!StringUtils.hasText(label)) {
            return;
        }
        final String detail = "{" + label + "} 메뉴를 사용하였습니다.";
        try {
            usageLogMapper.insertMenu(
                    body.userId().trim(),
                    body.userNm().trim(),
                    body.deptNm(),
                    body.positionNm(),
                    normalizeSvYn(body.svYn()),
                    body.menuCd(),
                    detail);
        } catch (Exception e) {
            log.warn("메뉴 사용기록 저장 실패: userId={}, {}", body.userId(), e.getMessage());
        }
    }

    @Transactional
    public void recordTag(UsageLogTagRequestDto body) {
        if (body == null || !StringUtils.hasText(body.userId())) {
            throw new IllegalArgumentException("사용자 정보가 없습니다.");
        }
        final String storeNm = body.storeNm().trim();
        if (!StringUtils.hasText(storeNm)) {
            throw new IllegalArgumentException("가맹점명이 없습니다.");
        }

        final String tagUid = StoreNfcTagService.normalizeTagUid(body.tagUid());
        if (!StringUtils.hasText(tagUid)) {
            throw new IllegalArgumentException("NFC 태그 UID를 확인할 수 없습니다.");
        }

        final StoreNfcTagLookupDto tagStore = storeNfcTagService.lookupByTagUid(tagUid);
        if (!body.storeIdx().equals(tagStore.storeIdx())) {
            throw new IllegalArgumentException("등록된 NFC 태그와 가맹점이 일치하지 않습니다.");
        }

        final BigDecimal storeLat = tagStore.latitude();
        final BigDecimal storeLng = tagStore.longitude();
        if (storeLat == null || storeLng == null) {
            throw new IllegalArgumentException("가맹점 좌표가 등록되어 있지 않습니다.");
        }

        final int distanceM = GeoDistance.haversineMeters(
                body.lat(),
                body.lng(),
                storeLat.doubleValue(),
                storeLng.doubleValue());
        if (distanceM > StoreNfcTagService.MAX_ENTRY_DISTANCE_M) {
            throw new IllegalArgumentException(
                    "현재 위치가 매장과 일치하지 않습니다. 위치 재검색 후 다시 태그해 주세요.");
        }

        final String addr = body.address() == null ? "" : body.address().trim();
        final String detail = String.format(
                "{%s} 가맹점 출입 태그 (storeIdx=%d, 거리=%dm%s)",
                storeNm,
                body.storeIdx(),
                distanceM,
                addr.isEmpty() ? "" : ", " + addr);

        usageLogMapper.insertTag(
                body.userId().trim(),
                body.userNm().trim(),
                body.deptNm(),
                body.positionNm(),
                normalizeSvYn(body.svYn()),
                "str_entry",
                detail,
                body.storeIdx(),
                tagUid,
                body.lat(),
                body.lng(),
                distanceM);
    }

    public List<UsageLogRowDto> list(
            String userNm,
            String useType,
            String tab,
            LocalDate startDt,
            LocalDate endDt) {
        final String normalizedTab = tab == null ? "ALL" : tab.trim().toUpperCase();
        final boolean publicOnly = "PUBLIC".equals(normalizedTab);
        String effectiveUseType = useType;
        if ("LOGIN".equals(normalizedTab)) {
            effectiveUseType = "LOGIN";
        }
        return usageLogMapper.selectList(
                trimToNull(userNm),
                trimToNull(effectiveUseType),
                publicOnly,
                startDt,
                endDt);
    }

    public List<UsageLogRowDto> listEntryTagsForActivity(
            String userId, Integer storeIdx, boolean unlinkedOnly) {
        if (!StringUtils.hasText(userId)) {
            throw new IllegalArgumentException("userId는 필수입니다.");
        }
        if (storeIdx == null || storeIdx <= 0) {
            throw new IllegalArgumentException("storeIdx는 필수입니다.");
        }
        return usageLogMapper.selectEntryTagsForActivity(
                userId.trim(), storeIdx, unlinkedOnly);
    }

    private static String normalizeSvYn(String svYn) {
        return "Y".equalsIgnoreCase(StringUtils.trimWhitespace(svYn)) ? "Y" : "N";
    }

    private static String trimToNull(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        return value.trim();
    }
}
