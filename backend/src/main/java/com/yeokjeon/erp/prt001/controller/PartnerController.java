package com.yeokjeon.erp.prt001.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.prt001.service.PartnerService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/partners")
@RequiredArgsConstructor
public class PartnerController {

    private final PartnerService partnerService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getAllPartners() {
        log.info("예비창업자 목록 조회 요청");
        return ResponseEntity.ok(ApiResponse.success(partnerService.getAllPartners()));
    }

    @GetMapping("/{partnerIdx}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPartner(
            @PathVariable Integer partnerIdx) {
        log.info("예비창업자 상세 조회 요청: {}", partnerIdx);
        return ResponseEntity.ok(ApiResponse.success(partnerService.getPartner(partnerIdx)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> createPartner(
            @RequestBody Map<String, Object> body) {
        log.info("예비창업자 생성 요청: {}", body != null ? body.get("partnerNm") : null);
        Map<String, Object> created = partnerService.createPartner(body);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("예비창업자가 생성되었습니다", created));
    }

    @PutMapping("/{partnerIdx}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updatePartner(
            @PathVariable Integer partnerIdx,
            @RequestBody Map<String, Object> body) {
        log.info("예비창업자 수정 요청: {}", partnerIdx);
        Map<String, Object> updated = partnerService.updatePartner(partnerIdx, body);
        return ResponseEntity.ok(ApiResponse.success("예비창업자가 수정되었습니다", updated));
    }
}
