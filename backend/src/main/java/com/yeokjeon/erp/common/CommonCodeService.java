package com.yeokjeon.erp.common;

import com.yeokjeon.erp.common.dto.CodeMstDto;
import com.yeokjeon.erp.common.mapper.CodeMstMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CommonCodeService {

    private final CodeMstMapper codeMstMapper;

    public List<CodeMstDto> getCodesByGroup(int grpCd) {
        return codeMstMapper.selectByGrpCd(grpCd);
    }
}
