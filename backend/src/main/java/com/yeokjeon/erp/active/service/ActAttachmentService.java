package com.yeokjeon.erp.active.service;

import com.yeokjeon.erp.active.dto.ActAttachmentDto;
import com.yeokjeon.erp.active.dto.ActAttachmentInsertParam;
import com.yeokjeon.erp.active.dto.ActAttachmentJdbcRow;
import com.yeokjeon.erp.active.entity.ActActive;
import com.yeokjeon.erp.active.mapper.ActAttachmentMapper;
import com.yeokjeon.erp.active.repository.ActRepository;
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
public class ActAttachmentService {

    /** 활동 첨부 전체 용량 상한 — UI 안내(200MB)와 동일. */
    private static final long MAX_TOTAL_BYTES = 209_715_200L;

    private final ActRepository actRepository;
    private final ActAttachmentMapper actAttachmentMapper;
    private final FileStorageProperties fileStorageProperties;

    private Path storageRoot;

    @PostConstruct
    void initStorageRoot() throws IOException {
        storageRoot = Path.of(fileStorageProperties.getStorageRoot()).toAbsolutePath().normalize();
        Files.createDirectories(storageRoot);
    }

    public List<ActAttachmentDto> list(Integer actIdx) {
        ensureActivityExists(actIdx);
        return actAttachmentMapper.selectByActIdx(actIdx).stream()
                .map(row -> ActAttachmentDto.fromRow(row, fileExists(row)))
                .collect(Collectors.toList());
    }

    @Transactional
    public ActAttachmentDto upload(Integer actIdx, MultipartFile file, String userId) {
        ActActive active = ensureActivityExists(actIdx);
        assertWritableStatus(active);

        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("업로드할 파일을 선택해주세요.");
        }
        if (file.getSize() > fileStorageProperties.getMaxSizeBytes()) {
            throw new IllegalArgumentException("파일 크기는 50MB까지 가능합니다.");
        }

        long currentTotal = actAttachmentMapper.sumFileSizeByActIdx(actIdx);
        if (currentTotal + file.getSize() > MAX_TOTAL_BYTES) {
            throw new IllegalArgumentException("첨부파일 전체 용량은 200MB까지 가능합니다.");
        }

        String originalName = sanitizeOriginalName(file.getOriginalFilename());
        if (originalName.isBlank()) {
            throw new IllegalArgumentException("파일명을 확인할 수 없습니다.");
        }

        String storedName = UUID.randomUUID() + "_" + originalName;
        Path targetDir = attachmentDir(actIdx);
        Path targetFile = targetDir.resolve(storedName).normalize();
        if (!targetFile.startsWith(targetDir)) {
            throw new IllegalArgumentException("잘못된 파일 경로입니다.");
        }

        try {
            Files.createDirectories(targetDir);
            Files.copy(file.getInputStream(), targetFile, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            log.error("활동 첨부 저장 실패 actIdx={} name={}", actIdx, originalName, e);
            throw new IllegalStateException("파일 저장에 실패했습니다.");
        }

        ActAttachmentInsertParam param = new ActAttachmentInsertParam();
        param.setActIdx(actIdx);
        param.setFileName(originalName);
        param.setStoredName(storedName);
        param.setFileSize(file.getSize());
        param.setContentType(StringUtils.hasText(file.getContentType()) ? file.getContentType() : null);
        param.setModifiedBy(trimToNull(userId));
        actAttachmentMapper.insert(param);

        ActAttachmentJdbcRow row = actAttachmentMapper.selectByAttIdxAndActIdx(
                param.getActAttIdx(), actIdx);
        if (row == null) {
            throw new IllegalStateException("업로드 후 첨부 정보를 조회할 수 없습니다.");
        }

        log.info("활동 첨부 업로드: actIdx={}, attIdx={}, file={}", actIdx, row.actAttIdx(), originalName);
        return ActAttachmentDto.fromRow(row, true);
    }

    public DownloadPayload download(Integer actIdx, Integer actAttIdx) {
        ActAttachmentJdbcRow row = requireAttachment(actIdx, actAttIdx);
        Path filePath = resolveStoredFile(row);
        if (!Files.isRegularFile(filePath)) {
            throw new ResourceNotFoundException("첨부 파일", "actAttIdx", actAttIdx);
        }
        Resource resource = new FileSystemResource(filePath);
        return new DownloadPayload(resource, row.fileName(), row.contentType());
    }

    @Transactional
    public void delete(Integer actIdx, Integer actAttIdx) {
        ActActive active = ensureActivityExists(actIdx);
        assertWritableStatus(active);

        ActAttachmentJdbcRow row = requireAttachment(actIdx, actAttIdx);
        int updated = actAttachmentMapper.markDeleted(actAttIdx, actIdx);
        if (updated == 0) {
            throw new ResourceNotFoundException("첨부", "actAttIdx", actAttIdx);
        }
        Path filePath = resolveStoredFile(row);
        try {
            Files.deleteIfExists(filePath);
        } catch (IOException e) {
            log.warn("첨부 디스크 파일 삭제 실패 actAttIdx={} path={}", actAttIdx, filePath, e);
        }
        log.info("활동 첨부 삭제: actIdx={}, attIdx={}", actIdx, actAttIdx);
    }

    private ActActive ensureActivityExists(Integer actIdx) {
        return actRepository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));
    }

    private static void assertWritableStatus(ActActive active) {
        String status = active.getApprStatus() == null ? "" : active.getApprStatus().trim().toUpperCase();
        if ("PENDING".equals(status) || "APPROVED".equals(status)) {
            throw new IllegalArgumentException("결재 진행·완료된 활동은 첨부를 변경할 수 없습니다.");
        }
    }

    private ActAttachmentJdbcRow requireAttachment(Integer actIdx, Integer actAttIdx) {
        ensureActivityExists(actIdx);
        ActAttachmentJdbcRow row = actAttachmentMapper.selectByAttIdxAndActIdx(actAttIdx, actIdx);
        if (row == null) {
            throw new ResourceNotFoundException("첨부", "actAttIdx", actAttIdx);
        }
        return row;
    }

    private Path attachmentDir(int actIdx) {
        return storageRoot.resolve("activities").resolve(String.valueOf(actIdx))
                .resolve("attachments").normalize();
    }

    private Path resolveStoredFile(ActAttachmentJdbcRow row) {
        Path dir = attachmentDir(row.actIdx());
        return dir.resolve(row.storedName()).normalize();
    }

    private boolean fileExists(ActAttachmentJdbcRow row) {
        return Files.isRegularFile(resolveStoredFile(row));
    }

    private static String sanitizeOriginalName(String raw) {
        if (!StringUtils.hasText(raw)) {
            return "";
        }
        String name = raw.replace("\\", "/");
        int slash = name.lastIndexOf('/');
        if (slash >= 0) {
            name = name.substring(slash + 1);
        }
        return name.trim();
    }

    private static String trimToNull(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        return value.trim();
    }

    public record DownloadPayload(Resource resource, String fileName, String contentType) {}
}
