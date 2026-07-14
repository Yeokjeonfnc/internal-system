package com.yeokjeon.erp.board.service;

import com.yeokjeon.erp.board.dto.*;
import com.yeokjeon.erp.board.mapper.BbsFolderMapper;
import com.yeokjeon.erp.board.mapper.BbsPostMapper;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.master.entity.MstUser;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class BoardService {

    private final BbsFolderMapper bbsFolderMapper;
    private final BbsPostMapper bbsPostMapper;
    private final BoardAccessService boardAccessService;

    public List<BbsFolderDto> listFolders(String userId) {
        boardAccessService.ensureCanView(userId);
        MstUser user = boardAccessService.requireUser(userId);
        boolean owner = boardAccessService.isFranchiseOwner(user);
        String uid = userId.trim();
        return bbsFolderMapper.selectFoldersForViewer(owner).stream()
                .map(row -> BbsFolderDto.fromRow(
                        row,
                        bbsFolderMapper.countPostsByFolderForViewer(
                                row.folderIdx(), uid, owner)))
                .collect(Collectors.toList());
    }

    @Transactional
    public BbsFolderDto createFolder(String userId, BbsFolderSaveRequestDto body) {
        boardAccessService.ensureCanManageFolders(userId);
        BbsFolderInsertParam param = new BbsFolderInsertParam();
        param.setFolderNm(body.folderNm());
        param.setSortOrder(body.sortOrder());
        param.setUseYn(body.useYn());
        param.setOwnerViewYn(normalizeYn(body.ownerViewYn(), "Y"));
        param.setStaffViewYn(normalizeYn(body.staffViewYn(), "Y"));
        param.setUserId(userId.trim());
        bbsFolderMapper.insertFolder(param);
        BbsFolderJdbcRow row = bbsFolderMapper.selectFolderById(param.getFolderIdx());
        return BbsFolderDto.fromRow(row, 0);
    }

    @Transactional
    public BbsFolderDto updateFolder(int folderIdx, String userId, BbsFolderSaveRequestDto body) {
        boardAccessService.ensureCanManageFolders(userId);
        ensureFolder(folderIdx);
        BbsFolderSaveRequestDto normalized = new BbsFolderSaveRequestDto(
                body.folderNm(),
                body.sortOrder(),
                body.useYn(),
                normalizeYn(body.ownerViewYn(), "Y"),
                normalizeYn(body.staffViewYn(), "Y"));
        bbsFolderMapper.updateFolder(folderIdx, normalized, userId.trim());
        BbsFolderJdbcRow row = bbsFolderMapper.selectFolderById(folderIdx);
        MstUser user = boardAccessService.requireUser(userId);
        boolean owner = boardAccessService.isFranchiseOwner(user);
        return BbsFolderDto.fromRow(
                row,
                bbsFolderMapper.countPostsByFolderForViewer(folderIdx, userId.trim(), owner));
    }

    @Transactional
    public void deleteFolder(int folderIdx, String userId) {
        boardAccessService.ensureCanManageFolders(userId);
        ensureFolder(folderIdx);
        long count = bbsPostMapper.countAllByFolder(folderIdx);
        if (count > 0) {
            throw new IllegalArgumentException("게시글이 있는 폴더는 삭제할 수 없습니다.");
        }
        bbsFolderMapper.deleteFolder(folderIdx);
    }

    public List<BbsPostDto> listPosts(String userId, Integer folderIdx, String keyword) {
        boardAccessService.ensureCanView(userId);
        MstUser user = boardAccessService.requireUser(userId);
        boolean owner = boardAccessService.isFranchiseOwner(user);
        if (folderIdx != null) {
            boardAccessService.ensureCanViewFolder(userId, folderIdx);
        }
        String kw = StringUtils.hasText(keyword) ? keyword.trim() : null;
        return bbsPostMapper.selectPosts(folderIdx, kw, userId.trim(), owner).stream()
                .map(BbsPostDto::fromRow)
                .collect(Collectors.toList());
    }

    @Transactional
    public BbsPostDto getPost(int postIdx, String userId, boolean incrementView) {
        boardAccessService.ensureCanView(userId);
        BbsPostDetailJdbcRow row = requirePost(postIdx);
        boardAccessService.ensureCanViewFolder(userId, row.folderIdx());
        ensureCanReadPost(userId, row);
        if (incrementView) {
            bbsPostMapper.incrementViewCnt(postIdx);
        }
        return BbsPostDto.fromDetailRow(row);
    }

    @Transactional
    public BbsPostDto createPost(String userId, BbsPostSaveRequestDto body) {
        boardAccessService.ensureCanCreate(userId);
        MstUser user = boardAccessService.requireUser(userId);
        boardAccessService.ensureCanViewFolder(userId, body.folderIdx());
        BbsPostInsertParam param = new BbsPostInsertParam();
        param.setFolderIdx(body.folderIdx());
        param.setTitle(body.title());
        param.setBodyTxt(body.bodyTxt());
        param.setPrivateYn(normalizeYn(body.privateYn(), "N"));
        if (boardAccessService.isFranchiseOwner(user)) {
            param.setNoticeYn("N");
            param.setStoreIdx(user.getStoreIdx());
        } else {
            param.setNoticeYn(
                    boardAccessService.canSetNotice(user)
                            ? normalizeYn(body.noticeYn(), "N")
                            : "N");
            param.setStoreIdx(body.storeIdx());
        }
        param.setUserId(userId.trim());
        bbsPostMapper.insertPost(param);
        return getPost(param.getPostIdx(), userId, false);
    }

    @Transactional
    public BbsPostDto updatePost(int postIdx, String userId, BbsPostSaveRequestDto body) {
        BbsPostDetailJdbcRow existing = requirePost(postIdx);
        boardAccessService.ensureCanEditPost(userId, existing);
        MstUser user = boardAccessService.requireUser(userId);
        boardAccessService.ensureCanViewFolder(userId, body.folderIdx());
        Integer storeIdx = boardAccessService.isFranchiseOwner(user)
                ? user.getStoreIdx()
                : body.storeIdx();
        BbsPostSaveRequestDto normalized = new BbsPostSaveRequestDto(
                body.folderIdx(),
                body.title(),
                body.bodyTxt(),
                normalizeYn(body.privateYn(), existing.privateYn()),
                boardAccessService.canSetNotice(user)
                        ? normalizeYn(body.noticeYn(), existing.noticeYn())
                        : existing.noticeYn(),
                storeIdx);
        bbsPostMapper.updatePost(postIdx, normalized, storeIdx);
        return getPost(postIdx, userId, false);
    }

    @Transactional
    public void deletePost(int postIdx, String userId) {
        BbsPostDetailJdbcRow existing = requirePost(postIdx);
        boardAccessService.ensureCanDeletePost(userId, existing);
        boardAccessService.ensureCanViewFolder(userId, existing.folderIdx());
        bbsPostMapper.softDeletePost(postIdx, userId.trim());
    }

    private void ensureCanReadPost(String userId, BbsPostDetailJdbcRow row) {
        if (!"Y".equalsIgnoreCase(String.valueOf(row.privateYn()))) {
            return;
        }
        MstUser user = boardAccessService.requireUser(userId);
        if (userId.trim().equals(row.createdBy())) {
            return;
        }
        if (!boardAccessService.isFranchiseOwner(user)) {
            return;
        }
        throw new IllegalArgumentException("비공개 게시글입니다.");
    }

    private BbsPostDetailJdbcRow requirePost(int postIdx) {
        BbsPostDetailJdbcRow row = bbsPostMapper.selectPostById(postIdx);
        if (row == null) {
            throw new ResourceNotFoundException("게시글", "postIdx", postIdx);
        }
        return row;
    }

    private void ensureFolder(int folderIdx) {
        if (bbsFolderMapper.selectFolderById(folderIdx) == null) {
            throw new ResourceNotFoundException("게시판 폴더", "folderIdx", folderIdx);
        }
    }

    private static String normalizeYn(String value, String fallback) {
        if (!StringUtils.hasText(value)) {
            return fallback != null ? fallback : "N";
        }
        return "Y".equalsIgnoreCase(value.trim()) ? "Y" : "N";
    }
}
