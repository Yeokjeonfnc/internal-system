package com.yeokjeon.erp.master.mapper;

import com.yeokjeon.erp.master.dto.MenuMstDto;
import com.yeokjeon.erp.master.dto.MenuPermissionDto;
import com.yeokjeon.erp.master.entity.UserMenuAuth;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface MenuPermissionMapper {

    List<MenuMstDto> selectActiveMenus();

    List<MenuPermissionDto> selectPermissionsByUserIdx(@Param("userIdx") int userIdx);

    List<MenuPermissionDto> selectAllMenusAsGranted();

    int deleteByUserIdx(@Param("userIdx") int userIdx);

    int insertUserMenuAuth(@Param("row") UserMenuAuth row);

    Integer selectUserIdxByUserId(@Param("userId") String userId);

    String selectAdminYnByUserId(@Param("userId") String userId);
}
