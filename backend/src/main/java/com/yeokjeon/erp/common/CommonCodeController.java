package com.yeokjeon.erp.common;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/codes")
@RequiredArgsConstructor
public class CommonCodeController {

    private final CommonCodeService commonCodeService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getCodes(
            @RequestParam int grpCd) {
        log.info("공통 코드 조회 요청: grpCd={}", grpCd);
        return ResponseEntity.ok(ApiResponse.success(
                commonCodeService.getCodesByGroup(grpCd)));
    }
}
