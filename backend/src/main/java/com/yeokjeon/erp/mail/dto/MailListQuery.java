package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * 메일 목록 조회 조건.
 *
 * <p>파라미터를 낱개로 늘어놓지 않고 한 덩어리로 묶은 이유는, 목록과 카운트가
 * 반드시 <b>같은 조건</b>으로 돌아야 하기 때문이다. 인자를 따로 받으면 언젠가
 * 한쪽에만 조건이 추가되고 "목록은 3건인데 카운트는 5건"이 된다.
 *
 * @param folder      inbox|sent|draft|scheduled|failed|spam|trash|star|unread|all|folder.
 *                    알 수 없는 값이면 XML 이 {@code 1 = 0} 으로 막는다 — 오타 난 폴더명에
 *                    전체 메일을 흘리지 않기 위해서다.
 *                    화면은 사용자 정의 메일함을 {@code folder:12} 형태로 보내고,
 *                    서비스가 이를 {@code folder="folder"} + {@code folderIdx=12} 로 쪼갠다.
 * @param folderIdx   {@code folder == "folder"} 일 때의 대상 메일함. 그 외에는 null 이다.
 *                    null 인 채로 folder 만 "folder" 면 XML 이 {@code 1 = 0} 으로 막는다 —
 *                    조건 없는 folder_idx 조회는 남의 메일함까지 다 보여 준다.
 * @param ownerUserId 담당자 필터. null/"" 이면 전체. 쿼리 파라미터 이름으로 userId 를
 *                    쓰지 않는 이유는 AuthTokenFilter 예약어라 토큰 주인과 다르면 403 이 되기 때문.
 * @param keyword     부분일치 검색어. 2자 미만은 trigram 인덱스가 무력해져서
 *                    서비스 단에서 null 로 정규화한 뒤 넘어온다.
 * @param limit       1~500. 서비스가 상한을 강제한다.
 */
public record MailListQuery(
        String folder,
        Long folderIdx,
        String ownerUserId,
        String keyword,
        OffsetDateTime fromDate,
        OffsetDateTime toDate,
        int limit,
        int offset) {

    /** 사용자 정의 메일함 조회를 나타내는 folder 값. */
    public static final String FOLDER_CUSTOM = "folder";

    /** 화면이 보내는 접두사. {@code folder:12} → folder="folder", folderIdx=12 */
    public static final String CUSTOM_PREFIX = "folder:";
}
