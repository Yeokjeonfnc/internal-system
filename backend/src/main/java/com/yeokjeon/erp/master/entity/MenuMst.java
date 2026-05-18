package com.yeokjeon.erp.master.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.ZonedDateTime;

/** 메뉴 마스터 — `menu_mst`. */
@Entity
@Table(name = "menu_mst")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MenuMst {

    @Id
    @Column(name = "menu_cd", length = 20)
    private String menuCd;

    @Column(name = "menu_nm", nullable = false, length = 100)
    private String menuNm;

    @Column(name = "parent_menu_cd", length = 20)
    private String parentMenuCd;

    @Column(name = "route_path", length = 200)
    private String routePath;

    /** G=그룹, L=리프(화면) */
    @Column(name = "menu_type", nullable = false, length = 1)
    private Character menuType;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder;

    @Column(name = "use_yn", nullable = false, length = 1)
    private Character useYn;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private ZonedDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private ZonedDateTime updatedAt;

    public boolean isGroup() {
        return menuType != null && menuType == 'G';
    }

    public boolean isLeaf() {
        return menuType != null && menuType == 'L';
    }

    public boolean isActive() {
        return useYn != null && useYn == 'Y';
    }
}
