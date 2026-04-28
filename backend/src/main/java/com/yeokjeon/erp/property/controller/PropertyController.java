package com.yeokjeon.erp.property.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.property.dto.PropertyRequestDto;
import com.yeokjeon.erp.property.dto.PropertyResponseDto;
import com.yeokjeon.erp.property.service.PropertyService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/properties")
@RequiredArgsConstructor
public class PropertyController {

    private final PropertyService propertyService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<PropertyResponseDto>>> getAllProperties() {
        log.info("물건 목록 조회 요청");
        return ResponseEntity.ok(ApiResponse.success(propertyService.getAllProperties()));
    }

    @GetMapping("/{propIdx}")
    public ResponseEntity<ApiResponse<PropertyResponseDto>> getProperty(@PathVariable Integer propIdx) {
        log.info("물건 상세 조회 요청: {}", propIdx);
        return ResponseEntity.ok(ApiResponse.success(propertyService.getProperty(propIdx)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<PropertyResponseDto>> createProperty(
            @Valid @RequestBody PropertyRequestDto dto) {
        log.info("물건 생성 요청: {}", dto.getPropNm());
        PropertyResponseDto created = propertyService.createProperty(dto);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("물건이 생성되었습니다", created));
    }

    @PutMapping("/{propIdx}")
    public ResponseEntity<ApiResponse<PropertyResponseDto>> updateProperty(
            @PathVariable Integer propIdx,
            @Valid @RequestBody PropertyRequestDto dto) {
        log.info("물건 수정 요청: {}", propIdx);
        PropertyResponseDto updated = propertyService.updateProperty(propIdx, dto);
        return ResponseEntity.ok(ApiResponse.success("물건이 수정되었습니다", updated));
    }

    @DeleteMapping("/{propIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteProperty(@PathVariable Integer propIdx) {
        log.info("물건 삭제 요청: {}", propIdx);
        propertyService.deleteProperty(propIdx);
        return ResponseEntity.ok(ApiResponse.success("물건이 삭제되었습니다", null));
    }
}
