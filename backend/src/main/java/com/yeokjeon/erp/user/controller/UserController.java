package com.yeokjeon.erp.user.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.user.dto.UserRequestDto;
import com.yeokjeon.erp.user.dto.UserResponseDto;
import com.yeokjeon.erp.user.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<UserResponseDto>>> getAllUsers(
            @RequestParam(required = false) Integer deptIdx) {
        List<UserResponseDto> users;
        if (deptIdx != null) {
            users = userService.getUsersByDept(deptIdx);
        } else {
            users = userService.getAllUsers();
        }
        return ResponseEntity.ok(ApiResponse.success(users));
    }

    @GetMapping("/{userIdx}")
    public ResponseEntity<ApiResponse<UserResponseDto>> getUser(@PathVariable Integer userIdx) {
        UserResponseDto user = userService.getUser(userIdx);
        return ResponseEntity.ok(ApiResponse.success(user));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<UserResponseDto>> createUser(@Valid @RequestBody UserRequestDto dto) {
        UserResponseDto created = userService.createUser(dto);
        return ResponseEntity.ok(ApiResponse.success("사용자가 생성되었습니다.", created));
    }

    @PutMapping("/{userIdx}")
    public ResponseEntity<ApiResponse<UserResponseDto>> updateUser(
            @PathVariable Integer userIdx,
            @Valid @RequestBody UserRequestDto dto) {
        UserResponseDto updated = userService.updateUser(userIdx, dto);
        return ResponseEntity.ok(ApiResponse.success("사용자가 수정되었습니다.", updated));
    }

    @DeleteMapping("/{userIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteUser(@PathVariable Integer userIdx) {
        userService.deleteUser(userIdx);
        return ResponseEntity.ok(ApiResponse.success("사용자가 삭제되었습니다.", null));
    }
}
