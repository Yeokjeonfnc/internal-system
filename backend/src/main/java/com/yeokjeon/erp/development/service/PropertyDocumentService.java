package com.yeokjeon.erp.development.service;

import com.yeokjeon.erp.config.FileStorageProperties;
import com.yeokjeon.erp.development.dto.PropertyDocumentDto;
import com.yeokjeon.erp.development.dto.PropertyDocumentInsertParam;
import com.yeokjeon.erp.development.dto.PropertyDocumentJdbcRow;
import com.yeokjeon.erp.development.mapper.PropertyDocumentMapper;
import com.yeokjeon.erp.development.repository.PropertyRepository;
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
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PropertyDocumentService {

    private final PropertyRepository propertyRepository;
    private final PropertyDocumentMapper propertyDocumentMapper;
    private final FileStorageProperties fileStorageProperties;

    private Path storageRoot;

    @PostConstruct
    void initStorageRoot() throws IOException {
        storageRoot = Path.of(fileStorageProperties.getStorageRoot()).toAbsolutePath().normalize();
        Files.createDirectories(storageRoot);
        log.info("물건 문서 저장 루트: {}", storageRoot);
    }

    public List<PropertyDocumentDto> list(Integer propIdx) {
        ensurePropertyExists(propIdx);
        return propertyDocumentMapper.selectByPropIdx(propIdx).stream()
                .map(row -> PropertyDocumentDto.fromRow(row, fileExists(row)))
                .collect(Collectors.toList());
    }

    @Transactional
    public PropertyDocumentDto upload(
            Integer propIdx,
            MultipartFile file,
            String userId,
            LocalDate attachmentBaseDate) {
        ensurePropertyExists(propIdx);
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
        Path targetDir = propertyDir(propIdx);
        Path targetFile = targetDir.resolve(storedName).normalize();
        if (!targetFile.startsWith(targetDir)) {
            throw new IllegalArgumentException("잘못된 파일 경로입니다.");
        }

        try {
            Files.createDirectories(targetDir);
            Files.copy(file.getInputStream(), targetFile, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            log.error("물건 파일 저장 실패 propIdx={} name={}", propIdx, originalName, e);
            throw new IllegalStateException("파일 저장에 실패했습니다.");
        }

        PropertyDocumentInsertParam param = new PropertyDocumentInsertParam();
        param.setPropIdx(propIdx);
        param.setFileName(originalName);
        param.setStoredName(storedName);
        param.setFileSize(file.getSize());
        param.setContentType(StringUtils.hasText(file.getContentType()) ? file.getContentType() : null);
        param.setAttachmentBaseDate(attachmentBaseDate != null ? attachmentBaseDate : LocalDate.now());
        param.setModifiedBy(trimToNull(userId));
        propertyDocumentMapper.insert(param);

        PropertyDocumentJdbcRow row = propertyDocumentMapper.selectByDocIdxAndPropIdx(
                param.getPropertyDocIdx(), propIdx);
        if (row == null) {
            throw new IllegalStateException("업로드 후 문서 정보를 조회할 수 없습니다.");
        }

        log.info("물건 문서 업로드: propIdx={}, docIdx={}, file={}", propIdx, row.propertyDocIdx(), originalName);
        return PropertyDocumentDto.fromRow(row, true);
    }

    public DownloadPayload download(Integer propIdx, Integer propertyDocIdx) {
        PropertyDocumentJdbcRow row = requireDocument(propIdx, propertyDocIdx);
        Path filePath = resolveStoredFile(row);
        if (!Files.isRegularFile(filePath)) {
            throw new ResourceNotFoundException("문서 파일", "propertyDocIdx", propertyDocIdx);
        }
        Resource resource = new FileSystemResource(filePath);
        return new DownloadPayload(resource, row.fileName(), row.contentType());
    }

    @Transactional
    public void delete(Integer propIdx, Integer propertyDocIdx) {
        PropertyDocumentJdbcRow row = requireDocument(propIdx, propertyDocIdx);
        int updated = propertyDocumentMapper.markDeleted(propertyDocIdx, propIdx);
        if (updated == 0) {
            throw new ResourceNotFoundException("문서", "propertyDocIdx", propertyDocIdx);
        }
        Path filePath = resolveStoredFile(row);
        try {
            Files.deleteIfExists(filePath);
        } catch (IOException e) {
            log.warn("디스크 파일 삭제 실패 propertyDocIdx={} path={}", propertyDocIdx, filePath, e);
        }
        log.info("물건 문서 삭제: propIdx={}, docIdx={}", propIdx, propertyDocIdx);
    }

    private PropertyDocumentJdbcRow requireDocument(Integer propIdx, Integer propertyDocIdx) {
        ensurePropertyExists(propIdx);
        PropertyDocumentJdbcRow row = propertyDocumentMapper.selectByDocIdxAndPropIdx(propertyDocIdx, propIdx);
        if (row == null) {
            throw new ResourceNotFoundException("문서", "propertyDocIdx", propertyDocIdx);
        }
        return row;
    }

    private void ensurePropertyExists(Integer propIdx) {
        propertyRepository.findById(propIdx)
                .orElseThrow(() -> new ResourceNotFoundException("물건", "propIdx", propIdx));
    }

    private Path propertyDir(int propIdx) {
        return storageRoot.resolve("properties").resolve(String.valueOf(propIdx)).normalize();
    }

    private Path resolveStoredFile(PropertyDocumentJdbcRow row) {
        Path dir = propertyDir(row.propIdx());
        return dir.resolve(row.storedName()).normalize();
    }

    private boolean fileExists(PropertyDocumentJdbcRow row) {
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
