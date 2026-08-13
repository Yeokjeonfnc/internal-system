package com.yeokjeon.erp.master.service;

import com.yeokjeon.erp.master.dto.UserPageFilterDto;
import com.yeokjeon.erp.master.dto.UserPageFilterSaveRequestDto;
import com.yeokjeon.erp.master.mapper.UserPageFilterMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
public class UserPageFilterService {

    private final UserPageFilterMapper userPageFilterMapper;

    public UserPageFilterDto get(String userId, String pageCode) {
        Integer userIdx = findUserIdx(userId);
        return userPageFilterMapper.selectByUserIdxAndPageCode(userIdx, normalizePageCode(pageCode));
    }

    @Transactional
    public UserPageFilterDto save(String userId, UserPageFilterSaveRequestDto body) {
        Integer userIdx = findUserIdx(userId);
        String pageCode = normalizePageCode(body.pageCode());
        userPageFilterMapper.upsert(userIdx, pageCode, body.filterJson());
        return new UserPageFilterDto(pageCode, body.filterJson());
    }

    private Integer findUserIdx(String userId) {
        if (!StringUtils.hasText(userId)) {
            throw new IllegalArgumentException("userId는 필수입니다.");
        }
        Integer userIdx = userPageFilterMapper.selectUserIdxByUserId(userId.trim());
        if (userIdx == null) {
            throw new IllegalArgumentException("사용자를 찾을 수 없습니다.");
        }
        return userIdx;
    }

    private String normalizePageCode(String pageCode) {
        if (!StringUtils.hasText(pageCode)) {
            throw new IllegalArgumentException("pageCode는 필수입니다.");
        }
        return pageCode.trim().toUpperCase();
    }
}
