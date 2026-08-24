package com.yeokjeon.erp.mail.mapper;

import com.yeokjeon.erp.mail.dto.MailAttInsertParam;
import com.yeokjeon.erp.mail.dto.MailAttJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 메일 첨부 메타 매퍼. 실물 바이너리는 디스크에 있고 여기에는 메타만 있다.
 *
 * <p>수신 첨부는 웹훅 시점에 메타만 만들어지고({@code fetched_at IS NULL})
 * 나중에 배치가 실물을 내려받아 {@link #updateFetched} 로 완성한다.
 */
@Mapper
public interface MailAttMapper {

    List<MailAttJdbcRow> selectByMailIdx(@Param("mailIdx") Long mailIdx);

    MailAttJdbcRow selectByIdx(@Param("mailAttIdx") Long mailAttIdx);

    /**
     * ON CONFLICT (mail_idx, resend_att_id) DO NOTHING.
     * 웹훅 재전달과 재동기화 배치가 같은 첨부를 동시에 집어넣을 수 있어서다.
     * 발신 메일 첨부는 resend_att_id 가 NULL 이고 NULL 끼리는 충돌하지 않으므로
     * 같은 파일을 두 번 올리는 것은 정상적으로 두 행이 된다.
     */
    int insert(MailAttInsertParam param);

    List<MailAttJdbcRow> selectFetchPending(@Param("limit") int limit,
                                            @Param("maxTryCnt") int maxTryCnt,
                                            @Param("backoffMinutes") int backoffMinutes);

    int markFetchTried(@Param("mailAttIdx") Long mailAttIdx);

    int updateFetched(@Param("mailAttIdx") Long mailAttIdx,
                      @Param("storedName") String storedName,
                      @Param("fileSize") Long fileSize,
                      @Param("contentType") String contentType);

    int updateFetchFailed(@Param("mailAttIdx") Long mailAttIdx, @Param("fetchErr") String fetchErr);

    /** 디스크 파일은 남긴 채 메타만 내린다 — 실수 삭제를 복구할 여지를 둔다 */
    int softDelete(@Param("mailAttIdx") Long mailAttIdx, @Param("modifiedBy") String modifiedBy);

    int countByMailIdx(@Param("mailIdx") Long mailIdx);
}
