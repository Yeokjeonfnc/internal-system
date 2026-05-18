package com.yeokjeon.erp.master.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.io.Serializable;
import java.time.ZonedDateTime;
import java.util.Objects;

/** 사용자별 메뉴 권한 — `user_menu_auth`. */
@Entity
@Table(name = "user_menu_auth")
@IdClass(UserMenuAuth.UserMenuAuthId.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserMenuAuth {

    @Id
    @Column(name = "user_idx")
    private Integer userIdx;

    @Id
    @Column(name = "menu_cd", length = 20)
    private String menuCd;

    @Column(name = "can_view", nullable = false, length = 1)
    private Character canView;

    @Column(name = "can_create", nullable = false, length = 1)
    private Character canCreate;

    @Column(name = "can_update", nullable = false, length = 1)
    private Character canUpdate;

    @Column(name = "can_delete", nullable = false, length = 1)
    private Character canDelete;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private ZonedDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private ZonedDateTime updatedAt;

    public boolean canView() {
        return canView != null && canView == 'Y';
    }

    public static UserMenuAuth viewOnly(Integer userIdx, String menuCd) {
        return UserMenuAuth.builder()
                .userIdx(userIdx)
                .menuCd(menuCd)
                .canView('Y')
                .canCreate('N')
                .canUpdate('N')
                .canDelete('N')
                .build();
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserMenuAuthId implements Serializable {
        private Integer userIdx;
        private String menuCd;

        @Override
        public boolean equals(Object o) {
            if (this == o) {
                return true;
            }
            if (!(o instanceof UserMenuAuthId that)) {
                return false;
            }
            return Objects.equals(userIdx, that.userIdx) && Objects.equals(menuCd, that.menuCd);
        }

        @Override
        public int hashCode() {
            return Objects.hash(userIdx, menuCd);
        }
    }
}
