package com.yeokjeon.erp.auth.service;

import com.yeokjeon.erp.auth.dto.AuthLoginRequestDto;
import com.yeokjeon.erp.auth.dto.AuthProfileDto;
import com.yeokjeon.erp.auth.dto.AuthProfileUpdateRequestDto;
import com.yeokjeon.erp.auth.mapper.AuthProfileMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final AuthProfileMapper authProfileMapper;

    public AuthProfileDto login(AuthLoginRequestDto body) {
        String userId = body.userId();
        String userPassword = body.userPassword();
        try {
            return authProfileMapper.selectByUserIdAndPassword(userId, userPassword);
        } catch (Exception e) {
            log.error("로그인 실패: userId={}, error={}", userId, e.getMessage());
            return null;
        }
    }

    @Transactional
    public AuthProfileDto updateUserProfile(String userId, AuthProfileUpdateRequestDto body) {
        int updated = authProfileMapper.updateProfile(userId, body);

        if (updated > 0) {
            log.info("사용자 정보 수정 완료: userId={}", userId);
            return getUserProfile(userId);
        }

        log.error("사용자 정보 수정 실패: userId={}", userId);
        return null;
    }

    public AuthProfileDto getUserProfile(String userId) {
        try {
            return authProfileMapper.selectByUserId(userId);
        } catch (Exception e) {
            log.error("사용자 정보 조회 실패: userId={}, error={}", userId, e.getMessage());
            return null;
        }
    }
}
