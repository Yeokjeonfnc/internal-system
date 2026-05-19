package com.yeokjeon.erp.active.service;

import com.yeokjeon.erp.active.dto.ActNotifAckDateRow;
import com.yeokjeon.erp.active.dto.ActiveListQuery;
import com.yeokjeon.erp.active.dto.ActiveMstResponseDto;
import com.yeokjeon.erp.active.dto.ActiveMstWriteRequestDto;
import com.yeokjeon.erp.active.dto.ActivityStatusPivotRowDto;
import com.yeokjeon.erp.active.dto.ChkMstInsertHolder;
import com.yeokjeon.erp.active.dto.ChkMstResponseDto;
import com.yeokjeon.erp.active.dto.ChkMstWriteRequestDto;
import com.yeokjeon.erp.active.dto.ChkResultDtlSaveDto;
import com.yeokjeon.erp.active.dto.ChkResultRowDto;
import com.yeokjeon.erp.active.dto.NotifMstDto;
import com.yeokjeon.erp.active.dto.UserIdNameRow;
import com.yeokjeon.erp.active.dto.UserWriterDeptRow;
import com.yeokjeon.erp.active.entity.ActActive;
import com.yeokjeon.erp.active.entity.ActNotif;
import com.yeokjeon.erp.active.mapper.ActMstMapper;
import com.yeokjeon.erp.active.repository.ActNotifRepository;
import com.yeokjeon.erp.active.repository.ActRepository;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.franchise.entity.Store;
import com.yeokjeon.erp.franchise.repository.StoreRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ActService {

    private static final String TYPE_ACTIVITY_APPROVAL = "ACTIVITY_APPROVAL";
    private static final String STATUS_DRAFT = "DRAFT";
    private static final String STATUS_APPROVED = "APPROVED";
    private static final String STATUS_PENDING = "PENDING";

    private final ActRepository actRepository;
    private final ActNotifRepository actNotifRepository;
    private final StoreRepository storeRepository;
    private final ActMstMapper actMstMapper;

    public List<ActivityStatusPivotRowDto> statusByStore(LocalDate startDt, LocalDate endDt, String brandCd) {
        return actMstMapper.pivotByStore(startDt, endDt, brandCd);
    }

    public List<ActivityStatusPivotRowDto> statusBySv(LocalDate startDt, LocalDate endDt, String brandCd) {
        return actMstMapper.pivotBySv(startDt, endDt, brandCd);
    }

    public List<ActiveMstResponseDto> listAll() {
        List<ActActive> rows = actMstMapper.actList(ActiveListQuery.allNoDraft());
        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActiveResponse(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    public List<ActiveMstResponseDto> listByStatus(String apprStatus, String svId, String relUserId) {
        List<ActActive> rows = actMstMapper.actList(ActiveListQuery.byApprStatus(apprStatus));

        // DRAFT: 작성자 = act_active.sv_id. 클라이언트는 보통 로그인 ID를 svId로 넘기며,
        // relUserId만 보낸 경우(동일 값)도 작성자 필터로 받아들인다.
        if (STATUS_DRAFT.equals(apprStatus)) {
            String writerId = null;
            if (svId != null && !svId.isBlank()) {
                writerId = svId.trim();
            } else if (relUserId != null && !relUserId.isBlank()) {
                writerId = relUserId.trim();
            }
            if (writerId != null) {
                final String uid = writerId;
                rows = rows.stream()
                        .filter(active -> uid.equals(active.getSvId()))
                        .collect(Collectors.toList());
            }
        }

        if (relUserId != null && !relUserId.isBlank()
                && (STATUS_PENDING.equals(apprStatus) || STATUS_APPROVED.equals(apprStatus))) {
            final String uid = relUserId.trim();
            rows = rows.stream()
                    .filter(active -> uid.equals(active.getSvId()) || apprIdContainsUser(active.getApprId(), uid))
                    .collect(Collectors.toList());
        }

        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActiveResponse(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    private static boolean apprIdContainsUser(String apprIdCsv, String userId) {
        if (apprIdCsv == null || apprIdCsv.isBlank()) {
            return false;
        }
        return Arrays.stream(apprIdCsv.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .anyMatch(userId::equals);
    }

    public ActiveMstResponseDto one(Integer actIdx) {
        ActActive active = actRepository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));
        Store store = storeRepository.findByStoreIdx(active.getStoreIdx()).orElse(null);
        ActiveMstResponseDto base = toActiveResponse(active, store);
        Map<String, String> dates = approvalAckDateMapForActivity(actIdx);
        return base.withApprAck(new LinkedHashMap<>(dates), new ArrayList<>(dates.keySet()));
    }

    public List<ActiveMstResponseDto> listByStore(Integer storeIdx) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        List<ActActive> rows = actMstMapper.actList(ActiveListQuery.byStore(storeIdx));
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActiveResponse(active, store, userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    /**
     * 가맹점 지시사항 다이얼로그 — {@code store_idx} 일치, {@code appr_status=APPROVED},
     * {@code appr_notes} 비어 있지 않음.
     */
    public List<ActiveMstResponseDto> listByStoreApprMemo(int storeIdx) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        List<ActActive> rows = actMstMapper.actList(ActiveListQuery.byStoreApprMemo(storeIdx));
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActiveResponse(active, store, userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    public List<ActiveMstResponseDto> listByChkYn(Character chkYn) {
        List<ActActive> rows = actMstMapper.actList(ActiveListQuery.byChkYn(chkYn));
        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActiveResponse(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    public List<ActiveMstResponseDto> listBySuggestions() {
        List<ActActive> rows = actMstMapper.actList(ActiveListQuery.byApprStatus(STATUS_APPROVED));
        rows = rows.stream()
                .filter(active -> active.getSuggestions() != null
                        && !active.getSuggestions().isBlank())
                .collect(Collectors.toList());

        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActiveResponse(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    /**
     * 활동관리 > 지시사항(결재특이사항) — {@code appr_notes} 가 비어 있지 않고,
     * {@code appr_status} 가 {@code PENDING} 이 아니며, {@code sv_id} 가 기안(로그인) 사용자와 같음.
     */
    public List<ActiveMstResponseDto> listBySvAppr(String svId) {
        if (svId == null || svId.isBlank()) {
            return List.of();
        }
        String uid = svId.trim();
        List<ActActive> rows = actMstMapper.actList(ActiveListQuery.byDrafterMemo(uid));

        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActiveResponse(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    /**
     * 활동관리결재 > 지시사항(결재특이사항) — {@code appr_notes} 있음·비결재대기·
     * {@code notif_mst} 에 본인 알림이 있고 {@code appr_id}(CSV)에 본인이 포함된 활동만.
     */
    public List<ActiveMstResponseDto> listMemoInstructionsForApprover(String userId) {
        if (userId == null || userId.isBlank()) {
            return List.of();
        }
        String uid = userId.trim();
        List<ActActive> rows =
                actMstMapper.actListApprMemo(uid, TYPE_ACTIVITY_APPROVAL);

        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActiveResponse(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    @Transactional
    public ActiveMstResponseDto create(ActiveMstWriteRequestDto body) {
        int storeIdx = requireStoreIdx(body);
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        ActActive active = entityFromWrite(body);
        normalizeForSave(active);

        ActActive saved = actRepository.save(active);

        List<ChkResultDtlSaveDto> checklistRows = body.checklistResultsOrEmpty();
        if (!checklistRows.isEmpty()) {
            int inserted = saveChecklistResults(saved.getActIdx(), checklistRows);
            if (inserted > 0) {
                saved.setChkYn('Y');
                saved = actRepository.save(saved);
            }
        }

        maybeNotifyPendingApprovers(saved, body.getApprUserIds(), null);

        log.info("활동관리 생성 완료: {}", saved.getActIdx());
        return toActiveResponse(saved, store);
    }

    @Transactional
    public ActiveMstResponseDto update(Integer actIdx, ActiveMstWriteRequestDto body) {
        ActActive active = actRepository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));

        final String previousApprStatus = active.getApprStatus();

        applyActivityFromWrite(active, body);

        List<ChkResultDtlSaveDto> checklistRows = body.checklistResultsOrEmpty();
        if (!checklistRows.isEmpty()) {
            int inserted = saveChecklistResults(actIdx, checklistRows);
            if (inserted > 0) {
                active.setChkYn('Y');
            } else {
                active.setChkYn('N');
            }
        }
        normalizeForSave(active);

        Store store = storeRepository.findByStoreIdx(active.getStoreIdx())
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", active.getStoreIdx()));
        ActActive saved = actRepository.save(active);
        maybeNotifyPendingApprovers(saved, body.getApprUserIds(), previousApprStatus);
        log.info("활동관리 수정 완료: {}", saved.getActIdx());
        return toActiveResponse(saved, store);
    }

    private static int requireStoreIdx(ActiveMstWriteRequestDto b) {
        if (b.getStoreIdx() == null) {
            throw new IllegalArgumentException("storeIdx은(는) 필수입니다.");
        }
        if (b.getStoreIdx() <= 0) {
            throw new IllegalArgumentException("storeIdx은(는) 유효한 가맹점이어야 합니다.");
        }
        return b.getStoreIdx();
    }

    private ActActive entityFromWrite(ActiveMstWriteRequestDto b) {
        if (b.getActType() == null || b.getActType().isBlank()) {
            throw new IllegalArgumentException("actType은(는) 필수입니다.");
        }
        return ActActive.builder()
                .storeIdx(requireStoreIdx(b))
                .actType(b.getActType().trim())
                .actDt(b.getActDt())
                .actNotes(trimToNull(b.getActNotes()))
                .svId(trimToNull(b.getSvId()))
                .apprId(joinCsvDistinct(b.getApprUserIds()))
                .apprStatus(trimToNull(b.getApprStatus()))
                .memoTxt(trimToNull(b.getMemoTxt()))
                .apprDt(b.getApprDt())
                .suggestions(trimToNull(b.getSuggestions()))
                .svNotes(trimToNull(b.getSvNotes()))
                .chkYn(b.getChkYn())
                .apprNotes(trimToNull(b.getApprNotes()))
                .build();
    }

    private void applyActivityFromWrite(ActActive active, ActiveMstWriteRequestDto b) {
        if (b.isStoreIdxPresent()) {
            if (b.getStoreIdx() == null) {
                throw new IllegalArgumentException("storeIdx은(는) 필수입니다.");
            }
            if (b.getStoreIdx() <= 0) {
                throw new IllegalArgumentException("storeIdx은(는) 유효한 가맹점이어야 합니다.");
            }
            active.setStoreIdx(b.getStoreIdx());
        }
        if (b.isActTypePresent()) {
            if (b.getActType() == null || b.getActType().isBlank()) {
                throw new IllegalArgumentException("actType은(는) 필수입니다.");
            }
            active.setActType(b.getActType().trim());
        }
        if (b.isActDtPresent()) {
            active.setActDt(b.getActDt());
        }
        if (b.isActNotesPresent()) {
            active.setActNotes(trimToNull(b.getActNotes()));
        }
        if (b.isMemoTxtPresent()) {
            active.setMemoTxt(trimToNull(b.getMemoTxt()));
        }
        if (b.isSvIdPresent()) {
            active.setSvId(trimToNull(b.getSvId()));
        }
        if (b.isApprStatusPresent()) {
            active.setApprStatus(trimToNull(b.getApprStatus()));
        }
        if (b.isApprDtPresent()) {
            active.setApprDt(b.getApprDt());
        }
        if (b.isApprNotesPresent()) {
            active.setApprNotes(trimToNull(b.getApprNotes()));
        }
        if (b.isSuggestionsPresent()) {
            active.setSuggestions(trimToNull(b.getSuggestions()));
        }
        if (b.isSvNotesPresent()) {
            active.setSvNotes(trimToNull(b.getSvNotes()));
        }
        if (b.isApprUserIdsPresent()) {
            active.setApprId(joinCsvDistinct(b.getApprUserIds()));
        }
    }

    private static String trimToNull(String s) {
        if (s == null) {
            return null;
        }
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }

    /** 결재자 ID 목록을 CSV로 합침(공백 제거·중복 제거·순서 유지). */
    private static String joinCsvDistinct(List<String> ids) {
        if (ids == null || ids.isEmpty()) {
            return null;
        }
        Set<String> set = new LinkedHashSet<>();
        for (String raw : ids) {
            if (raw == null) {
                continue;
            }
            String t = raw.trim();
            if (!t.isEmpty()) {
                set.add(t);
            }
        }
        if (set.isEmpty()) {
            return null;
        }
        return String.join(",", set);
    }

    @Transactional
    public void remove(Integer actIdx) {
        ActActive active = actRepository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));

        deleteChecklistResults(actIdx);

        actRepository.delete(active);
        log.info("활동관리 삭제 완료: {}", actIdx);
    }

    private void normalizeForSave(ActActive active) {
        if (active.getApprStatus() == null || active.getApprStatus().isBlank()) {
            active.setApprStatus(STATUS_DRAFT);
        } else {
            active.setApprStatus(active.getApprStatus().trim().toUpperCase());
        }
        if (STATUS_APPROVED.equals(active.getApprStatus()) && active.getApprDt() == null) {
            active.setApprDt(LocalDateTime.now());
        }
    }

    private Map<Integer, Store> storesByIdx(List<ActActive> rows) {
        List<Integer> ids = rows.stream()
                .map(ActActive::getStoreIdx)
                .distinct()
                .collect(Collectors.toList());
        return storeRepository.findAllById(ids)
                .stream()
                .collect(Collectors.toMap(Store::getStoreIdx, store -> store));
    }

    private ActiveMstResponseDto toActiveResponse(ActActive active, Store store) {
        String svNm = null;
        String svDeptNm = null;
        if (active.getSvId() != null && !active.getSvId().isBlank()) {
            String[] wd = loadWriterNameAndDept(active.getSvId());
            svNm = wd[0];
            svDeptNm = wd[1];
        }
        return toActiveResponse(active, store, svNm, svDeptNm);
    }

    private ActiveMstResponseDto toActiveResponse(ActActive active, Store store, String svNm, String svDeptNm) {
        String ssvNm = store == null ? null : loadUserName(store.getSvId());
        return ActiveMstResponseDto.fromActive(
                active,
                store,
                svNm,
                svDeptNm,
                ssvNm,
                splitApprUserIdsCsv(active.getApprId()),
                null,
                null);
    }

    private List<String> splitApprUserIdsCsv(String apprId) {
        if (apprId == null || apprId.isBlank()) {
            return List.of();
        }
        return Arrays.stream(apprId.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .distinct()
                .toList();
    }

    private void maybeNotifyPendingApprovers(ActActive saved, List<String> apprUserIdsFromDto,
                                             String previousApprStatus) {
        if (saved.getApprStatus() == null
                || !STATUS_PENDING.equalsIgnoreCase(saved.getApprStatus().trim())) {
            return;
        }
        boolean wasAlreadyPending = previousApprStatus != null
                && STATUS_PENDING.equalsIgnoreCase(previousApprStatus.trim());
        if (wasAlreadyPending) {
            return;
        }
        List<String> ids = apprUserIdsFromDto;
        if (ids == null || ids.isEmpty()) {
            ids = splitApprUserIdsCsv(saved.getApprId());
        }
        if (ids == null || ids.isEmpty()) {
            return;
        }
        notifyActivityApprovers(saved.getActIdx(), ids);
    }
    
    /** 실제 insert 된 체크리스트 행 수({@code chkIdx} 가 있는 항목만). */
    private int saveChecklistResults(Integer actIdx, List<ChkResultDtlSaveDto> results) {
        int inserted = 0;
        for (ChkResultDtlSaveDto result : results) {
            if (result.chkIdx() == null) {
                continue;
            }
            int score = result.answerScore() != null ? result.answerScore() : 0;
            actMstMapper.insChkDtl(actIdx, result.chkIdx(), result.answerVal(), score);
            inserted++;
        }

        log.info("체크리스트 결과 저장 완료: actIdx={}, 저장건수={}", actIdx, inserted);
        return inserted;
    }

    private void deleteChecklistResults(Integer actIdx) {
        int deleted = actMstMapper.delChkDtlByAct(actIdx);
        log.info("체크리스트 결과 삭제 완료: actIdx={}, 삭제된 항목수={}", actIdx, deleted);
    }

    private Map<String, String> loadUserNames(List<ActActive> activities) {
        List<String> userIds = activities.stream()
                .map(ActActive::getSvId)
                .filter(svId -> svId != null && !svId.isBlank())
                .distinct()
                .collect(Collectors.toList());

        if (userIds.isEmpty()) {
            return Map.of();
        }

        Map<String, String> result = new LinkedHashMap<>();
        for (UserIdNameRow row : actMstMapper.userNamesByIds(userIds)) {
            result.put(row.userId(), row.userName());
        }
        return result;
    }

    private String[] loadWriterNameAndDept(String svId) {
        String[] empty = new String[]{null, null};
        if (svId == null || svId.isBlank()) {
            return empty;
        }
        String uid = svId.trim();
        try {
            UserWriterDeptRow row = actMstMapper.writerDept(uid);
            if (row == null) {
                return new String[]{loadUserName(uid), null};
            }
            return new String[]{row.userName(), row.deptNm()};
        } catch (Exception e) {
            log.warn("작성자 이름·부서 조회 실패: svId={}", uid, e);
            return new String[]{loadUserName(uid), null};
        }
    }

    private String loadUserName(String userId) {
        if (userId == null || userId.isBlank()) {
            return null;
        }

        try {
            return actMstMapper.userName(userId);
        } catch (Exception e) {
            log.warn("사용자 이름 조회 실패: userId={}", userId);
            return null;
        }
    }

    public List<ChkResultRowDto> chkResults(Integer actIdx) {
        return actMstMapper.chkResultRows(actIdx);
    }

    // --- notifications ---

    public List<NotifMstDto> listForUser(String userId) {
        if (userId == null || userId.isBlank()) {
            return List.of();
        }
        return actMstMapper.notifList(userId.trim());
    }

    public long countUnread(String userId) {
        if (userId == null || userId.isBlank()) {
            return 0;
        }
        return actMstMapper.notifUnreadCnt(userId.trim());
    }

    @Transactional(readOnly = false)
    public void markRead(Long notifIdx, String userId) {
        if (notifIdx == null || userId == null || userId.isBlank()) {
            return;
        }
        actNotifRepository.findById(notifIdx).ifPresent(n -> {
            if (userId.trim().equals(n.getUserId())) {
                n.setReadYn('Y');
                actNotifRepository.save(n);
            }
        });
    }

    @Transactional(readOnly = false)
    public void markActivityApprovalAcknowledged(String userId, Integer actIdx, String apprNotes) {
        if (userId == null || userId.isBlank() || actIdx == null) {
            return;
        }
        String uid = userId.trim();
        ActActive active = actRepository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));

        String apprStatus = active.getApprStatus() == null ? "" : active.getApprStatus().trim();
        if (!STATUS_PENDING.equalsIgnoreCase(apprStatus)) {
            throw new IllegalArgumentException("결재대기 상태에서만 결재할 수 있습니다.");
        }

        String svId = active.getSvId() == null ? "" : active.getSvId().trim();
        if (!svId.isEmpty() && uid.equals(svId)) {
            throw new IllegalArgumentException("기안자는 결재하기를 사용할 수 없습니다. 지정된 결재자만 결재합니다.");
        }

        List<String> peers = splitApprUserIdsCsv(active.getApprId());
        if (peers.isEmpty()) {
            throw new IllegalArgumentException("상신된 결재자 목록이 비어 있어 결재를 확인할 수 없습니다.");
        }

        int notifTotal =
                actMstMapper.apprNotifCnt(actIdx, uid, TYPE_ACTIVITY_APPROVAL);
        if (notifTotal == 0) {
            throw new IllegalArgumentException(
                    "해당 활동으로 본인 계정에 온 결재 알림이 없어 결재할 수 없습니다.");
        }
        int notifPending =
                actMstMapper.apprNotifPendingCnt(actIdx, uid, TYPE_ACTIVITY_APPROVAL);
        if (notifPending == 0) {
            throw new IllegalArgumentException("이미 결재 처리된 건입니다.");
        }

        int updated = actMstMapper.apprNotifSetYn(
                uid, actIdx, TYPE_ACTIVITY_APPROVAL, "Y");
        if (updated == 0) {
            throw new IllegalArgumentException("결재 반영에 실패했습니다. 잠시 후 다시 시도해 주세요.");
        }

        boolean needsActiveSave = false;
        // 지시사항(결재특이사항): 요청에 apprNotes 가 있으면 화면 전문으로 덮어쓴다(줄 단위 병합 금지 — 중복 누적 방지).
        if (apprNotes != null) {
            active.setApprNotes(trimToNull(apprNotes));
            needsActiveSave = true;
        }

        int ackedDistinct = actMstMapper.apprCsvAckCnt(actIdx, TYPE_ACTIVITY_APPROVAL, peers);
        if (ackedDistinct >= peers.size()) {
            active.setApprDt(LocalDateTime.now());
            active.setApprStatus("APPROVED");
            needsActiveSave = true;
        }
        if (needsActiveSave) {
            actRepository.save(active);
        }
    }

    /**
     * 결재 확인일(표시용) — {@code notif_mst} 에서 {@code appr_yn = 'Y'} 인 행만 사용.
     * '결재자에 추가되었습니다…' 처럼 {@code appr_yn = 'N'} 인 대기 알림은 제외한다(미결재자 도장 오표시 방지).
     */
    public Map<String, String> approvalAckDateMapForActivity(Integer actIdx) {
        if (actIdx == null) {
            return Map.of();
        }
        List<ActNotifAckDateRow> rows =
                actMstMapper.apprAckDays(actIdx, TYPE_ACTIVITY_APPROVAL, true);
        Map<String, String> out = new LinkedHashMap<>();
        for (ActNotifAckDateRow r : rows) {
            String rowUid = r.userId();
            if (rowUid == null || rowUid.isBlank()) {
                continue;
            }
            LocalDate d = r.createDay();
            String day = d != null ? d.toString() : "";
            out.put(rowUid.trim(), day);
        }
        return out;
    }

    @Transactional(readOnly = false)
    public void notifyActivityApprovers(Integer actIdx, List<String> apprUserIds) {
        if (actIdx == null || apprUserIds == null || apprUserIds.isEmpty()) {
            return;
        }
        LinkedHashSet<String> distinct = new LinkedHashSet<>();
        for (String raw : apprUserIds) {
            if (raw == null) {
                continue;
            }
            String id = raw.trim();
            if (!id.isEmpty()) {
                distinct.add(id);
            }
        }
        if (distinct.isEmpty()) {
            return;
        }

        String msg = "결재자에 추가되었습니다. 결재 대기 중인 활동내역이 있습니다.";
        for (String uid : distinct) {
            ActNotif n = ActNotif.builder()
                    .userId(uid)
                    .msgTxt(msg)
                    .notifTyp(TYPE_ACTIVITY_APPROVAL)
                    .actIdx(actIdx)
                    .apprYn("N")
                    .build();
            actNotifRepository.save(n);
        }
    }

    // --- checklist master ---

    @Transactional
    public ChkMstResponseDto createChecklist(ChkMstWriteRequestDto body) {
        Character useYnRaw = body.useYn();
        Character useYn = useYnRaw == null ? 'N' : Character.toUpperCase(useYnRaw);
        Integer baseScore = body.baseScore();
        if (baseScore == null) {
            baseScore = 0;
        }
        String brandCd = body.brandCd().trim();
        String chkType = body.chkType().trim();
        String chkContent = body.chkContent().trim();
        ChkMstInsertHolder holder = new ChkMstInsertHolder();
        holder.setBrandCd(brandCd);
        holder.setChkType(chkType);
        holder.setChkContent(chkContent);
        holder.setBaseScore(baseScore);
        holder.setUseYn(useYn);
        actMstMapper.insChkMst(holder);
        Integer chkIdx = holder.getChkIdx();
        if (chkIdx == null) {
            throw new IllegalStateException("chk_mst INSERT 후 chk_idx를 읽지 못했습니다.");
        }
        return getChecklist(chkIdx);
    }

    @Transactional
    public ChkMstResponseDto updateChecklist(Integer chkIdx, ChkMstWriteRequestDto body) {
        Character useYnRaw = body.useYn();
        Character useYn = useYnRaw == null ? 'N' : Character.toUpperCase(useYnRaw);
        Integer baseScore = body.baseScore();
        if (baseScore == null) {
            baseScore = 0;
        }
        String brandCd = body.brandCd().trim();
        String chkType = body.chkType().trim();
        String chkContent = body.chkContent().trim();
        int updated = actMstMapper.updChkMst(chkIdx, brandCd, chkType, chkContent, baseScore, useYn);
        if (updated == 0) {
            throw new ResourceNotFoundException("체크리스트", "chkIdx", chkIdx);
        }
        return getChecklist(chkIdx);
    }

    public List<ChkMstResponseDto> getChecklists(String brandCd, String chkType) {
        String b = brandCd != null && !brandCd.isBlank() ? brandCd.trim() : null;
        String t = chkType != null && !chkType.isBlank() ? chkType.trim() : null;
        return actMstMapper.chkMstList(b, t);
    }

    private ChkMstResponseDto getChecklist(Integer chkIdx) {
        ChkMstResponseDto row = actMstMapper.chkMstOne(chkIdx);
        if (row == null) {
            throw new ResourceNotFoundException("체크리스트", "chkIdx", chkIdx);
        }
        return row;
    }
}
