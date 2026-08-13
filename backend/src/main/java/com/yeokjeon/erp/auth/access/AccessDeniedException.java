package com.yeokjeon.erp.auth.access;

/** 로그인은 했으나 해당 작업 권한이 없을 때 — HTTP 403 으로 매핑된다. */
public class AccessDeniedException extends RuntimeException {

    public AccessDeniedException(String message) {
        super(message);
    }
}
