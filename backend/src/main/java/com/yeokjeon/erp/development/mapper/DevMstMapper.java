package com.yeokjeon.erp.development.mapper;

import com.yeokjeon.erp.development.dto.PartnerMstDto;
import com.yeokjeon.erp.development.dto.PropertyMstDto;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface DevMstMapper {

    List<PartnerMstDto> selectPartnersOrdered();

    List<PropertyMstDto> selectPropertiesOrdered();
}
