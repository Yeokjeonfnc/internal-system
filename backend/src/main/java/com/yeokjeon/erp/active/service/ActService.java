package com.yeokjeon.erp.active.service;

import com.yeokjeon.erp.active.dto.ActNotifAckDateRow;
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
        String normalizedBrand = normalizeBrand(brandCd);
        return actMstMapper.selectStatusByStore(startDt, endDt, normalizedBrand);
    }

    public List<ActivityStatusPivotRowDto> statusBySv(LocalDate startDt, LocalDate endDt, String brandCd) {
        String normalizedBrand = normalizeBrand(brandCd);
        return actMstMapper.selectStatusBySv(startDt, endDt, normalizedBrand);
    }

    public List<ActiveMstResponseDto> listAll() {
        List<ActActive> rows = actMstMapper.selectAllActivities();
        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActiveResponse(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    public List<ActiveMstResponseDto> listByStatus(String apprStatus, String svId, String relUserId) {
        List<ActActive> rows = actMstMapper.selectActivitiesByApprStatus(apprStatus);

        if ("DRAFT".equals(apprStatus) && svId != null && !svId.isBlank()) {
            rows = rows.stream()
                    .filter(active -> svId.equals(active.getSvId()))
                    .collect(Collectors.toList());
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
        String apprStatus = base.apprStatus() == null ? "" : base.apprStatus();
        Map<String, String> dates =
                approvalAckDateMapForActivity(actIdx, apprStatus);
        return base.withApprAck(new LinkedHashMap<>(dates), new ArrayList<>(dates.keySet()));
    }

    public List<ActiveMstResponseDto> listByStore(Integer storeIdx) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        List<ActActive> rows = actMstMapper.selectActivitiesByStoreIdx(storeIdx);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActiveResponse(active, store, userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    public List<ActiveMstResponseDto> listByChkYn(Character chkYn) {
        List<ActActive> rows = actMstMapper.selectActivitiesByChkYn(chkYn);
        Map<Integer, Store> stores = storesByIdx(rows);
        Map<String, String> userNames = loadUserNames(rows);

        return rows.stream()
                .map(active -> toActiveResponse(active, stores.get(active.getStoreIdx()),
                        userNames.get(active.getSvId()), null))
                .collect(Collectors.toList());
    }

    public List<ActiveMstResponseDto> listBySuggestions() {
        List<ActActive> rows = actMstMapper.selectActivitiesByApprStatus(STATUS_APPROVED);
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
     * 지시사항(결재특이사항) — {@code active_mst.appr_note} 가 비어 있지 않고,
     * {@code sv_id} 가 로그인 사용자(요청 파라미터 {@code svId})와 같은 행만.
     */
    public List<ActiveMstResponseDto> listBySvAppr(String svId) {
        if (svId == null || svId.isBlank()) {
            return List.of();
        }
        String uid = svId.trim();
        List<ActActive> rows = actMstMapper.selectActivitiesBySvForApprNotes(uid).stream()
                .filter(active -> active.getApprNotes() != null && !active.getApprNotes().isBlank())
                .collect(Collectors.toList());

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
            saveChecklistResults(saved.getActIdx(), checklistRows);
            saved.setRChkId(saved.getActIdx());
            saved.setChkYn('Y');
            saved = actRepository.save(saved);
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
            if (active.getRChkId() != null) {
                deleteChecklistResults(actIdx);
            }
            saveChecklistResults(actIdx, checklistRows);
            active.setChkYn('Y');
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
                .rChkId(b.getRChkId())
                .chkYn(b.getChkYn())
                .apprNotes(trimToNull(b.getApprNotes()))
                .build();
    }

    private void applyActivityFromWrite(ActActive active, ActiveMstWriteRequestDto b) {
        if (b.isStoreIdxPresent()) {
            if (b.getStoreIdx() == null) {
                throw new IllegalArgumentException("storeIdx은(는) 필수입니다.");
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
        if (active.getChkYn() == null) {
            active.setChkYn('N');
        }
        if (STATUS_APPROVED.equals(active.getApprStatus()) && active.getApprDt() == null) {
            active.setApprDt(LocalDateTime.now());
        }
    }

    private String normalizeBrand(String brandCd) {
        if (brandCd == null || brandCd.isBlank()) return null;
        return brandCd.trim();
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

    private void saveChecklistResults(Integer actIdx, List<ChkResultDtlSaveDto> results) {
        for (ChkResultDtlSaveDto result : results) {
            if (result.chkIdx() == null) {
                continue;
            }
            int score = result.answerScore() != null ? result.answerScore() : 0;
            actMstMapper.insertChkResultDtl(actIdx, result.chkIdx(), result.answerVal(), score);
        }

        log.info("체크리스트 결과 저장 완료: actIdx={}, 항목수={}", actIdx, results.size());
    }

    private void deleteChecklistResults(Integer actIdx) {
        int deleted = actMstMapper.deleteChkResultDtlByActIdx(actIdx);
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
        for (UserIdNameRow row : actMstMapper.selectUserNamesByIds(userIds)) {
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
            UserWriterDeptRow row = actMstMapper.selectWriterAndDept(uid);
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
            return actMstMapper.selectUserName(userId);
        } catch (Exception e) {
            log.warn("사용자 이름 조회 실패: userId={}", userId);
            return null;
        }
    }

    public List<ChkResultRowDto> chkResults(Integer actIdx) {
        return actMstMapper.selectChkResultsForActivity(actIdx);
    }

    // --- notifications ---

    public List<NotifMstDto> listForUser(String userId) {
        if (userId == null || userId.isBlank()) {
            return List.of();
        }
        return actMstMapper.selectNotifsForUser(userId.trim());
    }

    public long countUnread(String userId) {
        if (userId == null || userId.isBlank()) {
            return 0;
        }
        return actMstMapper.countUnreadNotifsForUser(userId.trim());
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
    public void markActivityApprovalAcknowledged(String userId, Integer actIdx) {
        if (userId == null || userId.isBlank() || actIdx == null) {
            return;
        }
        String uid = userId.trim();
        int updated =
                actMstMapper.updateApprYnForUserActivityNotifs(uid, actIdx, TYPE_ACTIVITY_APPROVAL, "Y");
        if (updated == 0) {
            ActNotif ack = ActNotif.builder()
                    .userId(uid)
                    .msgTxt("활동 결재 확인")
                    .notifTyp(TYPE_ACTIVITY_APPROVAL)
                    .actIdx(actIdx)
                    .apprYn("Y")
                    .readYn('Y')
                    .build();
            actNotifRepository.save(ack);
        }
        actRepository.findById(actIdx).ifPresent(active -> {
            active.setApprDt(LocalDateTime.now());
            active.setApprStatus("APPROVED");
            actRepository.save(active);
        });
    }

    /**
     * 결재 확인일(표시용) — user_id → yyyy-MM-dd.
     * <ul>
     *     <li>결재대기 등: {@code appr_yn = 'Y'} 인 행만 (앱에서 도장·결재일자 표시).</li>
     *     <li>결재완료: 같은 활동의 {@code ACTIVITY_APPROVAL} 알림은 {@code appr_yn} 과 관계없이 포함.
     *     DB에서 직접 상신 없이 {@code APPROVED} 처리된 경우 등, 알림은 있는데 {@code appr_yn} 이 N 인 행도 상세에 반영.</li>
     * </ul>
     */
    public Map<String, String> approvalAckDateMapForActivity(Integer actIdx, String apprStatus) {
        if (actIdx == null) {
            return Map.of();
        }
        boolean approvedDoc = apprStatus != null && "APPROVED".equalsIgnoreCase(apprStatus.trim());
        List<ActNotifAckDateRow> rows =
                actMstMapper.selectApprovalAckDateRows(actIdx, TYPE_ACTIVITY_APPROVAL, !approvedDoc);
        Map<String, String> out = new LinkedHashMap<>();
        for (ActNotifAckDateRow r : rows) {
            String uid = r.userId();
            if (uid == null || uid.isBlank()) {
                continue;
            }
            LocalDate d = r.createDay();
            String day = d != null ? d.toString() : "";
            out.put(uid.trim(), day);
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
        actMstMapper.insertChkMst(holder);
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
        int updated = actMstMapper.updateChkMst(chkIdx, brandCd, chkType, chkContent, baseScore, useYn);
        if (updated == 0) {
            throw new ResourceNotFoundException("체크리스트", "chkIdx", chkIdx);
        }
        return getChecklist(chkIdx);
    }

    public List<ChkMstResponseDto> getChecklists(String brandCd, String chkType) {
        String b = brandCd != null && !brandCd.isBlank() ? brandCd.trim() : null;
        String t = chkType != null && !chkType.isBlank() ? chkType.trim() : null;
        return actMstMapper.selectChkMstList(b, t);
    }

    private ChkMstResponseDto getChecklist(Integer chkIdx) {
        ChkMstResponseDto row = actMstMapper.selectChkMstOne(chkIdx);
        if (row == null) {
            throw new ResourceNotFoundException("체크리스트", "chkIdx", chkIdx);
        }
        return row;
    }
}
