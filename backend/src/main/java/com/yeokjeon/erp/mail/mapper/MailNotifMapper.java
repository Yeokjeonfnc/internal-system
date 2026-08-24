package com.yeokjeon.erp.mail.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 수신 메일 → ERP 알림({@code notif_mst}) 적재 매퍼 (mal001-N).
 *
 * <p><b>왜 active 모듈의 {@code ActMstMapper}/{@code ActNotifRepository} 를 쓰지 않는가.</b>
 * 전자결재({@code EapDocumentService.notifyLineOnSubmit})는 {@code ActNotif} JPA 엔티티로
 * 알림을 저장하는데, 그 방식은 <b>무조건 INSERT</b> 라 중복 방지 장치가 없다. 메일은
 * 사정이 다르다 — Resend 웹훅은 at-least-once 라 같은 메일이 여러 번 들어오고,
 * 원장 재처리 배치도 같은 메일을 다시 훑는다. 그때마다 알림이 한 줄씩 늘면 알림함이
 * 같은 메일로 도배된다. 그래서 "없을 때만 넣는" INSERT 가 필요하고, 그건 SQL 로만
 * 표현할 수 있어 메일 전용 매퍼를 둔다.
 *
 * <p>읽기(목록·미읽음 수·읽음처리)는 기존 {@code ActMstMapper} 와 {@code /notifications}
 * API 를 그대로 쓴다 — 그쪽은 {@code notif_typ} 을 가리지 않고 사용자 알림을 전부
 * 돌려주므로 메일 알림도 저절로 화면에 뜬다.
 */
@Mapper
public interface MailNotifMapper {

    /**
     * 같은 메일에 대한 알림이 이미 있으면 넣지 않는다.
     *
     * <p>중복 판정 키는 {@code (notif_typ, act_idx, user_id)} 다. {@code act_idx} 에
     * {@code mail_idx} 를 담는데, 이건 전자결재가 같은 컬럼에 결재 매핑 id 를 담는
     * 선례를 그대로 따른 것이다({@code EapDocumentService}) — {@code act_idx} 는 이미
     * "이 알림이 가리키는 대상의 번호"라는 범용 의미로 쓰이고 있다.
     *
     * <p>{@code notif_typ} 조건이 반드시 있어야 한다. 빼면 같은 번호를 가진 활동
     * 알림과 메일 알림이 서로를 중복으로 오인해, 활동 알림이 있다는 이유로 메일 알림이
     * 안 들어가는 일이 생긴다.
     *
     * @return 실제로 들어간 건수(0이면 이미 있던 알림)
     */
    int insertIfAbsent(@Param("userId") String userId,
                       @Param("msgTxt") String msgTxt,
                       @Param("notifTyp") String notifTyp,
                       @Param("actIdx") Integer actIdx);

    /**
     * 알림을 받을 관리자 목록(최후 폴백).
     *
     * <p>수신자 주소로 사원을 못 찾는 메일이 실제로 있다(공용 주소 등). 그때 아무에게도
     * 안 보내면 메일이 온 사실 자체를 아무도 모른다. 그래서 관리자에게라도 보낸다.
     *
     * <p>기준은 {@code admin_yn='Y'} 다. 이 ERP 의 슈퍼관리자 판정과 같은 컬럼이다
     * ({@code MenuAccessGuard} 참고). 퇴사자는 제외한다 — 이미 나간 사람 알림함에
     * 메일이 쌓여 봐야 아무도 안 본다.
     */
    List<String> selectAdminUserIds();
}
