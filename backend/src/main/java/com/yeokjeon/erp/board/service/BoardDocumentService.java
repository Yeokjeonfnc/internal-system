package com.yeokjeon.erp.board.service;

import com.yeokjeon.erp.board.dto.BbsDocumentDto;
import com.yeokjeon.erp.board.dto.BbsDocumentInsertParam;
import com.yeokjeon.erp.board.dto.BbsDocumentJdbcRow;
import com.yeokjeon.erp.board.dto.BbsPostDetailJdbcRow;
import com.yeokjeon.erp.board.mapper.BbsDocumentMapper;
import com.yeokjeon.erp.board.mapper.BbsPostMapper;
import com.yeokjeon.erp.config.FileStorageProperties;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class BoardDocumentService {

    private final BbsDocumentMapper bbsDocumentMapper;
    private final BbsPostMapper bbsPostMapper;
    private final BoardAccessService boardAccessService;
    private final FileStorageProperties fileStorageProperties;

    private Path storageRoot;

    @PostConstruct
    void initStorageRoot() throws IOException {
        storageRoot = Path.of(fileStorageProperties.getStorageRoot()).toAbsolutePath().normalize();
        Files.createDirectories(storageRoot);
    }

    public List<BbsDocumentDto> list(int postIdx, String userId) {
        boardAccessService.ensureCanView(userId);
        requireReadablePost(postIdx, userId);
        return bbsDocumentMapper.selectByPostIdx(postIdx).stream()
                .map(row -> BbsDocumentDto.fromRow(row, fileExists(row)))
                .collect(Collectors.toList());
    }

    @Transactional
    public BbsDocumentDto upload(int postIdx, MultipartFile file, String userId) {
        BbsPostDetailJdbcRow post = requirePost(postIdx);
        boardAccessService.ensureCanAttachDocument(userId, post);
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("업로드할 파일을 선택해주세요.");
        }
        if (file.getSize() > fileStorageProperties.getMaxSizeBytes()) {
            throw new IllegalArgumentException("파일 크기는 50MB까지 가능합니다.");
        }
        String originalName = sanitizeOriginalName(file.getOriginalFilename());
        if (originalName.isBlank()) {
            throw new IllegalArgumentException("파일명을 확인할 수 없습니다.");
        }
        String storedName = UUID.randomUUID() + "_" + originalName;
        Path targetDir = postDir(postIdx);
        Path targetFile = targetDir.resolve(storedName).normalize();
        if (!targetFile.startsWith(targetDir)) {
            throw new IllegalArgumentException("잘못된 파일 경로입니다.");
        }
        try {
            Files.createDirectories(targetDir);
            Files.copy(file.getInputStream(), targetFile, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            log.error("게시판 파일 저장 실패 postIdx={} name={}", postIdx, originalName, e);
            throw new IllegalStateException("파일 저장에 실패했습니다.");
        }
        BbsDocumentInsertParam param = new BbsDocumentInsertParam();
        param.setPostIdx(postIdx);
        param.setFileName(originalName);
        param.setStoredName(storedName);
        param.setFileSize(file.getSize());
        param.setContentType(resolveContentType(file, originalName));
        param.setModifiedBy(trimToNull(userId));
        bbsDocumentMapper.insert(param);
        BbsDocumentJdbcRow row =
                bbsDocumentMapper.selectByDocIdxAndPostIdx(param.getBbsDocIdx(), postIdx);
        if (row == null) {
            throw new IllegalStateException("업로드 후 문서 정보를 조회할 수 없습니다.");
        }
        return BbsDocumentDto.fromRow(row, true);
    }

    public DownloadPayload download(int postIdx, int bbsDocIdx, String userId) {
        requireReadablePost(postIdx, userId);
        BbsDocumentJdbcRow row = requireDocument(postIdx, bbsDocIdx);
        Path filePath = resolveStoredFile(postIdx, row);
        if (!Files.isRegularFile(filePath)) {
            throw new ResourceNotFoundException("첨부 파일", "bbsDocIdx", bbsDocIdx);
        }
        Resource resource = new FileSystemResource(filePath);
        return new DownloadPayload(
                resource,
                row.fileName(),
                resolveContentTypeForDownload(row.contentType(), row.fileName()));
    }

    @Transactional
    public void delete(int postIdx, int bbsDocIdx, String userId) {
        BbsPostDetailJdbcRow post = requirePost(postIdx);
        boardAccessService.ensureCanEditPost(userId, post);
        BbsDocumentJdbcRow row = requireDocument(postIdx, bbsDocIdx);
        int updated = bbsDocumentMapper.markDeleted(bbsDocIdx, postIdx);
        if (updated == 0) {
            throw new ResourceNotFoundException("첨부 파일", "bbsDocIdx", bbsDocIdx);
        }
        try {
            Files.deleteIfExists(resolveStoredFile(postIdx, row));
        } catch (IOException e) {
            log.warn("디스크 파일 삭제 실패 bbsDocIdx={}", bbsDocIdx, e);
        }
    }

    private void requireReadablePost(int postIdx, String userId) {
        boardAccessService.ensureCanView(userId);
        BbsPostDetailJdbcRow row = requirePost(postIdx);
        boardAccessService.ensureCanViewFolder(userId, row.folderIdx());
        if ("Y".equalsIgnoreCase(String.valueOf(row.privateYn()))
                && boardAccessService.isFranchiseOwner(boardAccessService.requireUser(userId))
                && !userId.trim().equals(row.createdBy())) {
            throw new IllegalArgumentException("비공개 게시글입니다.");
        }
    }

    private BbsPostDetailJdbcRow requirePost(int postIdx) {
        BbsPostDetailJdbcRow row = bbsPostMapper.selectPostById(postIdx);
        if (row == null) {
            throw new ResourceNotFoundException("게시글", "postIdx", postIdx);
        }
        return row;
    }

    private BbsDocumentJdbcRow requireDocument(int postIdx, int bbsDocIdx) {
        BbsDocumentJdbcRow row = bbsDocumentMapper.selectByDocIdxAndPostIdx(bbsDocIdx, postIdx);
        if (row == null) {
            throw new ResourceNotFoundException("첨부 파일", "bbsDocIdx", bbsDocIdx);
        }
        return row;
    }

    private Path postDir(int postIdx) {
        return storageRoot.resolve("board").resolve(String.valueOf(postIdx)).normalize();
    }

    private Path resolveStoredFile(int postIdx, BbsDocumentJdbcRow row) {
        return postDir(postIdx).resolve(row.storedName()).normalize();
    }

    private boolean fileExists(BbsDocumentJdbcRow row) {
        return Files.isRegularFile(resolveStoredFile(row.postIdx(), row));
    }

    private static String sanitizeOriginalName(String name) {
        if (!StringUtils.hasText(name)) {
            return "";
        }
        String base = Path.of(name).getFileName().toString();
        return base.replaceAll("[\\\\/:*?\"<>|]", "_").trim();
    }

    private static String trimToNull(String s) {
        if (s == null) {
            return null;
        }
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }

    private static String resolveContentType(MultipartFile file, String originalName) {
        if (file != null && StringUtils.hasText(file.getContentType())) {
            String ct = file.getContentType().trim();
            if (!"application/octet-stream".equalsIgnoreCase(ct)) {
                return ct;
            }
        }
        return inferContentTypeFromFileName(originalName);
    }

    private static String resolveContentTypeForDownload(String contentType, String fileName) {
        if (StringUtils.hasText(contentType)) {
            return contentType.trim();
        }
        return inferContentTypeFromFileName(fileName);
    }

    private static String inferContentTypeFromFileName(String fileName) {
        if (!StringUtils.hasText(fileName)) {
            return "application/octet-stream";
        }
        String lower = fileName.trim().toLowerCase();
        if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
            return "image/jpeg";
        }
        if (lower.endsWith(".png")) {
            return "image/png";
        }
        if (lower.endsWith(".gif")) {
            return "image/gif";
        }
        if (lower.endsWith(".bmp")) {
            return "image/bmp";
        }
        if (lower.endsWith(".webp")) {
            return "image/webp";
        }
        if (lower.endsWith(".pdf")) {
            return "application/pdf";
        }
        return "application/octet-stream";
    }

    public record DownloadPayload(Resource resource, String fileName, String contentType) {}
}
