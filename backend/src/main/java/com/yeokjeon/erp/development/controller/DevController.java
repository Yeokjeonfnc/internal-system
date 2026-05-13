package com.yeokjeon.erp.development.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.development.dto.PartnerMstDto;
import com.yeokjeon.erp.development.dto.PartnerMstWriteRequestDto;
import com.yeokjeon.erp.development.dto.PropertyMstDto;
import com.yeokjeon.erp.development.dto.PropertyMstWriteRequestDto;
import com.yeokjeon.erp.development.dto.SalesAreaDto;
import com.yeokjeon.erp.development.service.DevService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** 예비창업자·물건·영업지역(DEV003) — {@code /partners}, {@code /properties}, {@code GET|POST /sales-areas}. */
@Slf4j
@RestController
@RequiredArgsConstructor
public class DevController {

    private final DevService devService;

    @GetMapping("/partners")
    public ResponseEntity<ApiResponse<List<PartnerMstDto>>> partnersList() {
        log.info("예비창업자 목록 조회 요청");
        return ResponseEntity.ok(ApiResponse.success(devService.listPartners()));
    }

    @GetMapping("/partners/{partnerIdx}")
    public ResponseEntity<ApiResponse<PartnerMstDto>> partnerOne(
            @PathVariable Integer partnerIdx) {
        log.info("예비창업자 상세 조회 요청: {}", partnerIdx);
        return ResponseEntity.ok(ApiResponse.success(devService.onePartner(partnerIdx)));
    }

    @PostMapping("/partners")
    public ResponseEntity<ApiResponse<PartnerMstDto>> partnerCreate(
            @RequestBody PartnerMstWriteRequestDto body) {
        log.info("예비창업자 생성 요청: {}", body != null ? body.getPartnerNm() : null);
        PartnerMstDto created = devService.createPartner(body);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("예비창업자가 생성되었습니다", created));
    }

    @PutMapping("/partners/{partnerIdx}")
    public ResponseEntity<ApiResponse<PartnerMstDto>> partnerUpdate(
            @PathVariable Integer partnerIdx,
            @RequestBody PartnerMstWriteRequestDto body) {
        log.info("예비창업자 수정 요청: {}", partnerIdx);
        PartnerMstDto updated = devService.updatePartner(partnerIdx, body);
        return ResponseEntity.ok(ApiResponse.success("예비창업자가 수정되었습니다", updated));
    }

    @GetMapping("/properties")
    public ResponseEntity<ApiResponse<List<PropertyMstDto>>> propertiesList() {
        log.info("물건 목록 조회 요청");
        return ResponseEntity.ok(ApiResponse.success(devService.listProperties()));
    }

    @GetMapping("/properties/{propIdx}")
    public ResponseEntity<ApiResponse<PropertyMstDto>> propertyOne(@PathVariable Integer propIdx) {
        log.info("물건 상세 조회 요청: {}", propIdx);
        return ResponseEntity.ok(ApiResponse.success(devService.oneProperty(propIdx)));
    }

    @PostMapping("/properties")
    public ResponseEntity<ApiResponse<PropertyMstDto>> propertyCreate(
            @RequestBody PropertyMstWriteRequestDto body) {
        log.info("물건 생성 요청: {}", body != null ? body.getPropNm() : null);
        PropertyMstDto created = devService.createProperty(body);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("물건이 생성되었습니다", created));
    }

    @PutMapping("/properties/{propIdx}")
    public ResponseEntity<ApiResponse<PropertyMstDto>> propertyUpdate(
            @PathVariable Integer propIdx,
            @RequestBody PropertyMstWriteRequestDto body) {
        log.info("물건 수정 요청: {}", propIdx);
        PropertyMstDto updated = devService.updateProperty(propIdx, body);
        return ResponseEntity.ok(ApiResponse.success("물건이 수정되었습니다", updated));
    }

    @DeleteMapping("/properties/{propIdx}")
    public ResponseEntity<ApiResponse<Void>> propertyRemove(@PathVariable Integer propIdx) {
        log.info("물건 삭제 요청: {}", propIdx);
        devService.removeProperty(propIdx);
        return ResponseEntity.ok(ApiResponse.success("물건이 삭제되었습니다", null));
    }

    @GetMapping("/sales-areas")
    public ResponseEntity<ApiResponse<List<SalesAreaDto>>> salesAreasListGet() {
        log.info("영업지역 목록 조회 요청(GET)");
        return ResponseEntity.ok(ApiResponse.success(devService.listSalesAreas()));
    }

    @PostMapping("/sales-areas")
    public ResponseEntity<ApiResponse<List<SalesAreaDto>>> salesAreasListPost() {
        log.info("영업지역 목록 조회 요청(POST)");
        return ResponseEntity.ok(ApiResponse.success(devService.listSalesAreas()));
    }
}
