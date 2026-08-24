package com.yeokjeon.erp.mail.dto;

import java.util.Locale;

/**
 * 목록 일괄 동작의 종류 (mal001-B).
 *
 * <p>문자열을 서비스 안에서 switch 로 흩어 두지 않고 enum 으로 좁히는 이유는,
 * 오타 난 action 이 조용히 "아무 일도 안 함"으로 처리되면 사용자는 눌렀는데 목록이
 * 그대로인 상태를 마주하기 때문이다. 모르는 값은 파싱 단계에서 400 으로 끊는다.
 *
 * <p>필요 권한을 각 상수가 직접 들고 있다. 컨트롤러가 action 별로 if 를 늘어놓으면
 * 항목이 추가될 때 권한 검사만 빠뜨리기 쉽다.
 */
public enum MailBulkAction {

    /** 읽음 표시 */
    READ(Permission.UPDATE),
    /** 안읽음으로 되돌림 */
    UNREAD(Permission.UPDATE),
    /** 중요표시(별) */
    STAR(Permission.UPDATE),
    /** 중요표시 해제 */
    UNSTAR(Permission.UPDATE),
    /** 휴지통으로 이동(소프트 삭제) */
    DELETE(Permission.DELETE),
    /** 휴지통에서 복구 */
    RESTORE(Permission.UPDATE),
    /**
     * 완전 삭제.
     *
     * <p>유일하게 되돌릴 수 없는 동작이라 DELETE 권한을 요구하고, 서비스에서
     * "이미 휴지통에 있는 메일"만 대상으로 한 번 더 좁힌다.
     */
    PURGE(Permission.DELETE),
    /** 스팸으로 신고 */
    SPAM(Permission.UPDATE),
    /** 스팸 해제 */
    NOTSPAM(Permission.UPDATE),
    /** 사용자 정의 메일함으로 이동. {@code folderIdx} 가 필요하다(null 이면 기본함으로 되돌림) */
    MOVE(Permission.UPDATE);

    /** {@code MenuAccessGuard.Action} 을 그대로 쓰지 않는 이유는 dto 가 auth 패키지에 의존하지 않게 하려는 것. */
    public enum Permission {
        UPDATE,
        DELETE
    }

    private final Permission permission;

    MailBulkAction(Permission permission) {
        this.permission = permission;
    }

    public Permission permission() {
        return permission;
    }

    /**
     * 화면이 보내는 문자열을 enum 으로 바꾼다. 대소문자를 가리지 않는다.
     *
     * @throws IllegalArgumentException 모르는 값 — GlobalExceptionHandler 가 400 으로 바꾼다
     */
    public static MailBulkAction from(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("수행할 동작(action)을 지정해 주세요.");
        }
        try {
            return valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("알 수 없는 동작입니다: " + raw);
        }
    }
}
