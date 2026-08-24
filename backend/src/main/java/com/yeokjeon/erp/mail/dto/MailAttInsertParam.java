package com.yeokjeon.erp.mail.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;

/**
 * mail_att INSERT 파라미터.
 *
 * <p>생성된 mail_att_idx 를 되받아야 해서 가변 클래스다.
 *
 * <p>수신 메일 첨부는 웹훅 시점에 크기를 알 수 없어 {@code fileSize} 가 null 로 들어온다
 * (Resend 웹훅 페이로드에 size 가 없다). XML 이 0 으로 막고, 나중에 본문/첨부 API 응답의
 * size 로 {@code updateFetched} 가 갱신한다.
 *
 * <p>{@code fetchedAt} 은 발신 메일 첨부처럼 우리가 직접 디스크에 저장해 이미 실물이
 * 있는 경우에만 채운다. 수신 첨부는 null 로 넣어야 수집 잡이 집어 간다.
 */
@Getter
@Setter
public class MailAttInsertParam {

    /** INSERT 후 MyBatis 가 채워 주는 생성키. 중복(ON CONFLICT DO NOTHING)이면 null 로 남는다 */
    private Long mailAttIdx;

    private Long mailIdx;
    private String resendAttId;
    private String fileName;
    private String storedName;
    private Long fileSize;
    private String contentType;
    private String contentId;
    private String inlineYn;
    private OffsetDateTime fetchedAt;
    private String modifiedBy;
}
