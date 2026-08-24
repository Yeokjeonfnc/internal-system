package com.yeokjeon.erp.mail.mapper;

import com.yeokjeon.erp.mail.dto.MailFolderCountDto;
import com.yeokjeon.erp.mail.dto.MailFolderInsertParam;
import com.yeokjeon.erp.mail.dto.MailFolderJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 사용자 정의 메일함(mail_folder_mst) 매퍼 (mal001-C).
 *
 * <p><b>모든 조회·변경 메서드가 {@code userId} 를 받는다.</b> 메일함은 개인 소유물이라
 * PK 만으로 갱신·삭제하면 남의 메일함을 idx 만 바꿔 지울 수 있다. 서비스에서 소유자를
 * 한 번 확인하고 매퍼에서 또 조건을 거는 이중 방어인데, 서비스 쪽 검사를 누가 빠뜨려도
 * SQL 이 0행을 갱신하고 끝나도록 하기 위해서다.
 */
@Mapper
public interface MailFolderMapper {

    /** 사이드바용 전체 목록. sort_order → idx 순. */
    List<MailFolderJdbcRow> selectByUserId(@Param("userId") String userId);

    /** 본인 소유일 때만 행을 돌려준다. 남의 메일함이면 null. */
    MailFolderJdbcRow selectByIdx(@Param("folderIdx") Long folderIdx,
                                  @Param("userId") String userId);

    /**
     * 메일함별 건수(사이드바 뱃지).
     *
     * <p>mail_folder_mst 를 왼쪽에 두고 LEFT JOIN 한다 — 메일이 0통인 메일함도
     * 목록에 남아야 한다. mail_mst 기준으로 GROUP BY 하면 빈 메일함이 사이드바에서
     * 통째로 사라져 사용자가 "만든 함이 없어졌다"고 오해한다.
     */
    List<MailFolderCountDto> selectFolderCounts(@Param("userId") String userId);

    /** useGeneratedKeys 로 param.mailFolderIdx 에 새 PK 가 채워진다 */
    int insert(MailFolderInsertParam param);

    /**
     * 부분 수정. null 인 항목은 COALESCE 로 기존 값을 유지한다.
     *
     * <p>{@code parentFolderIdx} 만은 COALESCE 를 쓸 수 없다 — null 이 "최상위로 옮김"
     * 이라는 <b>의미 있는 값</b>이라서다. 그래서 별도 플래그({@code parentGiven})로
     * "보냈는가"와 "null 을 보냈는가"를 구분한다.
     */
    int update(@Param("folderIdx") Long folderIdx,
               @Param("userId") String userId,
               @Param("folderNm") String folderNm,
               @Param("parentGiven") boolean parentGiven,
               @Param("parentFolderIdx") Long parentFolderIdx,
               @Param("sortOrder") Integer sortOrder);

    /**
     * 물리 삭제.
     *
     * <p>메일은 함께 지워지지 않는다 — mail_mst.folder_idx 의 FK 가
     * {@code ON DELETE SET NULL} 이라 안에 있던 메일은 folder_idx=NULL 이 되어
     * 기본함(받은메일함 등)으로 자동으로 돌아간다. 하위 메일함은
     * {@code ON DELETE CASCADE} 라 같이 지워지고, 그 안의 메일도 같은 규칙으로 풀린다.
     */
    int delete(@Param("folderIdx") Long folderIdx, @Param("userId") String userId);

    /** 같은 부모 아래 이름 중복 확인. {@code excludeIdx} 는 수정 시 자기 자신을 제외하려는 것. */
    int countByName(@Param("userId") String userId,
                    @Param("parentFolderIdx") Long parentFolderIdx,
                    @Param("folderNm") String folderNm,
                    @Param("excludeIdx") Long excludeIdx);

    /** 새 메일함을 맨 뒤에 붙일 때 쓸 다음 정렬값. 행이 없으면 0. */
    int selectNextSortOrder(@Param("userId") String userId,
                            @Param("parentFolderIdx") Long parentFolderIdx);

    /** 사용자당 메일함 개수 상한 검사용. 하위 메일함까지 전부 센다. */
    int countByUserId(@Param("userId") String userId);
}
