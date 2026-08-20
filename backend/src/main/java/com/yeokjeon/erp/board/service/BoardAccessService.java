package com.yeokjeon.erp.board.service;

import com.yeokjeon.erp.board.dto.BbsFolderJdbcRow;
import com.yeokjeon.erp.board.dto.BbsPostDetailJdbcRow;
import com.yeokjeon.erp.board.mapper.BbsFolderMapper;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.master.dto.MenuPermissionDto;
import com.yeokjeon.erp.master.entity.MstUser;
import com.yeokjeon.erp.master.repository.MstUserRepository;
import com.yeokjeon.erp.master.service.MenuPermissionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.List;

/** 게시판(bbs001) 접근·권한 판단. */
@Service
@RequiredArgsConstructor
public class BoardAccessService {

    static final String MENU_CD = "bbs001";

    private final MstUserRepository mstUserRepository;
    private final MenuPermissionService menuPermissionService;
    private final BbsFolderMapper bbsFolderMapper;

    public MstUser requireUser(String userId) {
        if (!StringUtils.hasText(userId)) {
            throw new IllegalArgumentException("userId는(은) 필수입니다.");
        }
        return mstUserRepository
                .findByUserId(userId.trim())
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }

    public boolean isFranchiseOwner(MstUser user) {
        return user.getOwnerYn() != null && user.getOwnerYn() == 'Y';
    }

    public void ensureCanView(String userId) {
        MstUser user = requireUser(userId);
        if (isFranchiseOwner(user)) {
            return;
        }
        if (menuPermissionService.isSuperAdmin(userId)) {
            return;
        }
        MenuPermissionDto perm = findMenuPerm(user, MENU_CD);
        if (perm != null && perm.canView()) {
            return;
        }
        throw new IllegalArgumentException("게시판 조회 권한이 없습니다.");
    }

    public void ensureCanCreate(String userId) {
        MstUser user = requireUser(userId);
        if (isFranchiseOwner(user)) {
            return;
        }
        if (menuPermissionService.isSuperAdmin(userId)) {
            return;
        }
        MenuPermissionDto perm = findMenuPerm(user, MENU_CD);
        if (perm != null && perm.canCreate()) {
            return;
        }
        throw new IllegalArgumentException("게시글 등록 권한이 없습니다.");
    }

    public void ensureCanManageFolders(String userId) {
        if (!canManageFolders(userId)) {
            throw new IllegalArgumentException("폴더 관리 권한이 없습니다.");
        }
    }

    /**
     * 폴더의 '조회 권한' 설정을 바꿀 수 있는 사람인지.
     *
     * <p>가시성 판정에서 이 사람만 예외로 둔다 — 사원 열람을 꺼 둔 폴더가 관리자에게도 안 보이면
     * 설정을 되돌릴 방법이 없어져 폴더가 영영 잠긴다.
     */
    public boolean canManageFolders(String userId) {
        MstUser user = requireUser(userId);
        if (isFranchiseOwner(user)) {
            return false;
        }
        if (menuPermissionService.isSuperAdmin(userId)) {
            return true;
        }
        MenuPermissionDto perm = findMenuPerm(user, MENU_CD);
        return perm != null && perm.canUpdate();
    }

    public void ensureCanEditPost(String userId, BbsPostDetailJdbcRow post) {
        MstUser user = requireUser(userId);
        if (isFranchiseOwner(user)) {
            if (userId.trim().equals(post.createdBy())) {
                return;
            }
            throw new IllegalArgumentException("본인 게시글만 수정할 수 있습니다.");
        }
        if (menuPermissionService.isSuperAdmin(userId)) {
            return;
        }
        MenuPermissionDto perm = findMenuPerm(user, MENU_CD);
        if (perm != null && perm.canUpdate()) {
            return;
        }
        throw new IllegalArgumentException("게시글 수정 권한이 없습니다.");
    }

    /** 글 등록 직후·수정 시 첨부 업로드 — 작성자는 등록 권한만 있어도 가능. */
    public void ensureCanAttachDocument(String userId, BbsPostDetailJdbcRow post) {
        ensureCanView(userId);
        MstUser user = requireUser(userId);
        if (isFranchiseOwner(user)) {
            if (userId.trim().equals(post.createdBy())) {
                return;
            }
            throw new IllegalArgumentException("본인 게시글에만 첨부할 수 있습니다.");
        }
        if (menuPermissionService.isSuperAdmin(userId)) {
            return;
        }
        if (userId.trim().equals(post.createdBy())) {
            MenuPermissionDto perm = findMenuPerm(user, MENU_CD);
            if (perm != null && (perm.canCreate() || perm.canUpdate())) {
                return;
            }
        }
        MenuPermissionDto perm = findMenuPerm(user, MENU_CD);
        if (perm != null && perm.canUpdate()) {
            return;
        }
        throw new IllegalArgumentException("첨부 파일 등록 권한이 없습니다.");
    }

    public void ensureCanDeletePost(String userId, BbsPostDetailJdbcRow post) {
        MstUser user = requireUser(userId);
        if (isFranchiseOwner(user)) {
            if (userId.trim().equals(post.createdBy())) {
                return;
            }
            throw new IllegalArgumentException("본인 게시글만 삭제할 수 있습니다.");
        }
        if (menuPermissionService.isSuperAdmin(userId)) {
            return;
        }
        MenuPermissionDto perm = findMenuPerm(user, MENU_CD);
        if (perm != null && perm.canDelete()) {
            return;
        }
        throw new IllegalArgumentException("게시글 삭제 권한이 없습니다.");
    }

    public boolean canSetNotice(MstUser user) {
        return !isFranchiseOwner(user);
    }

    /**
     * 폴더 가시성 판정 — 폴더 등록 화면의 '조회 권한' 체크박스를 그대로 따른다.
     *
     * <p>예전에는 가맹점주에게만 owner_view_yn 을 적용하고 사원은 무조건 true 였다. 그래서
     * '사원 열람' 을 꺼서 가맹점주 전용으로 만든 폴더(예: 점주 안내·점주 민원)와 그 안의
     * 게시글·첨부가 전 사원에게 그대로 보였다 — 화면 표시(가맹점주)와 실제 노출이 어긋났다.
     */
    public boolean canViewFolder(BbsFolderJdbcRow folder, MstUser user, boolean folderManager) {
        if (folder == null) {
            return false;
        }
        if (!"Y".equalsIgnoreCase(String.valueOf(folder.useYn()))) {
            return false;
        }
        if (folderManager) {
            return true;
        }
        if (isFranchiseOwner(user)) {
            return allowsAudience(folder.ownerViewYn());
        }
        return allowsAudience(folder.staffViewYn());
    }

    public void ensureCanViewFolder(String userId, int folderIdx) {
        ensureCanView(userId);
        BbsFolderJdbcRow folder = bbsFolderMapper.selectFolderById(folderIdx);
        if (folder == null) {
            throw new ResourceNotFoundException("게시판 폴더", "folderIdx", folderIdx);
        }
        MstUser user = requireUser(userId);
        if (!canViewFolder(folder, user, canManageFolders(userId))) {
            throw new IllegalArgumentException("이 폴더에 대한 조회 권한이 없습니다.");
        }
    }

    /** 값이 비어 있으면 열람 허용 — 컬럼 추가 이전 행을 SQL 의 COALESCE(..., 'Y') 와 같게 다룬다. */
    private static boolean allowsAudience(String viewYn) {
        return viewYn == null || viewYn.isBlank() || "Y".equalsIgnoreCase(viewYn.trim());
    }

    private MenuPermissionDto findMenuPerm(MstUser user, String menuCd) {
        List<MenuPermissionDto> perms =
                menuPermissionService.getUserPermissions(user.getUserIdx());
        for (MenuPermissionDto p : perms) {
            if (menuCd.equals(p.menuCd())) {
                return p;
            }
        }
        return null;
    }
}
