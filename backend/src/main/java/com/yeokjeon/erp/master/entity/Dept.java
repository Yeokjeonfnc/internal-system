package com.yeokjeon.erp.master.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@Entity
@Table(name = "dept_mst")
public class Dept {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "dept_idx")
    private Integer deptIdx;

    @Column(name = "upper_dept_idx")
    private Integer upperDeptIdx;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "upper_dept_idx", insertable = false, updatable = false)
    private Dept upperDept;

    @OneToMany(mappedBy = "upperDept")
    @OrderBy("sortOrder ASC, deptIdx ASC")
    private List<Dept> children = new ArrayList<>();

    @Column(name = "dept_nm", nullable = false)
    private String deptNm;

    @Column(name = "dept_level")
    private Integer deptLevel;

    @Column(name = "sort_order")
    private Integer sortOrder;
}
