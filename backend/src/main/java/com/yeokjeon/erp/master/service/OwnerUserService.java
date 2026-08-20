package com.yeokjeon.erp.master.service;

import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.master.dto.OwnerUserListJdbcRow;
import com.yeokjeon.erp.master.dto.OwnerUserMstCreateRequestDto;
import com.yeokjeon.erp.master.dto.OwnerUserMstDto;
import com.yeokjeon.erp.master.dto.OwnerUserMstUpdateRequestDto;
import com.yeokjeon.erp.master.entity.MstUser;
import com.yeokjeon.erp.master.mapper.MstOwnerUserMapper;
import com.yeokjeon.erp.master.repository.MstUserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import com.yeokjeon.erp.auth.password.PasswordHasher;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class OwnerUserService {

    private final MstUserRepository mstUserRepository;
    private final MstOwnerUserMapper mstOwnerUserMapper;
    private final PasswordHasher passwordHasher;

    public List<OwnerUserMstDto> getAll() {
        return mstOwnerUserMapper.selectOwnerUsers().stream()
                .map(OwnerUserMstDto::fromJdbcRow)
                .collect(Collectors.toList());
    }

    public OwnerUserMstDto get(int userIdx) {
        OwnerUserListJdbcRow row = mstOwnerUserMapper.selectOwnerUserById(userIdx);
        if (row == null) {
            throw new ResourceNotFoundException("가맹점주", "userIdx", userIdx);
        }
        return OwnerUserMstDto.fromJdbcRow(row);
    }

    @Transactional
    public OwnerUserMstDto save(OwnerUserMstCreateRequestDto body) {
        String userId = trimToNull(body.userId());
        ensureUserIdAvailable(userId, null);
        MstUser user = MstUser.builder()
                .userName(body.userName().trim())
                .userId(userId)
                // 비밀번호는 절대 평문으로 저장하지 않는다.
                .userPassword(passwordHasher.hash(body.userPassword()))
                .userPhone(trimToNull(body.userPhone()))
                .userEmail(trimToNull(body.userEmail()))
                .ownerYn('Y')
                .svYn('N')
                .storeIdx(body.storeIdx())
                .build();
        MstUser saved = mstUserRepository.save(user);
        log.info("가맹점주 생성 완료: userIdx={}", saved.getUserIdx());
        return loadDtoAfterSave(saved.getUserIdx());
    }

    @Transactional
    public OwnerUserMstDto save(int userIdx, OwnerUserMstUpdateRequestDto body) {
        MstUser user = findOwnerOrThrow(userIdx);
        if (body.isUserNamePresent()) {
            user.setUserName(trimToNull(body.getUserName()));
        }
        if (body.isUserIdPresent()) {
            String nextUserId = trimToNull(body.getUserId());
            ensureUserIdAvailable(nextUserId, userIdx);
            user.setUserId(nextUserId);
        }
        String pw = body.getUserPassword();
        if (pw != null && !pw.isBlank()) {
            user.setUserPassword(passwordHasher.hash(pw));
        }
        if (body.isUserPhonePresent()) {
            user.setUserPhone(trimToNull(body.getUserPhone()));
        }
        if (body.isUserEmailPresent()) {
            user.setUserEmail(trimToNull(body.getUserEmail()));
        }
        if (body.isStoreIdxPresent()) {
            user.setStoreIdx(body.getStoreIdx());
        }
        user.setOwnerYn('Y');
        MstUser saved = mstUserRepository.save(user);
        log.info("가맹점주 수정 완료: userIdx={}", saved.getUserIdx());
        return loadDtoAfterSave(saved.getUserIdx());
    }

    @Transactional
    public void remove(int userIdx) {
        MstUser user = findOwnerOrThrow(userIdx);
        mstUserRepository.delete(user);
        log.info("가맹점주 삭제 완료: userIdx={}", userIdx);
    }

    /**
     * 로그인ID 중복 확인 — {@code user_mst.user_id} 는 UNIQUE 라 그대로 저장하면
     * 제약 위반이 GlobalExceptionHandler 에서 "서버 오류가 발생했습니다" 로 가려져
     * 사용자가 무엇이 잘못됐는지 알 수 없다. 등록 화면에만 있는 중복확인 버튼은
     * 상세 수정·API 직접 호출을 막지 못하므로 서버에서 한 번 더 거른다.
     *
     * @param excludeUserIdx 수정 대상 본인(자기 ID 를 그대로 다시 저장하는 경우) — 등록이면 null
     */
    private void ensureUserIdAvailable(String userId, Integer excludeUserIdx) {
        if (userId == null) {
            return;
        }
        mstUserRepository.findByUserId(userId).ifPresent(existing -> {
            if (excludeUserIdx == null || !excludeUserIdx.equals(existing.getUserIdx())) {
                throw new IllegalArgumentException("이미 사용 중인 로그인 ID 입니다: " + userId);
            }
        });
    }

    private MstUser findOwnerOrThrow(int userIdx) {
        MstUser user = mstUserRepository.findById(userIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점주", "userIdx", userIdx));
        if (user.getOwnerYn() == null || user.getOwnerYn() != 'Y') {
            throw new ResourceNotFoundException("가맹점주", "userIdx", userIdx);
        }
        return user;
    }

    private OwnerUserMstDto loadDtoAfterSave(int userIdx) {
        OwnerUserListJdbcRow row = mstOwnerUserMapper.selectOwnerUserById(userIdx);
        if (row == null) {
            throw new ResourceNotFoundException("가맹점주", "userIdx", userIdx);
        }
        return OwnerUserMstDto.fromJdbcRow(row);
    }

    private static String trimToNull(String s) {
        if (s == null) {
            return null;
        }
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }
}
