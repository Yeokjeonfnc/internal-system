package com.yeokjeon.erp.eap.controller;

import com.yeokjeon.erp.auth.access.MenuAccessGuard;
import com.yeokjeon.erp.auth.access.MenuCodes;
import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.eap.dto.EapConnectionTestResult;
import com.yeokjeon.erp.eap.service.EapConnectionService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/eap")
@RequiredArgsConstructor
public class EapController {

    private final EapConnectionService eapConnectionService;
    private final MenuAccessGuard menuAccessGuard;

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Map<String, Object>>> health() {
        return ResponseEntity.ok(ApiResponse.success(
                "전자결재 API 정상",
                Map.of(
                        "service", "eap",
                        "status", "UP")));
    }

    /**
     * 응답에 내부 바인드 주소·콜백 경로·결재 양식 코드·인증키 설정 여부(=필요한 환경변수 이름)가
     * 그대로 실린다. 로그인만 하면 누구나(가맹점주 포함) 볼 수 있으면 정찰 정보가 되므로
     * 전자결재 메뉴 조회 권한을 가진 사람만 호출할 수 있게 한다.
     */
    @GetMapping("/connection-test")
    public ResponseEntity<ApiResponse<EapConnectionTestResult>> connectionTest(
            HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.EAP001, MenuAccessGuard.Action.VIEW);
        log.info("전자결재 연동 테스트 요청");
        EapConnectionTestResult result = eapConnectionService.testConnection();
        // 연결 확인은 조회만 하므로(기안 API 를 부르면 결재문서가 실제로 생성된다)
        // 인증키가 맞는지는 판정할 수 없다 — 도달 여부·설정 여부까지만 알린다.
        String message = result.daouReachable()
                ? "ERP 연결 OK — 다우오피스 주소 연결 정상"
                : result.daouConfigured()
                        ? "ERP 연결 OK — 다우오피스 호출 실패"
                        : "ERP 연결 OK — 다우오피스 인증키 미설정";
        return ResponseEntity.ok(ApiResponse.success(message, result));
    }
}
