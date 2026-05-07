package com.yeokjeon.erp.mck001.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.mck001.service.ChecklistService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/checklists")
@RequiredArgsConstructor
public class ChecklistController {

    private final ChecklistService checklistService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getChecklists(
            @RequestParam(required = false) String brandCd,
            @RequestParam(required = false) String chkType) {
        return ResponseEntity.ok(ApiResponse.success(
                checklistService.getChecklists(brandCd, chkType)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> createChecklist(
            @RequestBody Map<String, Object> body) {
        Map<String, Object> created = checklistService.createChecklist(body);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success(created));
    }

    @PutMapping("/{chkIdx}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateChecklist(
            @PathVariable Integer chkIdx,
            @RequestBody Map<String, Object> body) {
        Map<String, Object> updated = checklistService.updateChecklist(chkIdx, body);
        return ResponseEntity.ok(ApiResponse.success(updated));
    }
}
