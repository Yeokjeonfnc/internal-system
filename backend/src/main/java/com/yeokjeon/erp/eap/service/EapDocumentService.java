package com.yeokjeon.erp.eap.service;

import com.yeokjeon.erp.eap.config.DaouOfficeProperties;
import com.yeokjeon.erp.eap.dto.EapApprovalMappingInsertParam;
import com.yeokjeon.erp.eap.dto.EapApprovalMappingJdbcRow;
import com.yeokjeon.erp.eap.dto.EapDocumentDto;
import com.yeokjeon.erp.eap.dto.EapDraftRequestDto;
import com.yeokjeon.erp.eap.dto.EapDraftResultDto;
import com.yeokjeon.erp.eap.dto.EapFormConfigJdbcRow;
import com.yeokjeon.erp.eap.dto.EapStatusCallbackRequestDto;
import com.yeokjeon.erp.eap.mapper.EapApprovalMappingMapper;
import com.yeokjeon.erp.eap.mapper.EapFormConfigMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URI;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class EapDocumentService {

    private static final Duration TIMEOUT = Duration.ofSeconds(20);

    private final EapApprovalMappingMapper approvalMappingMapper;
    private final EapFormConfigMapper formConfigMapper;
    private final DaouOfficeProperties daouOfficeProperties;

    @Transactional(readOnly = true)
    public List<EapDocumentDto> listByFolder(String folder) {
        String key = folder == null ? "" : folder.trim().toLowerCase(Locale.ROOT);
        return approvalMappingMapper.selectByFolder(key).stream()
                .map(EapDocumentDto::fromRow)
                .toList();
    }

    @Transactional(readOnly = true)
    public EapDocumentDto findDocument(String documentId) {
        EapApprovalMappingJdbcRow row = approvalMappingMapper.selectByDocumentId(documentId);
        if (row == null && documentId != null && documentId.startsWith("MAP-")) {
            try {
                long id = Long.parseLong(documentId.substring(4));
                row = approvalMappingMapper.selectById(id);
            } catch (NumberFormatException ignored) {
                // fall through
            }
        }
        if (row == null) {
            throw new IllegalArgumentException("결재 문서를 찾을 수 없습니다: " + documentId);
        }
        // 저장된 연동 HTML 우선 — 없으면 최소 메타 HTML
        String stored = row.contentHtml();
        if (stored == null || stored.isBlank()) {
            stored = buildSimpleHtml(
                    row.title() == null ? "" : row.title(),
                    row.formName(),
                    row.erpMenuId(),
                    row.erpSourceId());
        }
        return EapDocumentDto.fromRow(row, stored);
    }

    @Transactional
    public EapDraftResultDto draft(EapDraftRequestDto body) {
        EapFormConfigJdbcRow form = formConfigMapper.selectByCode(body.formCode().trim());
        if (form == null) {
            throw new IllegalArgumentException("등록되지 않은 양식 코드입니다: " + body.formCode());
        }
        if (Boolean.FALSE.equals(form.enabled())) {
            throw new IllegalArgumentException("사용 중지된 양식입니다: " + body.formCode());
        }

        String erpMenuId = blankTo(body.erpMenuId(), blankTo(form.erpSourceMenu(), "eap001"));
        String title = body.title().trim();
        Long mappingId = body.mappingId();
        String erpSourceId;
        boolean isUpdate = mappingId != null && mappingId > 0;

        if (isUpdate) {
            EapApprovalMappingJdbcRow existing = approvalMappingMapper.selectById(mappingId);
            if (existing == null) {
                throw new IllegalArgumentException("수정할 결재 문서를 찾을 수 없습니다: " + mappingId);
            }
            String st = existing.status() == null ? "" : existing.status().trim().toUpperCase(Locale.ROOT);
            if (!"WRITING".equals(st)) {
                throw new IllegalArgumentException("작성중 문서만 수정·재기안할 수 있습니다. 현재 상태: " + existing.status());
            }
            erpSourceId = blankTo(existing.erpSourceId(), blankTo(body.erpSourceId(), "TMP-" + mappingId));
            String content = normalizeDaouContent(
                    blankTo(body.contentHtml(), buildSimpleHtml(title, form.formName(), erpMenuId, erpSourceId)));
            int updated = approvalMappingMapper.updateDraftContent(mappingId, title, content);
            if (updated == 0) {
                throw new IllegalStateException("작성중 문서 수정에 실패했습니다. 상태가 변경되었을 수 있습니다.");
            }
            return submitDaouAfterSave(mappingId, form, title, content, body.draftUserId(), true);
        }

        erpSourceId = blankTo(body.erpSourceId(), "TMP-" + UUID.randomUUID().toString().substring(0, 8));
        String content = normalizeDaouContent(
                blankTo(body.contentHtml(), buildSimpleHtml(title, form.formName(), erpMenuId, erpSourceId)));

        EapApprovalMappingInsertParam param = new EapApprovalMappingInsertParam();
        param.setErpMenuId(erpMenuId);
        param.setErpSourceId(erpSourceId);
        param.setDaouFormCode(form.formCode());
        // 다우 화면만 연 상태 — 임시저장/결재요청 전은 작성중
        param.setStatus("WRITING");
        param.setDraftUserId(body.draftUserId());
        param.setTitle(title);
        param.setContentHtml(content);
        approvalMappingMapper.insert(param);
        mappingId = param.getId();

        return submitDaouAfterSave(mappingId, form, title, content, body.draftUserId(), false);
    }

    private EapDraftResultDto submitDaouAfterSave(
            Long mappingId,
            EapFormConfigJdbcRow form,
            String title,
            String content,
            String draftUserId,
            boolean revised) {
        String revisePrefix = revised ? "수정·재기안: " : "";
        if (!daouOfficeProperties.isCredentialConfigured()) {
            String placeholderDocId = "LOCAL-" + mappingId;
            approvalMappingMapper.updateDaouDocument(mappingId, placeholderDocId, "WRITING");
            return new EapDraftResultDto(
                    mappingId,
                    placeholderDocId,
                    form.formCode(),
                    "WRITING",
                    title,
                    false,
                    revisePrefix + "다우 인증키가 없어 ERP 매핑만 저장했습니다. DAOU_CLIENT_ID/SECRET 설정 후 재기안하세요.",
                    null);
        }

        try {
            log.info(
                    "다우 기안 준비 formCode={} mappingId={} revised={} titleLen={} contentLen={}",
                    form.formCode(),
                    mappingId,
                    revised,
                    title.length(),
                    content.length());
            DaouSubmitResult submit = submitToDaou(
                    form.formCode(),
                    title,
                    content,
                    blankTo(draftUserId, null),
                    "ERP-" + mappingId);
            String status = submit.ok() ? "WRITING" : "DRAFT";
            String docId = submit.documentId() != null
                    ? submit.documentId()
                    : (submit.ok() ? "ERP-" + mappingId : "PENDING-" + mappingId);
            approvalMappingMapper.updateDaouDocument(mappingId, docId, status);
            String msg = submit.message();
            if (revised && (msg == null || msg.isBlank())) {
                msg = submit.ok() ? "수정 내용을 반영해 다우 기안 화면을 열었습니다." : "수정은 저장됐으나 다우 기안에 실패했습니다.";
            } else if (revised && msg != null && !msg.isBlank()) {
                msg = revisePrefix + msg;
            }
            return new EapDraftResultDto(
                    mappingId,
                    docId,
                    form.formCode(),
                    status,
                    title,
                    submit.ok(),
                    msg,
                    submit.redirectUrl());
        } catch (Exception e) {
            log.warn("다우 기안 호출 실패 mappingId={}", mappingId, e);
            String fallbackId = "ERR-" + mappingId;
            approvalMappingMapper.updateDaouDocument(mappingId, fallbackId, "DRAFT");
            return new EapDraftResultDto(
                    mappingId,
                    fallbackId,
                    form.formCode(),
                    "DRAFT",
                    title,
                    false,
                    revisePrefix + "다우 기안 호출 실패: " + e.getMessage(),
                    null);
        }
    }

    /**
     * 다우「전자결재 처리상태 전송」콜백.
     * HTTP 200 + {@code {"code":"200","message":"OK"}} 을 기대하므로,
     * 매핑 미발견이어도 호출부에서 성공 응답을 유지한다(여기선 warn 만).
     */
    @Transactional
    public void applyStatusCallback(EapStatusCallbackRequestDto body) {
        String docId = body.resolveDocId();
        String statusCode = body.resolveStatusCode();
        String partnerDocId = body.resolvePartnerDocId();
        String normalized = normalizeStatus(statusCode);

        if (statusCode == null || statusCode.isBlank()) {
            log.warn("다우 상태 콜백: docStatusCode 없음 body={}", body);
            return;
        }

        log.info(
                "다우 상태 콜백 docId={} docNum={} status={}({}) partnerDocId={} alliance={}",
                docId,
                body.docNum(),
                normalized,
                body.docStatusName(),
                partnerDocId,
                body.allianceInfo());

        int updated = 0;
        // 1) 실제 docId 로 조회·갱신 (콜백의 정식 키)
        if (docId != null && !docId.isBlank()) {
            updated = approvalMappingMapper.updateStatusByLookup(docId, normalized, docId);
        }
        // 2) 기안 시 보낸 partnerDocId (ERP-{mappingId}) — SQL CONCAT 대신 id 직접 파싱
        if (updated == 0 && partnerDocId != null && !partnerDocId.isBlank()) {
            updated = updateByPartnerDocId(partnerDocId, normalized, docId);
            if (updated == 0) {
                updated = approvalMappingMapper.updateStatusByLookup(
                        partnerDocId, normalized, docId);
            }
        }
        // 3) 레거시: daou_document_id 만 갱신
        if (updated == 0 && docId != null && !docId.isBlank()) {
            updated = approvalMappingMapper.updateStatusByDocumentId(docId, normalized);
        }

        if (updated == 0) {
            log.warn(
                    "다우 상태 콜백: 매핑 없음 docId={} partnerDocId={} status={}",
                    docId,
                    partnerDocId,
                    normalized);
        } else {
            log.info(
                    "다우 상태 콜백 반영 완료 docId={} partnerDocId={} status={} rows={}",
                    docId,
                    partnerDocId,
                    normalized,
                    updated);
        }
    }

    /** partnerDocId {@code ERP-123} / {@code MAP-123} → 매핑 PK로 상태·문서번호 동기화. */
    private int updateByPartnerDocId(String partnerDocId, String status, String newDaouDocumentId) {
        Long mappingId = parsePartnerMappingId(partnerDocId);
        if (mappingId == null) {
            return 0;
        }
        var row = approvalMappingMapper.selectById(mappingId);
        if (row == null) {
            return 0;
        }
        String daouId = (newDaouDocumentId != null && !newDaouDocumentId.isBlank())
                ? newDaouDocumentId.trim()
                : row.daouDocumentId();
        return approvalMappingMapper.updateDaouDocument(mappingId, daouId, status);
    }

    private static Long parsePartnerMappingId(String partnerDocId) {
        if (partnerDocId == null || partnerDocId.isBlank()) {
            return null;
        }
        String s = partnerDocId.trim();
        for (String prefix : List.of("ERP-", "MAP-", "REDIRECT-", "LOCAL-", "PENDING-", "ERR-")) {
            if (s.regionMatches(true, 0, prefix, 0, prefix.length())) {
                try {
                    return Long.parseLong(s.substring(prefix.length()).trim());
                } catch (NumberFormatException e) {
                    return null;
                }
            }
        }
        return null;
    }

    private DaouSubmitResult submitToDaou(
            String formCode,
            String title,
            String content,
            String draftEmpNo,
            String partnerDocId) throws Exception {
        // 표 border/padding style 은 유지 — 과도한 style 제거가 양식 깨짐의 원인
        String html = toDaouSafeHtml(content);
        if (html.isBlank()) {
            return new DaouSubmitResult(false, null, "본문 HTML 이 비어 있습니다.", null);
        }
        log.info(
                "다우 본문 정규화 rawLen={} safeLen={} preview={}",
                content == null ? 0 : content.length(),
                html.length(),
                html.length() > 160 ? html.substring(0, 160).replace('\n', ' ') : html.replace('\n', ' '));

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(TIMEOUT)
                .followRedirects(HttpClient.Redirect.NEVER)
                .build();

        Map<String, String> fields = new LinkedHashMap<>();
        fields.put("clientId", daouOfficeProperties.getClientId());
        fields.put("clientSecret", daouOfficeProperties.getClientSecret());
        fields.put("productName", "yeokjeon-erp");
        fields.put("productVersion", "1.0.0");
        fields.put("clientCompanyName", "yeokjeon-fnc");
        fields.put("formCode", formCode);
        fields.put("title", title);
        fields.put("content", html);
        fields.put("callbackUrl", blankTo(
                daouOfficeProperties.getCallbackUrl(),
                "https://test.yeokjeon.com/api/eap/status"));
        if (partnerDocId != null && !partnerDocId.isBlank()) {
            fields.put("partnerDocId", partnerDocId);
        }
        if (draftEmpNo != null && !draftEmpNo.isBlank()) {
            fields.put("draftEmpNo", draftEmpNo);
        }

        String draftUrl = trimSlash(daouOfficeProperties.getApiBaseUrl()) + "/public/v4/approval/document";
        HttpResponse<String> response = postDaouForm(client, draftUrl, fields, "기안(v4 content)");
        if (response.statusCode() >= 400) {
            log.warn("다우 urlencoded 실패 status={} - content+첨부 재시도", response.statusCode());
            response = postDaouMultipart(
                    client, draftUrl, fields, "eap_content.html", html, "기안(v4 content+첨부)");
        }

        int status = response.statusCode();
        String responseBody = response.body() == null ? "" : response.body();

        if (status == 302) {
            String location = response.headers().firstValue("Location").orElse("");
            String locContentId = extractContentIdFromLocation(location);
            // contentId 는 본문 슬롯 id. 콜백 docId 는 doasDocumentKey — contentId 로 저장하면 취소 반영 불가.
            String docId = extractDocumentIdFromLocationOrText(location);
            log.info(
                    "다우 v4 redirect contentId={} doasDocId={} contentLen={}",
                    locContentId,
                    docId,
                    html.length());
            log.info("다우 기안 redirect Location={}", location);
            return new DaouSubmitResult(
                    true,
                    docId,
                    "다우오피스 기안 화면으로 이동합니다.",
                    location.isBlank() ? null : location);
        }
        if (status >= 200 && status < 300) {
            String docId = extractDocumentId(responseBody);
            return new DaouSubmitResult(true, docId, "다우오피스 기안 요청이 접수되었습니다.", null);
        }
        return new DaouSubmitResult(false, null, describeDaouError(status, responseBody, formCode), null);
    }

    /**
     * DEXT5용 최소 정제 — 표/셀 style·bgcolor 은 유지·보강한다.
     * (style 만 지우면 테두리·헤더 배경이 사라져 양식이 깨져 보임)
     */
    private static String toDaouSafeHtml(String raw) {
        String s = sanitizeDaouHtml(raw);
        if (s.isBlank()) {
            return "";
        }
        s = s.replaceAll("(?is)\\s+data-erp-[a-zA-Z0-9\\-]+=\"[^\"]*\"", "");
        // table 에 border 가 없으면 기본 테두리 부여
        s = s.replaceAll(
                "(?is)<table(?![^>]*\\bborder=)",
                "<table border=\"1\" cellpadding=\"5\" cellspacing=\"0\"");
        // style 없는 td/th 에 최소 테두리·패딩 (DEXT5가 style 을 깎아도 border=1 은 남음)
        s = s.replaceAll(
                "(?is)<td(?![^>]*\\bstyle=)([^>]*)>",
                "<td$1 style=\"border:1px solid #000;padding:5px;\">");
        s = s.replaceAll(
                "(?is)<th(?![^>]*\\bstyle=)([^>]*)>",
                "<th$1 bgcolor=\"#D9D9D9\" style=\"border:1px solid #000;padding:5px;background:#d9d9d9;font-weight:bold;\">");
        // 헤더 배경이 style 로만 있으면 bgcolor 보강
        s = s.replaceAll(
                "(?is)<(th|td)(\\s(?![^>]*\\bbgcolor=)[^>]*?)style=\"([^\"]*background\\s*:\\s*#d[0-9a-fA-F]{2}[^\"]*)\"",
                "<$1$2 bgcolor=\"#D9D9D9\" style=\"$3\"");
        return s.trim();
    }

    /**
     * 웹 v4 multipart — 텍스트 필드 + attaches 파일(본문 HTML).
     */
    private HttpResponse<String> postDaouMultipart(
            HttpClient client,
            String url,
            Map<String, String> fields,
            String fileName,
            String fileHtml,
            String label) throws Exception {
        String boundary = "----ErpDaouBoundary" + UUID.randomUUID().toString().replace("-", "");
        var bytes = new java.io.ByteArrayOutputStream();

        for (Map.Entry<String, String> e : fields.entrySet()) {
            writeMultipartText(bytes, boundary, e.getKey(), e.getValue() == null ? "" : e.getValue());
        }
        // 첨부: text/html — 브라우저에서 바로 열람 가능
        bytes.write(("--" + boundary + "\r\n").getBytes(StandardCharsets.UTF_8));
        bytes.write(("Content-Disposition: form-data; name=\"attaches\"; filename=\""
                + fileName + "\"\r\n").getBytes(StandardCharsets.UTF_8));
        bytes.write("Content-Type: text/html; charset=UTF-8\r\n\r\n".getBytes(StandardCharsets.UTF_8));
        // UTF-8 BOM for Windows/Excel-friendly open
        bytes.write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
        String wrapped = wrapHtmlDocument(fileName, fileHtml);
        bytes.write(wrapped.getBytes(StandardCharsets.UTF_8));
        bytes.write("\r\n".getBytes(StandardCharsets.UTF_8));
        bytes.write(("--" + boundary + "--\r\n").getBytes(StandardCharsets.UTF_8));

        byte[] body = bytes.toByteArray();
        log.info(
                "다우 {} multipart fields={} contentLen={} attachLen={}",
                label,
                fields.keySet(),
                fields.getOrDefault("content", "").length(),
                wrapped.length());

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(TIMEOUT)
                .header("Content-Type", "multipart/form-data; boundary=" + boundary)
                .POST(HttpRequest.BodyPublishers.ofByteArray(body))
                .build();
        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
        String responseBody = response.body() == null ? "" : response.body();
        log.info(
                "다우 {} 응답 status={} body={}",
                label,
                response.statusCode(),
                responseBody.length() > 500 ? responseBody.substring(0, 500) : responseBody);
        return response;
    }

    private static void writeMultipartText(
            java.io.ByteArrayOutputStream out, String boundary, String name, String value)
            throws java.io.IOException {
        out.write(("--" + boundary + "\r\n").getBytes(StandardCharsets.UTF_8));
        out.write(("Content-Disposition: form-data; name=\"" + name + "\"\r\n\r\n")
                .getBytes(StandardCharsets.UTF_8));
        out.write(value.getBytes(StandardCharsets.UTF_8));
        out.write("\r\n".getBytes(StandardCharsets.UTF_8));
    }

    private static String wrapHtmlDocument(String title, String bodyFragment) {
        return "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><title>"
                + escape(title)
                + "</title></head><body>"
                + bodyFragment
                + "</body></html>";
    }

    private HttpResponse<String> postDaouForm(
            HttpClient client, String url, Map<String, String> form, String label) throws Exception {
        String body = form.entrySet().stream()
                .map(e -> encode(e.getKey()) + "=" + encode(e.getValue()))
                .collect(Collectors.joining("&"));
        log.info(
                "다우 {} POST keys={} contentLen={} contentId={}",
                label,
                form.keySet(),
                form.getOrDefault("content", "").length(),
                form.get("contentId"));
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(TIMEOUT)
                .header("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
                .POST(HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8))
                .build();
        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
        String responseBody = response.body() == null ? "" : response.body();
        log.info(
                "다우 {} 응답 status={} body={}",
                label,
                response.statusCode(),
                responseBody.length() > 500 ? responseBody.substring(0, 500) : responseBody);
        return response;
    }

    private record LocationDataPayload(String json, int urlDecodeRounds) {
    }

    /** Location ?data= Base64 JSON 디코드 (다우는 = 을 %253D 로 이중 인코딩하는 경우가 있음). */
    private static LocationDataPayload decodeLocationData(String location) {
        if (location == null || !location.contains("data=")) {
            return null;
        }
        try {
            URI uri = URI.create(location);
            String rawQuery = uri.getRawQuery();
            if (rawQuery == null) {
                return null;
            }
            String dataRaw = null;
            for (String part : rawQuery.split("&")) {
                if (part.startsWith("data=")) {
                    dataRaw = part.substring("data=".length());
                    break;
                }
            }
            if (dataRaw == null || dataRaw.isBlank()) {
                return null;
            }

            String decoded = dataRaw;
            int rounds = 0;
            for (int i = 0; i < 3; i++) {
                String next = URLDecoder.decode(decoded, StandardCharsets.UTF_8);
                if (next.equals(decoded)) {
                    break;
                }
                decoded = next;
                rounds++;
            }

            byte[] jsonBytes;
            try {
                jsonBytes = Base64.getDecoder().decode(decoded);
            } catch (IllegalArgumentException ex) {
                jsonBytes = Base64.getUrlDecoder().decode(decoded);
            }
            // 다우 원본은 보통 1~2회 URL 인코딩. 최소 1회는 맞춤.
            if (rounds == 0) {
                rounds = 1;
            }
            return new LocationDataPayload(new String(jsonBytes, StandardCharsets.UTF_8), rounds);
        } catch (Exception e) {
            log.warn("Location data 디코드 실패: {}", e.toString());
            return null;
        }
    }

    private static String extractContentIdFromLocation(String location) {
        LocationDataPayload payload = decodeLocationData(location);
        if (payload == null) {
            return null;
        }
        return extractContentId(payload.json());
    }

    private static String extractContentId(String text) {
        if (text == null || text.isBlank()) {
            return null;
        }
        for (String key : List.of(
                "\"contentId\":\"",
                "\"contentId\": \"",
                "\"contentId\":{",
                "contentId\":{\"",
                "contentId=",
                "\"contentId\":")) {
            int idx = text.indexOf(key);
            if (idx < 0) {
                continue;
            }
            String rest = text.substring(idx + key.length()).replace("\"", "").replace("{", "").replace("}", "");
            int end = rest.length();
            for (int i = 0; i < rest.length(); i++) {
                char c = rest.charAt(i);
                if (c == ',' || c == '&' || c == ' ' || c == '\n' || c == ':') {
                    // keep going for malformed {"24115"} style — break on structural ends except colon mid
                    if (c != ':') {
                        end = i;
                        break;
                    }
                }
            }
            // digits-only prefer
            StringBuilder digits = new StringBuilder();
            for (int i = 0; i < rest.length() && i < 32; i++) {
                char c = rest.charAt(i);
                if (Character.isDigit(c)) {
                    digits.append(c);
                } else if (digits.length() > 0) {
                    break;
                }
            }
            if (digits.length() > 0) {
                return digits.toString();
            }
            String value = rest.substring(0, Math.min(end, rest.length())).trim();
            if (!value.isEmpty() && value.length() < 40) {
                return value;
            }
        }
        // JSON: "contentId": { "24115"} 형태
        java.util.regex.Matcher m = java.util.regex.Pattern
                .compile("\"contentId\"\\s*:\\s*\\{\\s*\"?(\\d+)\"?\\s*\\}")
                .matcher(text);
        if (m.find()) {
            return m.group(1);
        }
        m = java.util.regex.Pattern.compile("\"contentId\"\\s*:\\s*\"?(\\d+)\"?").matcher(text);
        if (m.find()) {
            return m.group(1);
        }
        return null;
    }

    private static String describeDaouError(int status, String body, String formCode) {
        if (body.contains("901") || body.contains("유효하지 않은 client ID")) {
            return "다우 응답: Client ID 오류(901) — application.yml client-id 확인";
        }
        if (body.contains("902") || body.contains("client Secret")) {
            return "다우 응답: Client Secret 오류(902) — client-secret 확인";
        }
        if (body.contains("955") || body.contains("도메인 코드") || body.contains("formCode")) {
            return "다우 응답: formCode 오류(955) — 다우 관리자 양식 코드와 ERP formCode('"
                    + formCode + "')가 일치하는지 확인";
        }
        if (body.contains("callback") || body.contains("콜백")) {
            return "다우 응답: callbackUrl 오류 — 로컬host는 불가, 공인 HTTPS URL 필요";
        }
        String snippet = body == null ? "" : body.replaceAll("\\s+", " ").trim();
        if (snippet.length() > 180) {
            snippet = snippet.substring(0, 180) + "…";
        }
        if (!snippet.isEmpty()) {
            return "다우오피스 HTTP " + status + " — " + snippet;
        }
        return "다우오피스 HTTP " + status
                + " — formCode·callbackUrl(공인 URL)·연동 v4 설정을 확인하세요.";
    }

    /** Location 디코드 JSON 우선 — doasDocumentKey 가 콜백 docId 와 일치하는 경우가 많음. */
    private static String extractDocumentIdFromLocationOrText(String location) {
        LocationDataPayload payload = decodeLocationData(location);
        if (payload != null) {
            String fromJson = extractDocumentId(payload.json());
            if (fromJson != null) {
                return fromJson;
            }
        }
        return extractDocumentId(location);
    }

    private static String extractDocumentId(String text) {
        if (text == null || text.isBlank()) {
            return null;
        }
        // 콜백 docId 와 맞추기 위해 doasDocumentKey 를 최우선
        for (String key : List.of(
                "\"doasDocumentKey\":\"",
                "\"doasDocumentKey\": \"",
                "doasDocumentKey=",
                "\"documentId\":\"",
                "\"documentId\": \"",
                "documentId=",
                "\"docId\":\"",
                "\"docId\": \"",
                "docId=")) {
            int idx = text.indexOf(key);
            if (idx >= 0) {
                String rest = text.substring(idx + key.length()).replace("\"", "");
                int end = rest.length();
                for (int i = 0; i < rest.length(); i++) {
                    char c = rest.charAt(i);
                    if (c == '&' || c == ',' || c == '}' || c == ' ' || c == '\n' || c == '\r') {
                        end = i;
                        break;
                    }
                }
                String value = rest.substring(0, end).trim();
                if (!value.isEmpty()) {
                    return value;
                }
            }
        }
        return null;
    }

    /**
     * 다우 OpenAPI {@code content} 는 DEXT5 {@code appContent} 슬롯에 삽입되는 fragment HTML.
     * <p>양식 쪽 필수(관리자 HTML 탭): {@code <div data-id="appContent"></div>}
     * — id/name=appContent 만으로는 OpenAPI 본문이 그려지지 않는다.
     * (제목: {@code <div data-id="appTitle"></div>},
     *  필드: {@code <div data-id="appPostParam{n}"></div>})
     */
    private static String normalizeDaouContent(String raw) {
        return sanitizeDaouHtml(raw);
    }

    private static String sanitizeDaouHtml(String raw) {
        if (raw == null || raw.isBlank()) {
            return "";
        }
        String s = raw.replace("\r", "").trim();
        s = s.replaceAll("(?is)<script[^>]*>.*?</script>", "");
        // 전체문서 래퍼는 제거 — appContent 안쪽 fragment 만 넣는다
        java.util.regex.Matcher body = java.util.regex.Pattern
                .compile("(?is)<body[^>]*>(.*)</body>")
                .matcher(s);
        if (body.find()) {
            s = body.group(1).trim();
        }
        s = s.replaceAll("(?is)<!DOCTYPE[^>]*>", "");
        s = s.replaceAll("(?is)</?html[^>]*>", "");
        s = s.replaceAll("(?is)<head[^>]*>.*?</head>", "");
        s = s.replace("<divstyle", "<div style");
        s = s.replace("<DIVSTYLE", "<DIV style");
        return s.trim();
    }

    private static String normalizeStatus(String raw) {
        String s = raw == null ? "" : raw.trim().toUpperCase(Locale.ROOT);
        return switch (s) {
            case "WRITING", "DRAFT", "INPROGRESS", "COMPLETE", "RETURN", "CANCEL", "TEMPSAVE" -> s;
            case "IN_PROGRESS", "PROGRESS", "RECV_WAITING", "RECEIVED" -> "INPROGRESS";
            case "DONE", "APPROVED", "COMPLETED" -> "COMPLETE";
            case "REJECT", "REJECTED", "RETURNED", "FORCED_RETURN" -> "RETURN";
            case "CANCELED", "CANCELLED", "DELETE", "FORCE_DELETE" -> "CANCEL";
            case "TEMP_SAVE" -> "TEMPSAVE";
            default -> s.isEmpty() ? "WRITING" : s;
        };
    }

    private static String buildSimpleHtml(String title, String formName, String menuId, String sourceId) {
        return "<h2>" + escape(title) + "</h2>"
                + "<p>양식: " + escape(nullToEmpty(formName)) + "</p>"
                + "<p>ERP 메뉴: " + escape(nullToEmpty(menuId)) + "</p>"
                + "<p>ERP 전표: " + escape(nullToEmpty(sourceId)) + "</p>";
    }

    private static String escape(String value) {
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private static String blankTo(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }

    private static String encode(String value) {
        return URLEncoder.encode(value == null ? "" : value, StandardCharsets.UTF_8);
    }

    private static String trimSlash(String base) {
        if (base == null) {
            return "";
        }
        return base.endsWith("/") ? base.substring(0, base.length() - 1) : base;
    }

    private record DaouSubmitResult(
            boolean ok, String documentId, String message, String redirectUrl) {
    }
}
