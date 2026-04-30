package com.yeokjeon.erp.checklist.controller;

import com.yeokjeon.erp.checklist.dto.ChecklistRequestDto;
import com.yeokjeon.erp.checklist.dto.ChecklistResponseDto;
import com.yeokjeon.erp.checklist.service.ChecklistService;
import com.yeokjeon.erp.common.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/checklists")
@RequiredArgsConstructor
public class ChecklistController {

    private final ChecklistService checklistService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<ChecklistResponseDto>>> getChecklists(
            @RequestParam(required = false) String brandCd,
            @RequestParam(required = false) String chkType) {
        log.info("체크리스트 목록 조회 요청: brandCd={}, chkType={}", brandCd, chkType);
        return ResponseEntity.ok(ApiResponse.success(
                checklistService.getChecklists(brandCd, chkType)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ChecklistResponseDto>> createChecklist(
            @Valid @RequestBody ChecklistRequestDto dto) {
        log.info("체크리스트 등록 요청: brandCd={}, chkType={}", dto.getBrandCd(), dto.getChkType());
        ChecklistResponseDto created = checklistService.createChecklist(dto);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("체크리스트가 등록되었습니다", created));
    }

    @PutMapping("/{chkIdx}")
    public ResponseEntity<ApiResponse<ChecklistResponseDto>> updateChecklist(
            @PathVariable Integer chkIdx,
            @Valid @RequestBody ChecklistRequestDto dto) {
        log.info("체크리스트 수정 요청: chkIdx={}, brandCd={}, chkType={}", chkIdx, dto.getBrandCd(), dto.getChkType());
        ChecklistResponseDto updated = checklistService.updateChecklist(chkIdx, dto);
        return ResponseEntity.ok(ApiResponse.success("체크리스트가 수정되었습니다", updated));
    }
}
