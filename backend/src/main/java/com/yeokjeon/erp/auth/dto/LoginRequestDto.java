package com.yeokjeon.erp.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginRequestDto {
    
    @NotBlank(message = "아이디를 입력해주세요")
    private String userId;
    
    @NotBlank(message = "비밀번호를 입력해주세요")
    private String userPassword;
}
