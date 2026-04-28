package com.yeokjeon.erp.partner.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.partner.dto.PartnerRequestDto;
import com.yeokjeon.erp.partner.dto.PartnerResponseDto;
import com.yeokjeon.erp.partner.service.PartnerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/partners")
@RequiredArgsConstructor
public class PartnerController {

    private final PartnerService partnerService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<PartnerResponseDto>>> getAllPartners() {
        log.info("예비창업자 목록 조회 요청");
        return ResponseEntity.ok(ApiResponse.success(partnerService.getAllPartners()));
    }

    @GetMapping("/{partnerIdx}")
    public ResponseEntity<ApiResponse<PartnerResponseDto>> getPartner(
            @PathVariable Integer partnerIdx) {
        log.info("예비창업자 상세 조회 요청: {}", partnerIdx);
        return ResponseEntity.ok(ApiResponse.success(partnerService.getPartner(partnerIdx)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<PartnerResponseDto>> createPartner(
            @Valid @RequestBody PartnerRequestDto dto) {
        log.info("예비창업자 생성 요청: {}", dto.getPartnerNm());
        PartnerResponseDto created = partnerService.createPartner(dto);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("예비창업자가 생성되었습니다", created));
    }

    @PutMapping("/{partnerIdx}")
    public ResponseEntity<ApiResponse<PartnerResponseDto>> updatePartner(
            @PathVariable Integer partnerIdx,
            @Valid @RequestBody PartnerRequestDto dto) {
        log.info("예비창업자 수정 요청: {}", partnerIdx);
        PartnerResponseDto updated = partnerService.updatePartner(partnerIdx, dto);
        return ResponseEntity.ok(ApiResponse.success("예비창업자가 수정되었습니다", updated));
    }
}
