package com.yeokjeon.erp.prp001.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.prp001.service.PropertyService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/properties")
@RequiredArgsConstructor
public class PropertyController {

    private final PropertyService propertyService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getAllProperties() {
        log.info("물건 목록 조회 요청");
        return ResponseEntity.ok(ApiResponse.success(propertyService.getAllProperties()));
    }

    @GetMapping("/{propIdx}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getProperty(@PathVariable Integer propIdx) {
        log.info("물건 상세 조회 요청: {}", propIdx);
        return ResponseEntity.ok(ApiResponse.success(propertyService.getProperty(propIdx)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> createProperty(
            @RequestBody Map<String, Object> body) {
        log.info("물건 생성 요청: {}", body != null ? body.get("propNm") : null);
        Map<String, Object> created = propertyService.createProperty(body);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("물건이 생성되었습니다", created));
    }

    @PutMapping("/{propIdx}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateProperty(
            @PathVariable Integer propIdx,
            @RequestBody Map<String, Object> body) {
        log.info("물건 수정 요청: {}", propIdx);
        Map<String, Object> updated = propertyService.updateProperty(propIdx, body);
        return ResponseEntity.ok(ApiResponse.success("물건이 수정되었습니다", updated));
    }

    @DeleteMapping("/{propIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteProperty(@PathVariable Integer propIdx) {
        log.info("물건 삭제 요청: {}", propIdx);
        propertyService.deleteProperty(propIdx);
        return ResponseEntity.ok(ApiResponse.success("물건이 삭제되었습니다", null));
    }
}
