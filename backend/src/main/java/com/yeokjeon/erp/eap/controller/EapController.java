package com.yeokjeon.erp.eap.controller;

import com.yeokjeon.erp.auth.access.MenuAccessGuard;
import com.yeokjeon.erp.auth.access.MenuCodes;
import com.yeokjeon.erp.auth.token.AuthTokenFilter;
import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.eap.dto.EapDocumentDto;
import com.yeokjeon.erp.eap.dto.EapDraftRequestDto;
import com.yeokjeon.erp.eap.dto.EapDraftResultDto;
import com.yeokjeon.erp.eap.dto.EapFormConfigDto;
import com.yeokjeon.erp.eap.dto.EapFormConfigSaveRequestDto;
import com.yeokjeon.erp.eap.dto.EapFormConfigUpdateRequestDto;
import com.yeokjeon.erp.eap.service.EapDocumentService;
import com.yeokjeon.erp.eap.service.EapFormConfigService;
import jakarta.servlet.http.HttpServletRequest;
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

    private final EapFormConfigService eapFormConfigService;
    private final EapDocumentService eapDocumentService;
    private final MenuAccessGuard menuAccessGuard;

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Map<String, Object>>> health() {
        return ResponseEntity.ok(ApiResponse.success(
                "전자결재 API 정상",
                Map.of(
                        "service", "eap",
                        "status", "UP")));
    }

    @GetMapping("/forms")
    public ResponseEntity<ApiResponse<List<EapFormConfigDto>>> listForms(
            HttpServletRequest request,
            @RequestParam(required = false, defaultValue = "false") boolean enabledOnly) {
        // 전체 목록은 서식관리(mst007). 기안용 사용중 목록은 전자결재 조회만 있으면 된다.
        if (!enabledOnly) {
            menuAccessGuard.ensure(
                    callerId(request), MenuCodes.MST007, MenuAccessGuard.Action.VIEW);
        }
        List<EapFormConfigDto> forms = enabledOnly
                ? eapFormConfigService.listEnabled()
                : eapFormConfigService.listAll();
        return ResponseEntity.ok(ApiResponse.success("양식 코드 목록", forms));
    }

    @PostMapping("/forms")
    public ResponseEntity<ApiResponse<EapFormConfigDto>> createForm(
            HttpServletRequest request,
            @Valid @RequestBody EapFormConfigSaveRequestDto body) {
        menuAccessGuard.ensure(
                callerId(request), MenuCodes.MST007, MenuAccessGuard.Action.CREATE);
        return ResponseEntity.ok(ApiResponse.success(
                "양식 코드가 등록되었습니다.", eapFormConfigService.create(body)));
    }

    @PutMapping("/forms/{formCode}")
    public ResponseEntity<ApiResponse<EapFormConfigDto>> updateForm(
            HttpServletRequest request,
            @PathVariable String formCode,
            @Valid @RequestBody EapFormConfigUpdateRequestDto body) {
        menuAccessGuard.ensure(
                callerId(request), MenuCodes.MST007, MenuAccessGuard.Action.UPDATE);
        return ResponseEntity.ok(ApiResponse.success(
                "양식 코드가 수정되었습니다.", eapFormConfigService.update(formCode, body)));
    }

    @GetMapping("/forms/{formCode}")
    public ResponseEntity<ApiResponse<EapFormConfigDto>> getForm(@PathVariable String formCode) {
        return ResponseEntity.ok(ApiResponse.success(
                "양식 상세", eapFormConfigService.find(formCode)));
    }

    @DeleteMapping("/forms/{formCode}")
    public ResponseEntity<ApiResponse<Void>> deleteForm(
            @PathVariable String formCode, HttpServletRequest request) {
        // 서식 삭제는 user_mst.admin_yn = 'Y' 인 슈퍼관리자만 허용한다.
        menuAccessGuard.ensureSuperAdmin(callerId(request));
        eapFormConfigService.delete(formCode);
        return ResponseEntity.ok(ApiResponse.success("양식 코드가 삭제되었습니다.", null));
    }

    @GetMapping("/documents")
    public ResponseEntity<ApiResponse<List<EapDocumentDto>>> listDocuments(
            HttpServletRequest request,
            @RequestParam(required = false, defaultValue = "inbox-pending") String folder) {
        String uid = callerId(request);
        log.info("전자결재 목록 조회: folder={}, userId={}", folder, uid);
        return ResponseEntity.ok(ApiResponse.success(
                "결재 문서 목록", eapDocumentService.listByFolder(folder, uid)));
    }

    @DeleteMapping("/documents/{documentId}")
    public ResponseEntity<ApiResponse<Void>> deleteDocument(
            HttpServletRequest request,
            @PathVariable String documentId) {
        menuAccessGuard.ensureSuperAdmin(callerId(request));
        eapDocumentService.deleteDocument(documentId, callerId(request));
        return ResponseEntity.ok(ApiResponse.success("결재 문서가 삭제되었습니다.", null));
    }

    @GetMapping("/documents/{documentId}")
    public ResponseEntity<ApiResponse<EapDocumentDto>> getDocument(
            HttpServletRequest request,
            @PathVariable String documentId) {
        return ResponseEntity.ok(ApiResponse.success(
                "결재 문서 상세", eapDocumentService.findDocument(documentId, callerId(request))));
    }

    @PostMapping("/documents/{documentId}/approve")
    public ResponseEntity<ApiResponse<EapDocumentDto>> approve(
            HttpServletRequest request,
            @PathVariable String documentId) {
        return ResponseEntity.ok(ApiResponse.success(
                "결재했습니다.", eapDocumentService.approve(documentId, callerId(request))));
    }

    @PostMapping("/documents/{documentId}/reject")
    public ResponseEntity<ApiResponse<EapDocumentDto>> reject(
            HttpServletRequest request,
            @PathVariable String documentId) {
        return ResponseEntity.ok(ApiResponse.success(
                "반려했습니다.", eapDocumentService.reject(documentId, callerId(request))));
    }

    @PostMapping("/draft")
    public ResponseEntity<ApiResponse<EapDraftResultDto>> draft(
            HttpServletRequest request,
            @Valid @RequestBody EapDraftRequestDto body) {
        EapDraftResultDto result = eapDocumentService.draft(body, callerId(request));
        return ResponseEntity.ok(ApiResponse.success(result.message(), result));
    }

    private static String callerId(HttpServletRequest request) {
        Object v = request.getAttribute(AuthTokenFilter.ATTR_CURRENT_USER_ID);
        return v == null ? "" : v.toString();
    }
}
