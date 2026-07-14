package com.yeokjeon.erp.development.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.development.dto.PartnerMstDto;
import com.yeokjeon.erp.development.dto.PartnerMstWriteRequestDto;
import com.yeokjeon.erp.development.dto.PropertyDocumentDto;
import com.yeokjeon.erp.development.dto.PropertyMstDto;
import com.yeokjeon.erp.development.dto.PropertyMstWriteRequestDto;
import com.yeokjeon.erp.development.dto.SalesAreaDto;
import com.yeokjeon.erp.development.dto.SalesAreaMapPointDto;
import com.yeokjeon.erp.development.dto.SalesAreaSaveRequest;
import com.yeokjeon.erp.development.dto.SalesAreaZoneInfoSaveRequest;
import com.yeokjeon.erp.development.service.DevService;
import com.yeokjeon.erp.development.service.PropertyDocumentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;

/** 예비창업자·물건·영업지역(DEV003) — {@code /partners}, {@code /properties}, {@code GET|POST /sales-areas}. */
@Slf4j
@RestController
@RequiredArgsConstructor
public class DevController {

    private final DevService devService;
    private final PropertyDocumentService propertyDocumentService;

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

    @DeleteMapping("/partners/{partnerIdx}")
    public ResponseEntity<ApiResponse<Void>> partnerRemove(@PathVariable Integer partnerIdx) {
        log.info("예비창업자 삭제 요청: {}", partnerIdx);
        devService.removePartner(partnerIdx);
        return ResponseEntity.ok(ApiResponse.success("예비창업자가 삭제되었습니다", null));
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

    @GetMapping("/properties/{propIdx}/documents")
    public ResponseEntity<ApiResponse<List<PropertyDocumentDto>>> getPropertyDocuments(
            @PathVariable Integer propIdx) {
        log.info("물건 문서 목록 조회: {}", propIdx);
        return ResponseEntity.ok(ApiResponse.success(propertyDocumentService.list(propIdx)));
    }

    @PostMapping(value = "/properties/{propIdx}/documents", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<PropertyDocumentDto>> uploadPropertyDocument(
            @PathVariable Integer propIdx,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "userId", required = false) String userId,
            @RequestParam(value = "attachmentBaseDate", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate attachmentBaseDate) {
        log.info("물건 문서 업로드: propIdx={}, file={}", propIdx, file.getOriginalFilename());
        PropertyDocumentDto created = propertyDocumentService.upload(
                propIdx, file, userId, attachmentBaseDate);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("문서가 업로드되었습니다", created));
    }

    @GetMapping("/properties/{propIdx}/documents/{propertyDocIdx}/download")
    public ResponseEntity<org.springframework.core.io.Resource> downloadPropertyDocument(
            @PathVariable Integer propIdx,
            @PathVariable Integer propertyDocIdx) {
        PropertyDocumentService.DownloadPayload payload =
                propertyDocumentService.download(propIdx, propertyDocIdx);
        MediaType mediaType = MediaType.APPLICATION_OCTET_STREAM;
        if (payload.contentType() != null && !payload.contentType().isBlank()) {
            mediaType = MediaType.parseMediaType(payload.contentType());
        }
        ContentDisposition disposition = ContentDisposition.attachment()
                .filename(payload.fileName(), StandardCharsets.UTF_8)
                .build();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, disposition.toString())
                .contentType(mediaType)
                .body(payload.resource());
    }

    @DeleteMapping("/properties/{propIdx}/documents/{propertyDocIdx}")
    public ResponseEntity<ApiResponse<Void>> deletePropertyDocument(
            @PathVariable Integer propIdx,
            @PathVariable Integer propertyDocIdx) {
        log.info("물건 문서 삭제: propIdx={}, docIdx={}", propIdx, propertyDocIdx);
        propertyDocumentService.delete(propIdx, propertyDocIdx);
        return ResponseEntity.ok(ApiResponse.success("문서가 삭제되었습니다", null));
    }

    @GetMapping("/sales-areas")
    public ResponseEntity<ApiResponse<List<SalesAreaDto>>> salesAreasListGet() {
        log.info("영업지역 목록 조회 요청(GET)");
        return ResponseEntity.ok(ApiResponse.success(devService.listSalesAreas()));
    }

    @GetMapping("/sales-areas/map-points")
    public ResponseEntity<ApiResponse<List<SalesAreaMapPointDto>>> salesAreaMapPoints(
            @RequestParam(name = "includeGeometry", defaultValue = "false") boolean includeGeometry) {
        log.info("영업지역 지도 포인트 조회 (includeGeometry={})", includeGeometry);
        return ResponseEntity.ok(ApiResponse.success(devService.listSalesAreaMapPoints(includeGeometry)));
    }

    @GetMapping("/sales-areas/stores/{storeIdx}")
    public ResponseEntity<ApiResponse<SalesAreaDto>> salesAreaDetailByStore(
            @PathVariable Integer storeIdx) {
        log.info("영업지역 상세 조회(가맹점): storeIdx={}", storeIdx);
        return ResponseEntity.ok(ApiResponse.success(devService.salesAreaDetailByStore(storeIdx)));
    }

    @GetMapping("/sales-areas/zones/{zoneIdx}")
    public ResponseEntity<ApiResponse<SalesAreaDto>> salesAreaDetailByZone(
            @PathVariable Integer zoneIdx) {
        log.info("영업지역 상세 조회(구역): zoneIdx={}", zoneIdx);
        return ResponseEntity.ok(ApiResponse.success(devService.salesAreaDetailByZone(zoneIdx)));
    }

    @GetMapping("/sales-areas/properties/{propIdx}")
    public ResponseEntity<ApiResponse<SalesAreaDto>> salesAreaDetailByProperty(
            @PathVariable Integer propIdx) {
        log.info("영업지역 상세 조회(물건): propIdx={}", propIdx);
        return ResponseEntity.ok(ApiResponse.success(devService.salesAreaDetailByProperty(propIdx)));
    }

    @PostMapping("/sales-areas/save")
    public ResponseEntity<ApiResponse<SalesAreaDto>> salesAreaSave(
            @RequestBody SalesAreaSaveRequest body) {
        log.info("영업지역 저장: storeIdx={}", body != null ? body.storeIdx() : null);
        SalesAreaDto saved = devService.saveSalesArea(body);
        return ResponseEntity.ok(ApiResponse.success("영업지역이 저장되었습니다", saved));
    }

    @PostMapping("/sales-areas/zone-info")
    public ResponseEntity<ApiResponse<SalesAreaDto>> salesAreaZoneInfoSave(
            @RequestBody SalesAreaZoneInfoSaveRequest body) {
        log.info("영업지역정보 저장: zoneIdx={}", body != null ? body.zoneIdx() : null);
        SalesAreaDto saved = devService.saveSalesAreaZoneInfo(body);
        return ResponseEntity.ok(ApiResponse.success("영업지역정보가 저장되었습니다", saved));
    }

}
