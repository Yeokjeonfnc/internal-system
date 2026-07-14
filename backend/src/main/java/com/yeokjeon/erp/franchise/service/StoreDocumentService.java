package com.yeokjeon.erp.franchise.service;

import com.yeokjeon.erp.config.FileStorageProperties;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.franchise.dto.StoreDocumentDto;
import com.yeokjeon.erp.franchise.dto.StoreDocumentInsertParam;
import com.yeokjeon.erp.franchise.dto.StoreDocumentJdbcRow;
import com.yeokjeon.erp.franchise.entity.Store;
import com.yeokjeon.erp.franchise.mapper.StoreDocumentMapper;
import com.yeokjeon.erp.franchise.mapper.StoreHistoryMapper;
import com.yeokjeon.erp.franchise.repository.StoreRepository;
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
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StoreDocumentService {

    private final StoreRepository storeRepository;
    private final StoreDocumentMapper storeDocumentMapper;
    private final StoreHistoryMapper storeHistoryMapper;
    private final FileStorageProperties fileStorageProperties;

    private Path storageRoot;

    @PostConstruct
    void initStorageRoot() throws IOException {
        storageRoot = Path.of(fileStorageProperties.getStorageRoot()).toAbsolutePath().normalize();
        Files.createDirectories(storageRoot);
        log.info("파일 저장 루트: {}", storageRoot);
    }

    public List<StoreDocumentDto> list(Integer storeIdx) {
        ensureStoreExists(storeIdx);
        return storeDocumentMapper.selectByStoreIdx(storeIdx).stream()
                .map(row -> StoreDocumentDto.fromRow(row, fileExists(row)))
                .collect(Collectors.toList());
    }

    @Transactional
    public StoreDocumentDto upload(
            Integer storeIdx,
            MultipartFile file,
            String userId,
            LocalDate attachmentBaseDate) {
        ensureStoreExists(storeIdx);
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
        Path targetDir = storeDir(storeIdx);
        Path targetFile = targetDir.resolve(storedName).normalize();
        if (!targetFile.startsWith(targetDir)) {
            throw new IllegalArgumentException("잘못된 파일 경로입니다.");
        }

        try {
            Files.createDirectories(targetDir);
            Files.copy(file.getInputStream(), targetFile, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            log.error("파일 저장 실패 storeIdx={} name={}", storeIdx, originalName, e);
            throw new IllegalStateException("파일 저장에 실패했습니다.");
        }

        StoreDocumentInsertParam param = new StoreDocumentInsertParam();
        param.setStoreIdx(storeIdx);
        param.setFileName(originalName);
        param.setStoredName(storedName);
        param.setFileSize(file.getSize());
        param.setContentType(StringUtils.hasText(file.getContentType()) ? file.getContentType() : null);
        param.setAttachmentBaseDate(attachmentBaseDate != null ? attachmentBaseDate : LocalDate.now());
        param.setModifiedBy(trimToNull(userId));
        storeDocumentMapper.insert(param);

        StoreDocumentJdbcRow row = storeDocumentMapper.selectByDocIdxAndStoreIdx(
                param.getStoreDocIdx(), storeIdx);
        if (row == null) {
            throw new IllegalStateException("업로드 후 문서 정보를 조회할 수 없습니다.");
        }
        saveDocumentUploadHistory(storeIdx, userId);

        log.info("가맹점 문서 업로드: storeIdx={}, docIdx={}, file={}", storeIdx, row.storeDocIdx(), originalName);
        return StoreDocumentDto.fromRow(row, true);
    }

    private void saveDocumentUploadHistory(Integer storeIdx, String userId) {
        Store store = storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
        String chgUserId = trimToNull(userId);
        if (chgUserId == null) {
            chgUserId = "system";
        }
        storeHistoryMapper.insertHistorySimple(
                storeIdx,
                "UPDATE",
                chgUserId,
                store.getStoreNm(),
                "문서업로드");
    }

    public DownloadPayload download(Integer storeIdx, Integer storeDocIdx) {
        StoreDocumentJdbcRow row = requireDocument(storeIdx, storeDocIdx);
        Path filePath = resolveStoredFile(row);
        if (!Files.isRegularFile(filePath)) {
            throw new ResourceNotFoundException("문서 파일", "storeDocIdx", storeDocIdx);
        }
        Resource resource = new FileSystemResource(filePath);
        return new DownloadPayload(resource, row.fileName(), row.contentType());
    }

    @Transactional
    public void delete(Integer storeIdx, Integer storeDocIdx) {
        StoreDocumentJdbcRow row = requireDocument(storeIdx, storeDocIdx);
        int updated = storeDocumentMapper.markDeleted(storeDocIdx, storeIdx);
        if (updated == 0) {
            throw new ResourceNotFoundException("문서", "storeDocIdx", storeDocIdx);
        }
        Path filePath = resolveStoredFile(row);
        try {
            Files.deleteIfExists(filePath);
        } catch (IOException e) {
            log.warn("디스크 파일 삭제 실패 storeDocIdx={} path={}", storeDocIdx, filePath, e);
        }
        log.info("가맹점 문서 삭제: storeIdx={}, docIdx={}", storeIdx, storeDocIdx);
    }

    private StoreDocumentJdbcRow requireDocument(Integer storeIdx, Integer storeDocIdx) {
        ensureStoreExists(storeIdx);
        StoreDocumentJdbcRow row = storeDocumentMapper.selectByDocIdxAndStoreIdx(storeDocIdx, storeIdx);
        if (row == null) {
            throw new ResourceNotFoundException("문서", "storeDocIdx", storeDocIdx);
        }
        return row;
    }

    private void ensureStoreExists(Integer storeIdx) {
        storeRepository.findByStoreIdx(storeIdx)
                .orElseThrow(() -> new ResourceNotFoundException("가맹점", "storeIdx", storeIdx));
    }

    private Path storeDir(int storeIdx) {
        return storageRoot.resolve("stores").resolve(String.valueOf(storeIdx)).normalize();
    }

    private Path resolveStoredFile(StoreDocumentJdbcRow row) {
        Path dir = storeDir(row.storeIdx());
        return dir.resolve(row.storedName()).normalize();
    }

    private boolean fileExists(StoreDocumentJdbcRow row) {
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
