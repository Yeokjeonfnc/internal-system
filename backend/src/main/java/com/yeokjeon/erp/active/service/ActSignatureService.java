package com.yeokjeon.erp.active.service;

import com.yeokjeon.erp.active.entity.ActActive;
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
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ActSignatureService {

    private static final String SIGNATURE_CONTENT_TYPE = "image/png";

    private final ActRepository actRepository;
    private final FileStorageProperties fileStorageProperties;

    private Path storageRoot;

    @PostConstruct
    void initStorageRoot() throws IOException {
        storageRoot = Path.of(fileStorageProperties.getStorageRoot()).toAbsolutePath().normalize();
        Files.createDirectories(storageRoot);
    }

    public boolean hasSignature(ActActive active) {
        if (active == null || !StringUtils.hasText(active.getSignatureStoredName())) {
            return false;
        }
        return Files.isRegularFile(resolveSignaturePath(active.getActIdx(), active.getSignatureStoredName()));
    }

    @Transactional
    public void upload(Integer actIdx, MultipartFile file) {
        ActActive active = actRepository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));

        String status = active.getApprStatus() == null ? "" : active.getApprStatus().trim().toUpperCase();
        // 상신(PENDING) 직후 최초 서명 업로드는 허용한다. (등록 화면: DRAFT→PENDING 후 서명 또는 DRAFT 서명 후 PENDING)
        // 이미 서명이 있거나 결재완료(APPROVED)인 경우만 변경을 막는다.
        boolean hasExisting = StringUtils.hasText(active.getSignatureStoredName());
        if ("APPROVED".equals(status) || ("PENDING".equals(status) && hasExisting)) {
            throw new IllegalArgumentException("결재 진행·완료된 활동은 전자서명을 변경할 수 없습니다.");
        }

        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("전자서명 파일이 비어 있습니다.");
        }
        if (file.getSize() > fileStorageProperties.getMaxSizeBytes()) {
            throw new IllegalArgumentException("전자서명 파일 크기가 허용 범위를 초과했습니다.");
        }

        String contentType = file.getContentType();
        if (contentType != null && !contentType.isBlank()
                && !contentType.toLowerCase().contains("png")
                && !contentType.toLowerCase().contains("image")) {
            throw new IllegalArgumentException("전자서명은 PNG 이미지여야 합니다.");
        }

        deleteStoredFileIfExists(active.getActIdx(), active.getSignatureStoredName());

        String storedName = UUID.randomUUID() + "_signature.png";
        Path targetDir = actDir(actIdx);
        Path targetFile = targetDir.resolve(storedName).normalize();
        if (!targetFile.startsWith(targetDir)) {
            throw new IllegalArgumentException("잘못된 파일 경로입니다.");
        }

        try {
            Files.createDirectories(targetDir);
            Files.copy(file.getInputStream(), targetFile, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            log.error("전자서명 저장 실패 actIdx={}", actIdx, e);
            throw new IllegalStateException("전자서명 저장에 실패했습니다.");
        }

        active.setSignatureStoredName(storedName);
        actRepository.save(active);
        log.info("활동 전자서명 저장: actIdx={}", actIdx);
    }

    public DownloadPayload download(Integer actIdx) {
        ActActive active = actRepository.findById(actIdx)
                .orElseThrow(() -> new ResourceNotFoundException("활동관리", "actIdx", actIdx));
        if (!StringUtils.hasText(active.getSignatureStoredName())) {
            throw new ResourceNotFoundException("전자서명", "actIdx", actIdx);
        }
        Path filePath = resolveSignaturePath(actIdx, active.getSignatureStoredName());
        if (!Files.isRegularFile(filePath)) {
            throw new ResourceNotFoundException("전자서명 파일", "actIdx", actIdx);
        }
        return new DownloadPayload(
                new FileSystemResource(filePath),
                "signature.png",
                SIGNATURE_CONTENT_TYPE);
    }

    private void deleteStoredFileIfExists(Integer actIdx, String storedName) {
        if (!StringUtils.hasText(storedName)) {
            return;
        }
        try {
            Files.deleteIfExists(resolveSignaturePath(actIdx, storedName));
        } catch (IOException e) {
            log.warn("기존 전자서명 삭제 실패 actIdx={} name={}", actIdx, storedName, e);
        }
    }

    private Path actDir(int actIdx) {
        return storageRoot.resolve("activities").resolve(String.valueOf(actIdx)).normalize();
    }

    private Path resolveSignaturePath(int actIdx, String storedName) {
        Path dir = actDir(actIdx);
        return dir.resolve(storedName).normalize();
    }

    public record DownloadPayload(Resource resource, String fileName, String contentType) {}
}
