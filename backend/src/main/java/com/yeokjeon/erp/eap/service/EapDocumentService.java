package com.yeokjeon.erp.eap.service;

import com.yeokjeon.erp.auth.dto.AuthProfileRowDto;
import com.yeokjeon.erp.auth.mapper.AuthProfileMapper;
import com.yeokjeon.erp.active.entity.ActNotif;
import com.yeokjeon.erp.active.repository.ActNotifRepository;
import com.yeokjeon.erp.eap.dto.EapApprovalMappingInsertParam;
import com.yeokjeon.erp.eap.dto.EapApprovalMappingJdbcRow;
import com.yeokjeon.erp.eap.dto.EapDocLineDto;
import com.yeokjeon.erp.eap.dto.EapDocLineInsertParam;
import com.yeokjeon.erp.eap.dto.EapDocLineJdbcRow;
import com.yeokjeon.erp.eap.dto.EapDocumentDto;
import com.yeokjeon.erp.eap.dto.EapDraftRequestDto;
import com.yeokjeon.erp.eap.dto.EapDraftResultDto;
import com.yeokjeon.erp.eap.dto.EapFormConfigJdbcRow;
import com.yeokjeon.erp.eap.dto.EapLineMemberRequestDto;
import com.yeokjeon.erp.eap.mapper.EapApprovalMappingMapper;
import com.yeokjeon.erp.eap.mapper.EapDocLineMapper;
import com.yeokjeon.erp.eap.mapper.EapFormConfigMapper;
import com.yeokjeon.erp.master.service.MenuPermissionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class EapDocumentService {

    private static final Set<String> LINE_ROLES = Set.of("APPROVER", "AGREE", "CC", "VIEWER");
    private static final Set<String> OPEN_STATUSES = Set.of("INPROGRESS", "DRAFT", "WRITING");
    private static final String NOTIF_TYPE_EAP_APPROVAL = "EAP_APPROVAL";

    private final EapApprovalMappingMapper approvalMappingMapper;
    private final EapDocLineMapper docLineMapper;
    private final EapFormConfigMapper formConfigMapper;
    private final ActNotifRepository actNotifRepository;
    private final AuthProfileMapper authProfileMapper;
    private final MenuPermissionService menuPermissionService;

    @Transactional(readOnly = true)
    public List<EapDocumentDto> listByFolder(String folder, String userId) {
        String key = resolveFolderKey(folder);
        String uid = userId == null ? "" : userId.trim();
        if (uid.isEmpty()) {
            return List.of();
        }
        boolean superAdmin = menuPermissionService.isSuperAdmin(uid);
        Set<String> keys = callerKeys(uid);

        if (superAdmin && "all".equals(key)) {
            return approvalMappingMapper.selectAllDocuments().stream()
                    .map(this::toListDocument)
                    .toList();
        }

        return approvalMappingMapper.selectByFolder(key, uid).stream()
                .map(this::toListDocument)
                .filter(doc -> EapFolderMatcher.matches(key, uid, doc, keys))
                .toList();
    }

    private static String resolveFolderKey(String folder) {
        String key = folder == null ? "" : folder.trim().toLowerCase(Locale.ROOT);
        if ("cc-read".equals(key)) {
            return "cc";
        }
        return key;
    }

    private Set<String> callerKeys(String userId) {
        Set<String> keys = new LinkedHashSet<>();
        String uid = userId == null ? "" : userId.trim();
        if (!uid.isEmpty()) {
            keys.add(uid.toUpperCase(Locale.ROOT));
        }
        AuthProfileRowDto profile = authProfileMapper.selectByUserId(uid);
        if (profile != null) {
            if (profile.userId() != null && !profile.userId().isBlank()) {
                keys.add(profile.userId().trim().toUpperCase(Locale.ROOT));
            }
            if (profile.userNm() != null && !profile.userNm().isBlank()) {
                keys.add(profile.userNm().trim().toUpperCase(Locale.ROOT));
            }
        }
        return keys;
    }


    @Transactional(readOnly = true)
    public EapDocumentDto findDocument(String documentId, String userId) {
        EapApprovalMappingJdbcRow row = resolveRow(documentId);
        if (row == null) {
            throw new IllegalArgumentException("결재 문서를 찾을 수 없습니다: " + documentId);
        }
        ensureDocumentAccess(row, userId);
        return toDocument(row, null, userId, true);
    }

    @Transactional
    public void deleteDocument(String documentId, String userId) {
        String uid = userId == null ? "" : userId.trim();
        if (uid.isEmpty()) {
            throw new IllegalArgumentException("로그인이 필요합니다.");
        }
        if (!menuPermissionService.isSuperAdmin(uid)) {
            throw new IllegalArgumentException("문서 삭제 권한이 없습니다.");
        }
        EapApprovalMappingJdbcRow row = resolveRow(documentId);
        if (row == null) {
            throw new IllegalArgumentException("결재 문서를 찾을 수 없습니다: " + documentId);
        }
        int deleted = approvalMappingMapper.deleteById(row.id());
        if (deleted == 0) {
            throw new IllegalStateException("문서 삭제에 실패했습니다.");
        }
    }

    private void ensureDocumentAccess(EapApprovalMappingJdbcRow row, String userId) {
        String uid = userId == null ? "" : userId.trim();
        if (uid.isEmpty()) {
            throw new IllegalArgumentException("로그인이 필요합니다.");
        }
        if (menuPermissionService.isSuperAdmin(uid)) {
            return;
        }
        EapDocumentDto doc = toListDocument(row);
        if (!EapFolderMatcher.canAccessDocument(doc, callerKeys(uid))) {
            throw new IllegalArgumentException("문서를 조회할 권한이 없습니다.");
        }
    }

    @Transactional
    public EapDocumentDto approve(String documentId, String userId) {
        return actOnLine(documentId, userId, "DONE");
    }

    @Transactional
    public EapDocumentDto reject(String documentId, String userId) {
        return actOnLine(documentId, userId, "REJECT");
    }

    @Transactional
    public EapDraftResultDto draft(EapDraftRequestDto body, String actorUserId) {
        EapFormConfigJdbcRow form = formConfigMapper.selectByCode(body.formCode().trim());
        if (form == null) {
            throw new IllegalArgumentException("등록되지 않은 양식 코드입니다: " + body.formCode());
        }
        if (Boolean.FALSE.equals(form.enabled())) {
            throw new IllegalArgumentException("사용 중지된 양식입니다: " + body.formCode());
        }

        String draftUserId = blankTo(actorUserId, body.draftUserId());
        String erpMenuId = blankTo(body.erpMenuId(), "eap001");
        String title = body.title().trim();
        Long mappingId = body.mappingId();
        String localStatus = resolveDraftStatus(body);
        if ("INPROGRESS".equals(localStatus) || "DRAFT".equals(localStatus)) {
            requireApprover(body.lines(), draftUserId);
        }

        if (mappingId != null && mappingId > 0) {
            EapApprovalMappingJdbcRow existing = approvalMappingMapper.selectById(mappingId);
            if (existing == null) {
                throw new IllegalArgumentException("수정할 결재 문서를 찾을 수 없습니다: " + mappingId);
            }
            String st = existing.status() == null ? "" : existing.status().trim().toUpperCase(Locale.ROOT);
            if (!Set.of("WRITING", "TEMPSAVE", "DRAFT").contains(st)) {
                throw new IllegalArgumentException("작성중·임시저장 문서만 수정할 수 있습니다. 현재 상태: " + existing.status());
            }
            String existingDrafter = existing.draftUserId() == null ? "" : existing.draftUserId().trim();
            if (!existingDrafter.isEmpty() && !existingDrafter.equalsIgnoreCase(draftUserId)) {
                throw new IllegalArgumentException("작성자만 문서를 수정할 수 있습니다.");
            }
            String erpSourceId = blankTo(existing.erpSourceId(), blankTo(body.erpSourceId(), "TMP-" + mappingId));
            String content = sanitizeHtml(
                    blankTo(body.contentHtml(), buildSimpleHtml(title, form.formName(), erpMenuId, erpSourceId)));
            int updated = approvalMappingMapper.updateDraftContent(mappingId, title, content, localStatus);
            if (updated == 0) {
                throw new IllegalStateException("작성중 문서 수정에 실패했습니다. 상태가 변경되었을 수 있습니다.");
            }
            replaceLines(mappingId, body.lines(), draftUserId);
            notifyLineOnSubmit(mappingId, title, draftUserId, body.lines(), localStatus);
            return new EapDraftResultDto(
                    mappingId,
                    blankTo(existing.daouDocumentId(), "LOCAL-" + mappingId),
                    form.formCode(),
                    localStatus,
                    title,
                    draftSavedMessage(localStatus));
        }

        String erpSourceId = blankTo(body.erpSourceId(), "TMP-" + UUID.randomUUID().toString().substring(0, 8));
        String content = sanitizeHtml(
                blankTo(body.contentHtml(), buildSimpleHtml(title, form.formName(), erpMenuId, erpSourceId)));

        EapApprovalMappingInsertParam param = new EapApprovalMappingInsertParam();
        param.setErpMenuId(erpMenuId);
        param.setErpSourceId(erpSourceId);
        param.setDaouFormCode(form.formCode());
        param.setDraftUserId(draftUserId);
        param.setTitle(title);
        param.setContentHtml(content);
        param.setStatus(localStatus);
        approvalMappingMapper.insert(param);
        mappingId = param.getId();
        String localDocId = "LOCAL-" + mappingId;
        approvalMappingMapper.updateDaouDocument(mappingId, localDocId, localStatus);
        replaceLines(mappingId, body.lines(), draftUserId);
        notifyLineOnSubmit(mappingId, title, draftUserId, body.lines(), localStatus);
        return new EapDraftResultDto(
                mappingId,
                localDocId,
                form.formCode(),
                localStatus,
                title,
                draftSavedMessage(localStatus));
    }

    private void notifyLineOnSubmit(
            Long mappingId,
            String title,
            String drafterUserId,
            List<EapLineMemberRequestDto> members,
            String localStatus) {
        if (!"INPROGRESS".equals(localStatus) || mappingId == null || mappingId <= 0) {
            return;
        }
        if (mappingId > Integer.MAX_VALUE || members == null || members.isEmpty()) {
            return;
        }
        String drafter = drafterUserId == null ? "" : drafterUserId.trim();
        LinkedHashSet<String> recipients = new LinkedHashSet<>();
        for (EapLineMemberRequestDto m : members) {
            if (m == null || m.userId() == null || m.userId().isBlank()) {
                continue;
            }
            String role = m.roleCd() == null ? "" : m.roleCd().trim().toUpperCase(Locale.ROOT);
            if (!LINE_ROLES.contains(role)) {
                continue;
            }
            String uid = m.userId().trim();
            if (!drafter.isEmpty() && drafter.equalsIgnoreCase(uid)) {
                continue;
            }
            recipients.add(uid);
        }
        if (recipients.isEmpty()) {
            return;
        }
        String label = title == null || title.isBlank() ? "전자결재" : title.trim();
        if (label.length() > 80) {
            label = label.substring(0, 80) + "…";
        }
        String msg = label + " 문서의 결재선에 지정되었습니다.";
        int refIdx = mappingId.intValue();
        for (String uid : recipients) {
            ActNotif n = ActNotif.builder()
                    .userId(uid)
                    .msgTxt(msg)
                    .notifTyp(NOTIF_TYPE_EAP_APPROVAL)
                    .actIdx(refIdx)
                    .apprYn("N")
                    .build();
            actNotifRepository.save(n);
        }
    }

    private EapApprovalMappingJdbcRow resolveRow(String documentId) {
        EapApprovalMappingJdbcRow row = approvalMappingMapper.selectByDocumentId(documentId);
        if (row == null && documentId != null && documentId.startsWith("MAP-")) {
            try {
                long id = Long.parseLong(documentId.substring(4));
                row = approvalMappingMapper.selectById(id);
            } catch (NumberFormatException ignored) {
                // fall through
            }
        }
        return row;
    }

    private EapDocumentDto toListDocument(EapApprovalMappingJdbcRow row) {
        List<EapDocLineJdbcRow> lineRows = docLineMapper.selectByMappingId(row.id());
        List<EapDocLineDto> lines = lineRows.stream().map(EapDocLineDto::fromRow).toList();
        return EapDocumentDto.fromRow(row, "", lines, false);
    }

    private EapDocumentDto toDocument(
            EapApprovalMappingJdbcRow row,
            String contentHtml,
            String userId,
            boolean includeBody) {
        String html = contentHtml;
        if (includeBody) {
            String stored = row.contentHtml();
            if (stored == null || stored.isBlank()) {
                stored = buildSimpleHtml(
                        row.title() == null ? "" : row.title(),
                        row.formName(),
                        row.erpMenuId(),
                        row.erpSourceId());
            }
            html = stored;
        }
        List<EapDocLineJdbcRow> lineRows = docLineMapper.selectByMappingId(row.id());
        List<EapDocLineDto> lines = lineRows.stream().map(EapDocLineDto::fromRow).toList();
        boolean canApprove = canActOnLine(lineRows, userId, row.status());
        return EapDocumentDto.fromRow(row, html, lines, canApprove);
    }

    private EapDocumentDto actOnLine(String documentId, String userId, String nextLineStatus) {
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("로그인이 필요합니다.");
        }
        EapApprovalMappingJdbcRow row = resolveRow(documentId);
        if (row == null) {
            throw new IllegalArgumentException("결재 문서를 찾을 수 없습니다: " + documentId);
        }
        String docStatus = row.status() == null ? "" : row.status().trim().toUpperCase(Locale.ROOT);
        List<EapDocLineJdbcRow> lines = docLineMapper.selectByMappingId(row.id());
        EapDocLineJdbcRow target = findActionableLine(
                lines, userId, docStatus, callerKeys(userId));
        if (target == null) {
            throw new IllegalArgumentException("결재할 수 있는 차례가 아닙니다.");
        }
        docLineMapper.updateLineStatus(target.lineId(), nextLineStatus);
        if ("REJECT".equals(nextLineStatus)) {
            approvalMappingMapper.updateDaouDocument(row.id(), row.daouDocumentId(), "RETURN");
        } else {
            List<EapDocLineJdbcRow> after = docLineMapper.selectByMappingId(row.id());
            boolean agreeWait = after.stream().anyMatch(
                    l -> "AGREE".equalsIgnoreCase(l.roleCd()) && "WAIT".equalsIgnoreCase(l.lineStatus()));
            boolean approverWait = after.stream().anyMatch(
                    l -> "APPROVER".equalsIgnoreCase(l.roleCd()) && "WAIT".equalsIgnoreCase(l.lineStatus()));
            String nextDoc = (agreeWait || approverWait) ? "INPROGRESS" : "COMPLETE";
            approvalMappingMapper.updateDaouDocument(row.id(), row.daouDocumentId(), nextDoc);
        }
        return findDocument(documentId, userId);
    }

    private boolean canActOnLine(
            List<EapDocLineJdbcRow> lines, String userId, String docStatus) {
        return findActionableLine(lines, userId, docStatus, callerKeys(userId)) != null;
    }

    private static EapDocLineJdbcRow findActionableLine(
            List<EapDocLineJdbcRow> lines,
            String userId,
            String docStatus,
            Set<String> keys) {
        String st = docStatus == null ? "" : docStatus.trim().toUpperCase(Locale.ROOT);
        String uid = userId == null ? "" : userId.trim();
        if (!OPEN_STATUSES.contains(st) || uid.isEmpty()) {
            return null;
        }
        EapDocLineJdbcRow agree = null;
        for (EapDocLineJdbcRow line : lines) {
            if (!EapFolderMatcher.lineMatchesKeys(line.userId(), line.userNm(), keys)) {
                continue;
            }
            if (!"WAIT".equalsIgnoreCase(EapFolderMatcher.normalizeLineStatus(line.lineStatus()))) {
                continue;
            }
            String role = line.roleCd() == null ? "" : line.roleCd().trim().toUpperCase(Locale.ROOT);
            if ("APPROVER".equals(role) && isCurrentApprover(lines, line)) {
                return line;
            }
            if ("AGREE".equals(role) && agree == null) {
                agree = line;
            }
        }
        return agree;
    }

    private static boolean isCurrentApprover(List<EapDocLineJdbcRow> lines, EapDocLineJdbcRow me) {
        int myOrder = me.sortOrder() == null ? 0 : me.sortOrder();
        for (EapDocLineJdbcRow p : lines) {
            if (!"APPROVER".equalsIgnoreCase(p.roleCd())) {
                continue;
            }
            int order = p.sortOrder() == null ? 0 : p.sortOrder();
            if (order < myOrder && "WAIT".equalsIgnoreCase(p.lineStatus())) {
                return false;
            }
        }
        return true;
    }

    private void replaceLines(Long mappingId, List<EapLineMemberRequestDto> members, String draftUserId) {
        docLineMapper.deleteByMappingId(mappingId);
        if (members == null || members.isEmpty()) {
            return;
        }
        String drafter = draftUserId == null ? "" : draftUserId.trim();
        Map<String, EapLineMemberRequestDto> unique = new LinkedHashMap<>();
        for (EapLineMemberRequestDto m : members) {
            if (m == null) {
                continue;
            }
            String uid = m.userId() == null ? "" : m.userId().trim();
            if (uid.isEmpty()) {
                uid = blankTo(m.userNm(), "");
            }
            if (uid.isEmpty()) {
                continue;
            }
            if (!drafter.isEmpty() && drafter.equalsIgnoreCase(uid)) {
                continue;
            }
            String role = m.roleCd() == null ? "" : m.roleCd().trim().toUpperCase(Locale.ROOT);
            if (!LINE_ROLES.contains(role)) {
                continue;
            }
            String key = uid.toUpperCase(Locale.ROOT);
            EapLineMemberRequestDto prev = unique.get(key);
            if (prev == null || roleRank(role) < roleRank(prev.roleCd())) {
                unique.put(key, m);
            }
        }
        int fallbackOrder = 0;
        for (EapLineMemberRequestDto m : unique.values()) {
            String uid = m.userId() == null ? "" : m.userId().trim();
            if (uid.isEmpty()) {
                uid = blankTo(m.userNm(), "");
            }
            String role = m.roleCd() == null ? "" : m.roleCd().trim().toUpperCase(Locale.ROOT);
            EapDocLineInsertParam param = new EapDocLineInsertParam();
            param.setMappingId(mappingId);
            param.setRoleCd(role);
            param.setSortOrder(m.sortOrder() == null ? fallbackOrder : m.sortOrder());
            param.setUserId(uid);
            param.setUserNm(blankTo(m.userNm(), uid));
            param.setTitleNm(m.titleNm() == null ? "" : m.titleNm().trim());
            param.setLineStatus("WAIT");
            docLineMapper.insert(param);
            fallbackOrder++;
        }
    }

    private static int roleRank(String role) {
        String r = role == null ? "" : role.trim().toUpperCase(Locale.ROOT);
        return switch (r) {
            case "APPROVER" -> 0;
            case "AGREE" -> 1;
            case "CC" -> 2;
            case "VIEWER" -> 3;
            default -> 9;
        };
    }

    private static void requireApprover(List<EapLineMemberRequestDto> members, String draftUserId) {
        if (members == null) {
            throw new IllegalArgumentException("결재자를 한 명 이상 지정해 주세요.");
        }
        String drafter = draftUserId == null ? "" : draftUserId.trim();
        boolean hasApprover = members.stream().anyMatch(m -> {
            if (m == null || m.userId() == null || m.userId().isBlank()) {
                return false;
            }
            String uid = m.userId().trim();
            if (!drafter.isEmpty() && drafter.equalsIgnoreCase(uid)) {
                return false;
            }
            String role = m.roleCd() == null ? "" : m.roleCd().trim();
            return "APPROVER".equalsIgnoreCase(role);
        });
        if (!hasApprover) {
            throw new IllegalArgumentException("결재자를 한 명 이상 지정해 주세요.");
        }
    }

    private static String draftSavedMessage(String status) {
        if ("TEMPSAVE".equals(status)) {
            return "임시 저장했습니다.";
        }
        if ("INPROGRESS".equals(status) || "DRAFT".equals(status)) {
            return "상신했습니다.";
        }
        return "저장했습니다.";
    }

    private static String resolveDraftStatus(EapDraftRequestDto body) {
        String s = body.status();
        if (s == null || s.isBlank()) {
            return "INPROGRESS";
        }
        return s.trim().toUpperCase(Locale.ROOT);
    }

    private static String sanitizeHtml(String raw) {
        if (raw == null || raw.isBlank()) {
            return "";
        }
        return raw.replace("\r", "").replaceAll("(?is)<script[^>]*>.*?</script>", "").trim();
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
}
