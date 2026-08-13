package com.yeokjeon.erp.eap.service;

import com.yeokjeon.erp.eap.dto.EapFormConfigDto;
import com.yeokjeon.erp.eap.dto.EapFormConfigJdbcRow;
import com.yeokjeon.erp.eap.dto.EapFormConfigSaveRequestDto;
import com.yeokjeon.erp.eap.dto.EapFormConfigUpdateRequestDto;
import com.yeokjeon.erp.eap.mapper.EapFormConfigMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class EapFormConfigService {

    private final EapFormConfigMapper eapFormConfigMapper;

    @Transactional(readOnly = true)
    public List<EapFormConfigDto> listAll() {
        return eapFormConfigMapper.selectAll().stream()
                .map(EapFormConfigDto::fromRow)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<EapFormConfigDto> listEnabled() {
        return eapFormConfigMapper.selectEnabled().stream()
                .map(EapFormConfigDto::fromRow)
                .toList();
    }

    @Transactional(readOnly = true)
    public EapFormConfigDto find(String formCode) {
        EapFormConfigJdbcRow row = eapFormConfigMapper.selectByCode(formCode);
        if (row == null) {
            throw new IllegalArgumentException("양식 코드를 찾을 수 없습니다: " + formCode);
        }
        return EapFormConfigDto.fromRow(row);
    }

    @Transactional
    public EapFormConfigDto create(EapFormConfigSaveRequestDto body) {
        if (eapFormConfigMapper.selectByCode(body.formCode().trim()) != null) {
            throw new IllegalArgumentException("이미 등록된 양식 코드입니다: " + body.formCode());
        }
        eapFormConfigMapper.insert(body);
        return find(body.formCode().trim());
    }

    @Transactional
    public EapFormConfigDto update(String formCode, EapFormConfigUpdateRequestDto body) {
        if (eapFormConfigMapper.selectByCode(formCode) == null) {
            throw new IllegalArgumentException("양식 코드를 찾을 수 없습니다: " + formCode);
        }
        eapFormConfigMapper.update(formCode, body);
        return find(formCode);
    }

    @Transactional
    public void delete(String formCode) {
        if (eapFormConfigMapper.delete(formCode) == 0) {
            throw new IllegalArgumentException("양식 코드를 찾을 수 없습니다: " + formCode);
        }
    }
}
