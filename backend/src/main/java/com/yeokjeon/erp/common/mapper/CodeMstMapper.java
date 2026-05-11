package com.yeokjeon.erp.common.mapper;

import com.yeokjeon.erp.common.dto.CodeMstDto;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface CodeMstMapper {

    List<CodeMstDto> selectByGrpCd(int grpCd);
}
