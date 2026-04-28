package com.yeokjeon.erp.partner.service;

import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.partner.dto.PartnerRequestDto;
import com.yeokjeon.erp.partner.dto.PartnerResponseDto;
import com.yeokjeon.erp.partner.entity.Partner;
import com.yeokjeon.erp.partner.repository.PartnerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PartnerService {

    private final PartnerRepository partnerRepository;

    public List<PartnerResponseDto> getAllPartners() {
        return partnerRepository.findAllPartners()
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public PartnerResponseDto getPartner(Integer partnerIdx) {
        Partner partner = partnerRepository.findById(partnerIdx)
                .orElseThrow(() -> new ResourceNotFoundException("예비창업자", "partnerIdx", partnerIdx));
        return toDto(partner);
    }

    @Transactional
    public PartnerResponseDto createPartner(PartnerRequestDto dto) {
        Partner saved = partnerRepository.save(dto.toEntity());
        log.info("예비창업자 생성 완료: {}", saved.getPartnerIdx());
        return toDto(saved);
    }

    @Transactional
    public PartnerResponseDto updatePartner(Integer partnerIdx, PartnerRequestDto dto) {
        Partner partner = partnerRepository.findById(partnerIdx)
                .orElseThrow(() -> new ResourceNotFoundException("예비창업자", "partnerIdx", partnerIdx));

        if (dto.getPartnerNm() != null) partner.setPartnerNm(dto.getPartnerNm());
        if (dto.getPartnerStatus() != null) partner.setPartnerStatus(dto.getPartnerStatus());
        if (dto.getPartnerTel() != null) partner.setPartnerTel(dto.getPartnerTel());
        if (dto.getPartnerEmail() != null) partner.setPartnerEmail(dto.getPartnerEmail());
        if (dto.getGender() != null) partner.setGender(dto.getGender());
        if (dto.getPartnerBirth() != null) partner.setPartnerBirth(dto.getPartnerBirth());
        if (dto.getPZipCd() != null) partner.setPZipCd(dto.getPZipCd());
        if (dto.getPAddress() != null) partner.setPAddress(dto.getPAddress());
        if (dto.getPAddressDetail() != null) partner.setPAddressDetail(dto.getPAddressDetail());
        if (dto.getPRegion() != null) partner.setPRegion(dto.getPRegion());

        Partner saved = partnerRepository.save(partner);
        log.info("예비창업자 수정 완료: {}", saved.getPartnerIdx());
        return toDto(saved);
    }

    private PartnerResponseDto toDto(Partner partner) {
        return PartnerResponseDto.builder()
                .partnerIdx(partner.getPartnerIdx())
                .partnerNm(partner.getPartnerNm())
                .partnerStatus(partner.getPartnerStatus())
                .partnerTel(partner.getPartnerTel())
                .partnerEmail(partner.getPartnerEmail())
                .gender(partner.getGender())
                .createDt(partner.getCreateDt())
                .updateDt(partner.getUpdateDt())
                .partnerBirth(partner.getPartnerBirth())
                .pZipCd(partner.getPZipCd())
                .pAddress(partner.getPAddress())
                .pAddressDetail(partner.getPAddressDetail())
                .pRegion(partner.getPRegion())
                .build();
    }
}
