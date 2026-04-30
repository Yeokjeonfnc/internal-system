package com.yeokjeon.erp.user.dto;

import com.yeokjeon.erp.user.entity.User;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserRequestDto {

    @NotBlank(message = "사용자 이름은 필수입니다.")
    @Size(max = 50)
    private String userName;

    @Size(max = 50)
    private String userId;

    @NotBlank(message = "비밀번호는 필수입니다.")
    @Size(max = 255)
    private String userPassword;

    private Integer deptIdx;

    @Size(max = 20)
    private String userPhone;

    @Email(message = "유효한 이메일 형식이어야 합니다.")
    @Size(max = 100)
    private String userEmail;

    private Character svYn;

    @Size(max = 10)
    private String positionCd;

    private Character tagYn;

    public User toEntity() {
        return User.builder()
                .userName(userName)
                .userId(userId)
                .userPassword(userPassword)
                .deptIdx(deptIdx)
                .userPhone(userPhone)
                .userEmail(userEmail)
                .svYn(svYn != null ? svYn : 'N')
                .positionCd(positionCd)
                .tagYn(tagYn != null ? tagYn : 'N')
                .build();
    }
}
