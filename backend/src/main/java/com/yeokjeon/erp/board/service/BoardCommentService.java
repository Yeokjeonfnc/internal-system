package com.yeokjeon.erp.board.service;

import com.yeokjeon.erp.board.dto.BbsCommentDto;
import com.yeokjeon.erp.board.dto.BbsCommentInsertParam;
import com.yeokjeon.erp.board.dto.BbsCommentJdbcRow;
import com.yeokjeon.erp.board.dto.BbsCommentSaveRequestDto;
import com.yeokjeon.erp.board.dto.BbsPostDetailJdbcRow;
import com.yeokjeon.erp.board.mapper.BbsCommentMapper;
import com.yeokjeon.erp.board.mapper.BbsPostMapper;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.master.dto.MenuPermissionDto;
import com.yeokjeon.erp.master.entity.MstUser;
import com.yeokjeon.erp.master.service.MenuPermissionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class BoardCommentService {

    private final BbsCommentMapper bbsCommentMapper;
    private final BbsPostMapper bbsPostMapper;
    private final BoardAccessService boardAccessService;
    private final MenuPermissionService menuPermissionService;

    public List<BbsCommentDto> list(int postIdx, String userId) {
        ensureCanReadPost(postIdx, userId);
        return bbsCommentMapper.selectByPostIdx(postIdx).stream()
                .map(BbsCommentDto::fromRow)
                .toList();
    }

    @Transactional
    public BbsCommentDto create(int postIdx, String userId, BbsCommentSaveRequestDto body) {
        ensureCanReadPost(postIdx, userId);
        BbsCommentInsertParam param = new BbsCommentInsertParam();
        param.setPostIdx(postIdx);
        param.setBodyTxt(body.bodyTxt());
        param.setUserId(userId.trim());
        bbsCommentMapper.insert(param);
        BbsCommentJdbcRow row = bbsCommentMapper.selectByIdx(param.getCommentIdx(), postIdx);
        if (row == null) {
            throw new ResourceNotFoundException("댓글", "commentIdx", param.getCommentIdx());
        }
        return BbsCommentDto.fromRow(row);
    }

    @Transactional
    public void delete(int postIdx, int commentIdx, String userId) {
        ensureCanReadPost(postIdx, userId);
        BbsCommentJdbcRow row = bbsCommentMapper.selectByIdx(commentIdx, postIdx);
        if (row == null) {
            throw new ResourceNotFoundException("댓글", "commentIdx", commentIdx);
        }
        ensureCanDeleteComment(userId, row);
        bbsCommentMapper.softDelete(commentIdx, postIdx, userId.trim());
    }

    private void ensureCanReadPost(int postIdx, String userId) {
        boardAccessService.ensureCanView(userId);
        BbsPostDetailJdbcRow post = bbsPostMapper.selectPostById(postIdx);
        if (post == null) {
            throw new ResourceNotFoundException("게시글", "postIdx", postIdx);
        }
        boardAccessService.ensureCanViewFolder(userId, post.folderIdx());
        if (!"Y".equalsIgnoreCase(String.valueOf(post.privateYn()))) {
            return;
        }
        if (userId.trim().equals(post.createdBy())) {
            return;
        }
        MstUser user = boardAccessService.requireUser(userId);
        if (!boardAccessService.isFranchiseOwner(user)) {
            return;
        }
        throw new IllegalArgumentException("비공개 게시글입니다.");
    }

    private void ensureCanDeleteComment(String userId, BbsCommentJdbcRow comment) {
        String uid = userId.trim();
        if (uid.equals(comment.createdBy())) {
            return;
        }
        MstUser user = boardAccessService.requireUser(uid);
        if (boardAccessService.isFranchiseOwner(user)) {
            throw new IllegalArgumentException("본인 댓글만 삭제할 수 있습니다.");
        }
        if (menuPermissionService.isSuperAdmin(uid)) {
            return;
        }
        List<MenuPermissionDto> perms =
                menuPermissionService.getUserPermissions(user.getUserIdx());
        for (MenuPermissionDto p : perms) {
            if (BoardAccessService.MENU_CD.equals(p.menuCd()) && p.canDelete()) {
                return;
            }
        }
        throw new IllegalArgumentException("댓글 삭제 권한이 없습니다.");
    }
}
