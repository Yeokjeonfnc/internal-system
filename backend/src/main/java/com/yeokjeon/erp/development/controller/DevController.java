package com.yeokjeon.erp.development.controller;

import com.yeokjeon.erp.auth.access.MenuAccessGuard;
import com.yeokjeon.erp.auth.access.MenuCodes;
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
import jakarta.servlet.http.HttpServletRequest;
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
    private final MenuAccessGuard menuAccessGuard;

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

    /*
     * 아래 3개는 예비창업자(가맹 상담 대상자) 원장을 만들고 바꾸고 지운다.
     * 담당자별로 나뉜 개인정보·상담 이력이라 권한 검사가 없으면 로그인한
     * 아무나 남의 담당 건을 고치거나 지울 수 있다. 예비창업자(dev001) 권한을 요구한다.
     */

    @PostMapping("/partners")
    public ResponseEntity<ApiResponse<PartnerMstDto>> partnerCreate(
            @RequestBody PartnerMstWriteRequestDto body, HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.DEV001, MenuAccessGuard.Action.CREATE);
        log.info("예비창업자 생성 요청: {}", body != null ? body.getPartnerNm() : null);
        PartnerMstDto created = devService.createPartner(body);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("예비창업자가 생성되었습니다", created));
    }

    @PutMapping("/partners/{partnerIdx}")
    public ResponseEntity<ApiResponse<PartnerMstDto>> partnerUpdate(
            @PathVariable Integer partnerIdx,
            @RequestBody PartnerMstWriteRequestDto body,
            HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.DEV001, MenuAccessGuard.Action.UPDATE);
        log.info("예비창업자 수정 요청: {}", partnerIdx);
        PartnerMstDto updated = devService.updatePartner(partnerIdx, body);
        return ResponseEntity.ok(ApiResponse.success("예비창업자가 수정되었습니다", updated));
    }

    @DeleteMapping("/partners/{partnerIdx}")
    public ResponseEntity<ApiResponse<Void>> partnerRemove(
            @PathVariable Integer partnerIdx, HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.DEV001, MenuAccessGuard.Action.DELETE);
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

    /*
     * 물건(출점 후보지) 원장의 생성·수정·삭제. 임대조건·계약금액 등 영업상 민감한
     * 정보이고 영업지역·가맹점 데이터가 여기에 물려 있어서, 권한 없는 사용자가
     * 손대면 남의 담당 물건이 조용히 바뀌거나 사라진다. 물건(dev002) 권한을 요구한다.
     */

    @PostMapping("/properties")
    public ResponseEntity<ApiResponse<PropertyMstDto>> propertyCreate(
            @RequestBody PropertyMstWriteRequestDto body, HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.DEV002, MenuAccessGuard.Action.CREATE);
        log.info("물건 생성 요청: {}", body != null ? body.getPropNm() : null);
        PropertyMstDto created = devService.createProperty(body);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("물건이 생성되었습니다", created));
    }

    @PutMapping("/properties/{propIdx}")
    public ResponseEntity<ApiResponse<PropertyMstDto>> propertyUpdate(
            @PathVariable Integer propIdx,
            @RequestBody PropertyMstWriteRequestDto body,
            HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.DEV002, MenuAccessGuard.Action.UPDATE);
        log.info("물건 수정 요청: {}", propIdx);
        PropertyMstDto updated = devService.updateProperty(propIdx, body);
        return ResponseEntity.ok(ApiResponse.success("물건이 수정되었습니다", updated));
    }

    @DeleteMapping("/properties/{propIdx}")
    public ResponseEntity<ApiResponse<Void>> propertyRemove(
            @PathVariable Integer propIdx, HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.DEV002, MenuAccessGuard.Action.DELETE);
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
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate attachmentBaseDate,
            HttpServletRequest request) {
        // 문서는 물건에 딸린 자료(계약서·등기부 등)라 물건 원장과 같은 권한으로 다룬다.
        // userId 파라미터는 AuthTokenFilter 가 사칭만 막을 뿐, 남의 물건에 파일을
        // 붙이는 것 자체는 걸러주지 못한다.
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.DEV002, MenuAccessGuard.Action.CREATE);
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
            @PathVariable Integer propertyDocIdx,
            HttpServletRequest request) {
        // 첨부 삭제는 되돌릴 수 없다(원본 파일까지 없어진다). 물건(dev002) 삭제 권한을 요구한다.
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.DEV002, MenuAccessGuard.Action.DELETE);
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

    /*
     * 아래 2개는 가맹점의 영업지역 경계·구역정보를 덮어쓴다(신규/기존 구분 없는 upsert라
     * UPDATE 로 본다). 영업지역은 가맹점 간 상권 분쟁의 기준이 되는 값이라, 권한 없는
     * 사용자가 남의 점포 경계선을 조용히 바꿔 놓으면 되돌리기 어렵다. 영업지역(dev003) 권한을 요구한다.
     */

    @PostMapping("/sales-areas/save")
    public ResponseEntity<ApiResponse<SalesAreaDto>> salesAreaSave(
            @RequestBody SalesAreaSaveRequest body, HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.DEV003, MenuAccessGuard.Action.UPDATE);
        log.info("영업지역 저장: storeIdx={}", body != null ? body.storeIdx() : null);
        SalesAreaDto saved = devService.saveSalesArea(body);
        return ResponseEntity.ok(ApiResponse.success("영업지역이 저장되었습니다", saved));
    }

    @PostMapping("/sales-areas/zone-info")
    public ResponseEntity<ApiResponse<SalesAreaDto>> salesAreaZoneInfoSave(
            @RequestBody SalesAreaZoneInfoSaveRequest body, HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.DEV003, MenuAccessGuard.Action.UPDATE);
        log.info("영업지역정보 저장: zoneIdx={}", body != null ? body.zoneIdx() : null);
        SalesAreaDto saved = devService.saveSalesAreaZoneInfo(body);
        return ResponseEntity.ok(ApiResponse.success("영업지역정보가 저장되었습니다", saved));
    }

}
