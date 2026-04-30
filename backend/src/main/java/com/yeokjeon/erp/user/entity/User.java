package com.yeokjeon.erp.user.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.ZonedDateTime;

@Entity
@Table(name = "user_mst")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_idx")
    private Integer userIdx;

    @Column(name = "user_name", nullable = false, length = 50)
    private String userName;

    @Column(name = "user_id", unique = true, length = 50)
    private String userId;

    @Column(name = "user_password", nullable = false, length = 255)
    private String userPassword;

    @Column(name = "dept_idx")
    private Integer deptIdx;

    @Column(name = "user_phone", length = 20)
    private String userPhone;

    @Column(name = "user_email", length = 100)
    private String userEmail;

    @Column(name = "sv_yn", length = 1)
    private Character svYn;

    @Column(name = "position_cd", length = 10)
    private String positionCd;

    @Column(name = "tag_yn", length = 1)
    private Character tagYn;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private ZonedDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private ZonedDateTime updatedAt;
}
