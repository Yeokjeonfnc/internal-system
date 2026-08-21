package com.yeokjeon.erp.eap.mapper;

import com.yeokjeon.erp.eap.dto.EapFormConfigJdbcRow;
import com.yeokjeon.erp.eap.dto.EapFormConfigSaveRequestDto;
import com.yeokjeon.erp.eap.dto.EapFormConfigUpdateRequestDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface EapFormConfigMapper {

    List<EapFormConfigJdbcRow> selectAll();

    List<EapFormConfigJdbcRow> selectEnabled();

    EapFormConfigJdbcRow selectByCode(@Param("formCode") String formCode);

    void lockFormCode();

    int selectNextSeq(@Param("year") String year);

    int insert(
            @Param("formCode") String formCode,
            @Param("body") EapFormConfigSaveRequestDto body);

    int update(
            @Param("formCode") String formCode,
            @Param("body") EapFormConfigUpdateRequestDto body);

    int delete(@Param("formCode") String formCode);
}
