package com.yeokjeon.erp.master.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.master.dto.OwnerUserMstCreateRequestDto;
import com.yeokjeon.erp.master.dto.OwnerUserMstDto;
import com.yeokjeon.erp.master.dto.OwnerUserMstUpdateRequestDto;
import com.yeokjeon.erp.master.service.OwnerUserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** 가맹점주 — `/owner-users`. */
@RestController
@RequestMapping("/owner-users")
@RequiredArgsConstructor
public class OwnerUserController {

    private final OwnerUserService ownerUserService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<OwnerUserMstDto>>> list() {
        return ResponseEntity.ok(ApiResponse.success(ownerUserService.getAll()));
    }

    @GetMapping("/{userIdx}")
    public ResponseEntity<ApiResponse<OwnerUserMstDto>> one(@PathVariable Integer userIdx) {
        return ResponseEntity.ok(ApiResponse.success(ownerUserService.get(userIdx)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<OwnerUserMstDto>> create(
            @Valid @RequestBody OwnerUserMstCreateRequestDto body) {
        OwnerUserMstDto created = ownerUserService.save(body);
        return ResponseEntity.ok(ApiResponse.success("가맹점주가 등록되었습니다.", created));
    }

    @PutMapping("/{userIdx}")
    public ResponseEntity<ApiResponse<OwnerUserMstDto>> update(
            @PathVariable Integer userIdx,
            @RequestBody OwnerUserMstUpdateRequestDto body) {
        OwnerUserMstDto updated = ownerUserService.save(userIdx, body);
        return ResponseEntity.ok(ApiResponse.success("가맹점주 정보가 수정되었습니다.", updated));
    }

    @DeleteMapping("/{userIdx}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Integer userIdx) {
        ownerUserService.remove(userIdx);
        return ResponseEntity.ok(ApiResponse.success("가맹점주가 삭제되었습니다.", null));
    }
}
