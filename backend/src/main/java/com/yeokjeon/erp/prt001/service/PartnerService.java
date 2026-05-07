package com.yeokjeon.erp.prt001.service;

import com.yeokjeon.erp.common.RequestMapUtil;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.prt001.entity.Partner;
import com.yeokjeon.erp.prt001.repository.PartnerRepository;
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
public class PartnerService {

    private final PartnerRepository partnerRepository;

    public List<Map<String, Object>> getAllPartners() {
        return partnerRepository.findAllPartners()
                .stream()
                .map(this::toRow)
                .collect(Collectors.toList());
    }

    public Map<String, Object> getPartner(Integer partnerIdx) {
        Partner partner = partnerRepository.findById(partnerIdx)
                .orElseThrow(() -> new ResourceNotFoundException("예비창업자", "partnerIdx", partnerIdx));
        return toRow(partner);
    }

    @Transactional
    public Map<String, Object> createPartner(Map<String, Object> body) {
        Partner partner = Partner.builder()
                .partnerNm(RequestMapUtil.reqStr(body, "partnerNm"))
                .partnerStatus(RequestMapUtil.optStr(body, "partnerStatus"))
                .partnerTel(RequestMapUtil.reqStr(body, "partnerTel"))
                .partnerEmail(RequestMapUtil.optStr(body, "partnerEmail"))
                .gender(RequestMapUtil.optStr(body, "gender"))
                .partnerBirth(RequestMapUtil.optLocalDate(body, "partnerBirth"))
                .pZipCd(RequestMapUtil.optStr(body, "pZipCd"))
                .pAddress(RequestMapUtil.optStr(body, "pAddress"))
                .pAddressDetail(RequestMapUtil.optStr(body, "pAddressDetail"))
                .pRegion(RequestMapUtil.optStr(body, "pRegion"))
                .build();
        Partner saved = partnerRepository.save(partner);
        log.info("예비창업자 생성 완료: {}", saved.getPartnerIdx());
        return toRow(saved);
    }

    @Transactional
    public Map<String, Object> updatePartner(Integer partnerIdx, Map<String, Object> body) {
        Partner partner = partnerRepository.findById(partnerIdx)
                .orElseThrow(() -> new ResourceNotFoundException("예비창업자", "partnerIdx", partnerIdx));

        if (body.containsKey("partnerNm")) {
            partner.setPartnerNm(RequestMapUtil.optStr(body, "partnerNm"));
        }
        if (body.containsKey("partnerStatus")) {
            partner.setPartnerStatus(RequestMapUtil.optStr(body, "partnerStatus"));
        }
        if (body.containsKey("partnerTel")) {
            partner.setPartnerTel(RequestMapUtil.optStr(body, "partnerTel"));
        }
        if (body.containsKey("partnerEmail")) {
            partner.setPartnerEmail(RequestMapUtil.optStr(body, "partnerEmail"));
        }
        if (body.containsKey("gender")) {
            partner.setGender(RequestMapUtil.optStr(body, "gender"));
        }
        if (body.containsKey("partnerBirth")) {
            partner.setPartnerBirth(RequestMapUtil.optLocalDate(body, "partnerBirth"));
        }
        if (body.containsKey("pZipCd")) {
            partner.setPZipCd(RequestMapUtil.optStr(body, "pZipCd"));
        }
        if (body.containsKey("pAddress")) {
            partner.setPAddress(RequestMapUtil.optStr(body, "pAddress"));
        }
        if (body.containsKey("pAddressDetail")) {
            partner.setPAddressDetail(RequestMapUtil.optStr(body, "pAddressDetail"));
        }
        if (body.containsKey("pRegion")) {
            partner.setPRegion(RequestMapUtil.optStr(body, "pRegion"));
        }

        Partner saved = partnerRepository.save(partner);
        log.info("예비창업자 수정 완료: {}", saved.getPartnerIdx());
        return toRow(saved);
    }

    private Map<String, Object> toRow(Partner partner) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("partnerIdx", partner.getPartnerIdx());
        m.put("partnerNm", partner.getPartnerNm());
        m.put("partnerStatus", partner.getPartnerStatus());
        m.put("partnerTel", partner.getPartnerTel());
        m.put("partnerEmail", partner.getPartnerEmail());
        m.put("gender", partner.getGender());
        m.put("createDt", partner.getCreateDt());
        m.put("updateDt", partner.getUpdateDt());
        m.put("partnerBirth", partner.getPartnerBirth());
        m.put("pZipCd", partner.getPZipCd());
        m.put("pAddress", partner.getPAddress());
        m.put("pAddressDetail", partner.getPAddressDetail());
        m.put("pRegion", partner.getPRegion());
        return m;
    }
}
