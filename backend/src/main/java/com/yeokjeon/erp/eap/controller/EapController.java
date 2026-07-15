package com.yeokjeon.erp.eap.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.eap.dto.EapConnectionTestResult;
import com.yeokjeon.erp.eap.dto.EapDocumentDto;
import com.yeokjeon.erp.eap.dto.EapDraftRequestDto;
import com.yeokjeon.erp.eap.dto.EapDraftResultDto;
import com.yeokjeon.erp.eap.dto.EapFormConfigDto;
import com.yeokjeon.erp.eap.dto.EapFormConfigSaveRequestDto;
import com.yeokjeon.erp.eap.dto.EapFormConfigUpdateRequestDto;
import com.yeokjeon.erp.eap.dto.EapStatusCallbackRequestDto;
import com.yeokjeon.erp.eap.service.EapConnectionService;
import com.yeokjeon.erp.eap.service.EapDocumentService;
import com.yeokjeon.erp.eap.service.EapFormConfigService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/eap")
@RequiredArgsConstructor
public class EapController {

    private final EapConnectionService eapConnectionService;
    private final EapFormConfigService eapFormConfigService;
    private final EapDocumentService eapDocumentService;

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Map<String, Object>>> health() {
        return ResponseEntity.ok(ApiResponse.success(
                "전자결재 API 정상",
                Map.of(
                        "service", "eap",
                        "status", "UP")));
    }

    @GetMapping("/connection-test")
    public ResponseEntity<ApiResponse<EapConnectionTestResult>> connectionTest() {
        log.info("전자결재 연동 테스트 요청");
        EapConnectionTestResult result = eapConnectionService.testConnection();
        String message = result.daouAuthOk()
                ? "ERP·다우오피스 연동 테스트 성공"
                : result.daouReachable()
                        ? "ERP 연결 OK — 다우오피스 설정 확인 필요"
                        : result.daouConfigured()
                                ? "ERP 연결 OK — 다우오피스 호출 실패"
                                : "ERP 연결 OK — 다우오피스 인증키 미설정";
        return ResponseEntity.ok(ApiResponse.success(message, result));
    }

    @GetMapping("/forms")
    public ResponseEntity<ApiResponse<List<EapFormConfigDto>>> listForms(
            @RequestParam(required = false, defaultValue = "false") boolean enabledOnly) {
        List<EapFormConfigDto> forms = enabledOnly
                ? eapFormConfigService.listEnabled()
                : eapFormConfigService.listAll();
        return ResponseEntity.ok(ApiResponse.success("양식 코드 목록", forms));
    }

    @PostMapping("/forms")
    public ResponseEntity<ApiResponse<EapFormConfigDto>> createForm(
            @Valid @RequestBody EapFormConfigSaveRequestDto body) {
        return ResponseEntity.ok(ApiResponse.success(
                "양식 코드가 등록되었습니다.", eapFormConfigService.create(body)));
    }

    @PutMapping("/forms/{formCode}")
    public ResponseEntity<ApiResponse<EapFormConfigDto>> updateForm(
            @PathVariable String formCode,
            @Valid @RequestBody EapFormConfigUpdateRequestDto body) {
        return ResponseEntity.ok(ApiResponse.success(
                "양식 코드가 수정되었습니다.", eapFormConfigService.update(formCode, body)));
    }

    @DeleteMapping("/forms/{formCode}")
    public ResponseEntity<ApiResponse<Void>> deleteForm(@PathVariable String formCode) {
        eapFormConfigService.delete(formCode);
        return ResponseEntity.ok(ApiResponse.success("양식 코드가 삭제되었습니다.", null));
    }

    @GetMapping("/documents")
    public ResponseEntity<ApiResponse<List<EapDocumentDto>>> listDocuments(
            @RequestParam(required = false, defaultValue = "drafted") String folder) {
        return ResponseEntity.ok(ApiResponse.success(
                "결재 문서 목록", eapDocumentService.listByFolder(folder)));
    }

    @GetMapping("/documents/{documentId}")
    public ResponseEntity<ApiResponse<EapDocumentDto>> getDocument(
            @PathVariable String documentId) {
        return ResponseEntity.ok(ApiResponse.success(
                "결재 문서 상세", eapDocumentService.findDocument(documentId)));
    }

    @PostMapping("/draft")
    public ResponseEntity<ApiResponse<EapDraftResultDto>> draft(
            @Valid @RequestBody EapDraftRequestDto body) {
        EapDraftResultDto result = eapDocumentService.draft(body);
        return ResponseEntity.ok(ApiResponse.success(result.message(), result));
    }

    /**
     * 다우「전자결재 처리상태 전송」콜백.
     * 응답은 다우 가이드 형식: {@code {"code":"200","message":"OK"}} (비 200 이면 다우 쪽 상태 이벤트가 취소될 수 있음).
     */
    @PostMapping("/status")
    public ResponseEntity<Map<String, String>> statusCallback(
            @RequestBody EapStatusCallbackRequestDto body) {
        try {
            eapDocumentService.applyStatusCallback(body);
        } catch (Exception e) {
            log.warn("다우 상태 콜백 처리 중 오류(응답은 200 유지): {}", e.toString());
        }
        return ResponseEntity.ok(Map.of("code", "200", "message", "OK"));
    }
}
