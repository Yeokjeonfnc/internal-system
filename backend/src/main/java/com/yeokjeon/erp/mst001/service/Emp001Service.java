package com.yeokjeon.erp.mst001.service;

import com.yeokjeon.erp.common.RequestMapUtil;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.mst001.entity.User;
import com.yeokjeon.erp.mst001.repository.UserListRow;
import com.yeokjeon.erp.mst001.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class Emp001Service {

    private final UserRepository userRepository;

    public List<Map<String, Object>> getAll(Integer deptIdx) {
        return userRepository.findAllEnriched(deptIdx).stream()
                .map(this::toRow)
                .collect(Collectors.toList());
    }

    public Map<String, Object> get(int userIdx) {
        UserListRow row = userRepository.findEnrichedById(userIdx)
                .orElseThrow(() -> new ResourceNotFoundException("사용자", "userIdx", userIdx));
        return toRow(row);
    }

    public boolean free(String userId) {
        if (userId == null || userId.isBlank()) {
            return true;
        }
        return userRepository.findByUserId(userId.trim()).isEmpty();
    }

    @Transactional
    public Map<String, Object> save(Map<String, Object> body) {
        Character sv = RequestMapUtil.optChar(body, "svYn");
        Character tag = RequestMapUtil.optChar(body, "tagYn");
        User user = User.builder()
                .userName(RequestMapUtil.reqStr(body, "userName"))
                .userId(RequestMapUtil.optStr(body, "userId"))
                .userPassword(RequestMapUtil.reqStr(body, "userPassword"))
                .deptIdx(RequestMapUtil.optInt(body, "deptIdx"))
                .userPhone(RequestMapUtil.optStr(body, "userPhone"))
                .userEmail(RequestMapUtil.optStr(body, "userEmail"))
                .svYn(sv != null ? sv : 'N')
                .positionCd(RequestMapUtil.optStr(body, "positionCd"))
                .tagYn(tag != null ? tag : 'N')
                .joinDt(RequestMapUtil.optLocalDate(body, "joinDt"))
                .build();
        normalize(user);
        User saved = userRepository.save(user);
        log.info("사용자 생성 완료: {}", saved.getUserIdx());
        return get(saved.getUserIdx());
    }

    @Transactional
    public Map<String, Object> save(int userIdx, Map<String, Object> body) {
        User user = userRepository.findById(userIdx)
                .orElseThrow(() -> new ResourceNotFoundException("사용자", "userIdx", userIdx));
        if (body.containsKey("userName")) {
            user.setUserName(RequestMapUtil.optStr(body, "userName"));
        }
        if (body.containsKey("userId")) {
            user.setUserId(RequestMapUtil.optStr(body, "userId"));
        }
        String pw = RequestMapUtil.optStr(body, "userPassword");
        if (pw != null && !pw.isBlank()) {
            user.setUserPassword(pw);
        }
        if (body.containsKey("deptIdx")) {
            user.setDeptIdx(RequestMapUtil.optInt(body, "deptIdx"));
        }
        if (body.containsKey("userPhone")) {
            user.setUserPhone(RequestMapUtil.optStr(body, "userPhone"));
        }
        if (body.containsKey("userEmail")) {
            user.setUserEmail(RequestMapUtil.optStr(body, "userEmail"));
        }
        if (body.containsKey("svYn")) {
            user.setSvYn(RequestMapUtil.optChar(body, "svYn"));
        }
        if (body.containsKey("positionCd")) {
            user.setPositionCd(RequestMapUtil.optStr(body, "positionCd"));
        }
        if (body.containsKey("tagYn")) {
            user.setTagYn(RequestMapUtil.optChar(body, "tagYn"));
        }
        if (body.containsKey("joinDt")) {
            user.setJoinDt(RequestMapUtil.optLocalDate(body, "joinDt"));
        }
        normalize(user);
        User saved = userRepository.save(user);
        log.info("사용자 수정 완료: {}", saved.getUserIdx());
        return get(saved.getUserIdx());
    }

    @Transactional
    public void remove(int userIdx) {
        User user = userRepository.findById(userIdx)
                .orElseThrow(() -> new ResourceNotFoundException("사용자", "userIdx", userIdx));
        userRepository.delete(user);
        log.info("사용자 삭제 완료: {}", userIdx);
    }

    private void normalize(User user) {
        if (user.getSvYn() == null) {
            user.setSvYn('N');
        }
        if (user.getTagYn() == null) {
            user.setTagYn('N');
        }
    }

    private Map<String, Object> toRow(UserListRow r) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("userIdx", r.getUserIdx());
        m.put("userName", r.getUserName());
        m.put("userId", r.getUserId());
        m.put("deptIdx", r.getDeptIdx());
        m.put("deptNm", r.getDeptNm());
        m.put("userPhone", r.getUserPhone());
        m.put("userEmail", r.getUserEmail());
        m.put("svYn", firstChar(r.getSvYn()));
        m.put("positionCd", r.getPositionCd());
        m.put("positionNm", r.getPositionNm());
        m.put("tagYn", firstChar(r.getTagYn()));
        m.put("joinDt", r.getJoinDt());
        m.put("createdAt", r.getCreatedAt());
        m.put("updatedAt", r.getUpdatedAt());
        return m;
    }

    private static Character firstChar(String s) {
        if (s == null || s.isEmpty()) {
            return null;
        }
        return s.charAt(0);
    }
}
