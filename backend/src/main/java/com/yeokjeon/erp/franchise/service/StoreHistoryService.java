package com.yeokjeon.erp.franchise.service;

import com.yeokjeon.erp.franchise.mapper.StoreHistoryMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class StoreHistoryService {

    private static final String CHG_TYPE_ACTIVE = "active";

    private final StoreHistoryMapper storeHistoryMapper;

    /**
     * 활동관리 결재 완료(APPROVED) 시 가맹점 히스토리에 방문 기록을 남긴다.
     */
    public void recordActivityVisitOnApproval(
            Integer storeIdx,
            String storeNm,
            String svDisplayName,
            LocalDateTime apprDt) {
        if (storeIdx == null || storeIdx <= 0) {
            return;
        }
        String label = StringUtils.hasText(svDisplayName) ? svDisplayName.trim() : "system";
        String summaryText = label + " 방문";
        LocalDateTime chgDt = apprDt != null ? apprDt : LocalDateTime.now();

        storeHistoryMapper.insertHistoryActive(
                storeIdx,
                CHG_TYPE_ACTIVE,
                label,
                storeNm,
                summaryText,
                chgDt);
        log.info("가맹점 활동 히스토리 저장: storeIdx={}, chgType={}, summary={}", storeIdx, CHG_TYPE_ACTIVE, summaryText);
    }
}
