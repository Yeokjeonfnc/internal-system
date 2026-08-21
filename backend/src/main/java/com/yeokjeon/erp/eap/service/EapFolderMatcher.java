package com.yeokjeon.erp.eap.service;

import com.yeokjeon.erp.eap.dto.EapDocLineDto;
import com.yeokjeon.erp.eap.dto.EapDocumentDto;

import java.util.Locale;
import java.util.Set;

/**
 * 전자결재 문서함 분류.
 *
 * <p>한 사용자는 한 문서에 대해 문서함 하나만 가진다.
 * <ol>
 *   <li>결재자·합의자 → 받은결재 (기안자 ID가 잘못 들어 있어도 결재선이 우선)</li>
 *   <li>그 외 기안자 → 올린결재</li>
 *   <li>그 외 참조·열람 → 수신참조</li>
 * </ol>
 */
public final class EapFolderMatcher {

    static final Set<String> LINE_ROLES = Set.of("APPROVER", "AGREE", "CC", "VIEWER");
    static final Set<String> INBOX_ROLES = Set.of("APPROVER", "AGREE");
    static final Set<String> CC_ROLES = Set.of("CC", "VIEWER");
    static final Set<String> OPEN_STATUSES = Set.of("INPROGRESS", "DRAFT", "WRITING");

    private EapFolderMatcher() {
    }

    public static boolean matches(String folder, String uid, EapDocumentDto doc, Set<String> keys) {
        String key = folder == null ? "" : folder.trim().toLowerCase(Locale.ROOT);
        if ("cc-read".equals(key)) {
            key = "cc";
        }
        return switch (key) {
            case "sent" -> isSent(uid, doc, keys)
                    && statusIn(doc, "INPROGRESS", "DRAFT", "WRITING", "COMPLETE", "RETURN", "CANCEL");
            case "drafted" -> isSent(uid, doc, keys)
                    && statusIn(doc, "WRITING", "DRAFT", "TEMPSAVE", "INPROGRESS", "COMPLETE", "RETURN", "CANCEL");
            case "sent-open" -> isSent(uid, doc, keys) && statusIn(doc, OPEN_STATUSES);
            case "sent-complete" -> isSent(uid, doc, keys) && statusIs(doc, "COMPLETE");
            case "sent-rejected" -> isSent(uid, doc, keys) && statusIs(doc, "RETURN");
            case "sent-temp", "temp-saved" -> isSent(uid, doc, keys) && statusIs(doc, "TEMPSAVE");
            case "inbox-pending" -> isInboxPending(uid, doc, keys);
            case "inbox-progress" -> isInboxProgress(uid, doc, keys);
            case "inbox-complete" -> isInboxComplete(uid, doc, keys);
            case "inbox-rejected" -> isInboxRejected(uid, doc, keys);
            case "cc" -> !hasRole(doc, INBOX_ROLES, keys) && hasRole(doc, CC_ROLES, keys);
            case "all" -> isDrafter(uid, doc, keys) || hasRole(doc, LINE_ROLES, keys);
            default -> isDrafter(uid, doc, keys) || hasRole(doc, LINE_ROLES, keys);
        };
    }

    /** 상신·결재·합의·참조·열람 당사자만 문서 열람 가능(관리자는 서비스에서 별도 허용). */
    public static boolean canAccessDocument(EapDocumentDto doc, Set<String> keys) {
        return isDrafter(null, doc, keys) || hasRole(doc, LINE_ROLES, keys);
    }

    /** 올린결재 — 내가 기안했고, 내 결재·합의 라인이 없다. */
    static boolean isSent(String uid, EapDocumentDto doc, Set<String> keys) {
        return isDrafter(uid, doc, keys) && !hasRole(doc, INBOX_ROLES, keys);
    }

    /** 결재대기 — 내 결재·합의 라인이 아직 DONE/REJECT 가 아님. 차례와 무관. */
    static boolean isInboxPending(String uid, EapDocumentDto doc, Set<String> keys) {
        if (!statusIn(doc, OPEN_STATUSES)) {
            return false;
        }
        return inboxUnfinished(doc, keys);
    }

    /** 진행문서 — 내가 이미 결재·합의했고, 남은 내 대기 라인이 없음. */
    static boolean isInboxProgress(String uid, EapDocumentDto doc, Set<String> keys) {
        if (!statusIn(doc, OPEN_STATUSES)) {
            return false;
        }
        return inboxDone(doc, keys) && !inboxUnfinished(doc, keys);
    }

    static boolean isInboxComplete(String uid, EapDocumentDto doc, Set<String> keys) {
        return statusIs(doc, "COMPLETE") && hasRole(doc, INBOX_ROLES, keys);
    }

    static boolean isInboxRejected(String uid, EapDocumentDto doc, Set<String> keys) {
        return statusIs(doc, "RETURN") && hasRole(doc, INBOX_ROLES, keys);
    }

    static boolean isDrafter(String uid, EapDocumentDto doc, Set<String> keys) {
        String draft = doc.draftUserId() == null ? "" : doc.draftUserId().trim();
        if (draft.isEmpty()) {
            return false;
        }
        if (uid != null && !uid.isBlank() && draft.equalsIgnoreCase(uid.trim())) {
            return true;
        }
        return keys != null && keys.contains(draft.toUpperCase(Locale.ROOT));
    }

    static boolean hasRole(EapDocumentDto doc, Set<String> roles, Set<String> keys) {
        if (doc.lines() == null || doc.lines().isEmpty()) {
            return false;
        }
        for (EapDocLineDto line : doc.lines()) {
            String role = line.roleCd() == null ? "" : line.roleCd().trim().toUpperCase(Locale.ROOT);
            if (lineMatchesKeys(line.userId(), line.userNm(), keys) && roles.contains(role)) {
                return true;
            }
        }
        return false;
    }

    static boolean lineMatchesKeys(String lineUserId, String lineUserNm, Set<String> keys) {
        if (keys == null || keys.isEmpty()) {
            return false;
        }
        String lineUid = lineUserId == null ? "" : lineUserId.trim().toUpperCase(Locale.ROOT);
        String lineNm = lineUserNm == null ? "" : lineUserNm.trim().toUpperCase(Locale.ROOT);
        return (!lineUid.isEmpty() && keys.contains(lineUid))
                || (!lineNm.isEmpty() && keys.contains(lineNm));
    }

    static String normalizeLineStatus(String status) {
        String st = status == null ? "" : status.trim().toUpperCase(Locale.ROOT);
        return st.isEmpty() ? "WAIT" : st;
    }

    private static boolean inboxUnfinished(EapDocumentDto doc, Set<String> keys) {
        if (doc.lines() == null) {
            return false;
        }
        for (EapDocLineDto line : doc.lines()) {
            String role = line.roleCd() == null ? "" : line.roleCd().trim().toUpperCase(Locale.ROOT);
            if (!INBOX_ROLES.contains(role) || !lineMatchesKeys(line.userId(), line.userNm(), keys)) {
                continue;
            }
            String st = normalizeLineStatus(line.lineStatus());
            if (!"DONE".equals(st) && !"REJECT".equals(st)) {
                return true;
            }
        }
        return false;
    }

    private static boolean inboxDone(EapDocumentDto doc, Set<String> keys) {
        if (doc.lines() == null) {
            return false;
        }
        for (EapDocLineDto line : doc.lines()) {
            String role = line.roleCd() == null ? "" : line.roleCd().trim().toUpperCase(Locale.ROOT);
            if (!INBOX_ROLES.contains(role) || !lineMatchesKeys(line.userId(), line.userNm(), keys)) {
                continue;
            }
            if ("DONE".equals(normalizeLineStatus(line.lineStatus()))) {
                return true;
            }
        }
        return false;
    }

    private static boolean statusIs(EapDocumentDto doc, String expected) {
        return expected.equals(statusOf(doc));
    }

    private static boolean statusIn(EapDocumentDto doc, String... statuses) {
        String st = statusOf(doc);
        for (String s : statuses) {
            if (s.equals(st)) {
                return true;
            }
        }
        return false;
    }

    private static boolean statusIn(EapDocumentDto doc, Set<String> statuses) {
        return statuses.contains(statusOf(doc));
    }

    private static String statusOf(EapDocumentDto doc) {
        return doc.status() == null ? "" : doc.status().trim().toUpperCase(Locale.ROOT);
    }
}
