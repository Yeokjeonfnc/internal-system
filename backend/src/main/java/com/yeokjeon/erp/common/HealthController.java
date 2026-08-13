package com.yeokjeon.erp.common;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 운영 스크립트(health-check.ps1 / status.ps1)용 상태 확인 엔드포인트.
 *
 * <p>인증 없이 호출할 수 있는 유일한 조회 엔드포인트다. 업무 데이터를 노출하지 않도록
 * 살아있다는 사실만 응답한다.
 */
@RestController
public class HealthController {

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<String>> health() {
        return ResponseEntity.ok(ApiResponse.success("OK"));
    }
}
