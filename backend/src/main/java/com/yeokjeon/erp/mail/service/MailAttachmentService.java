package com.yeokjeon.erp.mail.service;

import com.yeokjeon.erp.config.FileStorageProperties;
import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.mail.client.ResendApiException;
import com.yeokjeon.erp.mail.client.ResendClient;
import com.yeokjeon.erp.mail.config.ResendProperties;
import com.yeokjeon.erp.mail.dto.MailAttInsertParam;
import com.yeokjeon.erp.mail.dto.MailAttJdbcRow;
import com.yeokjeon.erp.mail.dto.MailAttachmentDto;
import com.yeokjeon.erp.mail.dto.MailMstJdbcRow;
import com.yeokjeon.erp.mail.dto.resend.ResendAttachmentMetaDto;
import com.yeokjeon.erp.mail.dto.resend.ResendSendAttachmentDto;
import com.yeokjeon.erp.mail.mapper.MailAttMapper;
import com.yeokjeon.erp.mail.mapper.MailMstMapper;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

/**
 * 메일 첨부 — 발신 업로드 / 수신 실물 수집 / 다운로드.
 *
 * <p>바이너리는 DB 에 넣지 않는다. 기존 {@code bbs_doc} / {@code active_att} 와 똑같이
 * 디스크({@code FILE_STORAGE_ROOT})에 두고 {@code mail_att} 에는 메타만 남긴다.
 * 경로 규칙은 마이그레이션 주석과 동일하게 {@code <storageRoot>/mails/<mail_idx>/<stored_name>}.
 *
 * <p>수신 첨부는 웹훅 시점에 메타만 들어오고 실물은 없다({@code fetched_at IS NULL}).
 * 다운로드 URL 이 1시간 만료 서명 URL 이라 DB 에 저장할 수 없어, 워커가 그때그때
 * 메타를 다시 조회해 URL 을 받고 곧바로 내려받는 2단계로 돈다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailAttachmentService {

    private static final int MAX_BATCH = 100;
    private static final int FILE_NAME_MAX = 255;
    private static final int STORED_NAME_MAX = 255;
    private static final int CONTENT_TYPE_MAX = 127;
    private static final int ERR_MAX = 500;

    private final MailAttMapper mailAttMapper;
    private final MailMstMapper mailMstMapper;
    private final ResendClient resendClient;
    private final ResendProperties properties;
    private final FileStorageProperties fileStorageProperties;
    private final PlatformTransactionManager transactionManager;

    private Path storageRoot;
    private TransactionTemplate txTemplate;

    @PostConstruct
    void init() throws IOException {
        this.storageRoot = Path.of(fileStorageProperties.getStorageRoot()).toAbsolutePath().normalize();
        Files.createDirectories(storageRoot);
        this.txTemplate = new TransactionTemplate(transactionManager);
    }

    /**
     * 발신 임시보관(DRAFT) 메일에 첨부를 올린다.
     *
     * <p>DRAFT 로 제한하는 이유: 이미 대기열에 들어갔거나 나간 메일에 첨부를 붙이면
     * ERP 화면에는 첨부가 보이는데 실제로 나간 메일에는 없는 상태가 된다.
     */
    @Transactional
    public MailAttachmentDto upload(long mailIdx, MultipartFile file, String callerUserId) {
        MailMstJdbcRow mail = requireMail(mailIdx);
        if (!"OUT".equals(mail.direction()) || !"DRAFT".equals(mail.sendStatus())) {
            throw new IllegalStateException("임시보관 중인 발신 메일에만 첨부할 수 있습니다.");
        }
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("업로드할 파일을 선택해주세요.");
        }
        long maxBytes = Math.min(properties.getAttachmentMaxBytes(), fileStorageProperties.getMaxSizeBytes());
        if (file.getSize() > maxBytes) {
            throw new IllegalArgumentException("첨부 파일 크기는 " + (maxBytes / 1024 / 1024) + "MB까지 가능합니다.");
        }
        String originalName = sanitizeFileName(file.getOriginalFilename());
        if (originalName.isBlank()) {
            throw new IllegalArgumentException("파일명을 확인할 수 없습니다.");
        }
        String storedName = clip(UUID.randomUUID() + "_" + originalName, STORED_NAME_MAX);
        Path targetDir = mailDir(mailIdx);
        Path targetFile = resolveInside(targetDir, storedName);
        try {
            Files.createDirectories(targetDir);
            Files.copy(file.getInputStream(), targetFile, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            log.error("메일 첨부 저장 실패 mailIdx={} name={}", mailIdx, originalName, e);
            throw new IllegalStateException("파일 저장에 실패했습니다.");
        }

        MailAttInsertParam param = new MailAttInsertParam();
        param.setMailIdx(mailIdx);
        // 발신 첨부는 Resend 첨부 id 가 없다. NULL 끼리는 UNIQUE 충돌이 나지 않으므로
        // 같은 파일을 두 번 올리면 두 행이 생기는 것이 의도된 동작이다.
        param.setResendAttId(null);
        param.setFileName(clip(originalName, FILE_NAME_MAX));
        param.setStoredName(storedName);
        param.setFileSize(file.getSize());
        param.setContentType(clip(resolveContentType(file.getContentType(), originalName), CONTENT_TYPE_MAX));
        param.setContentId(null);
        param.setInlineYn("N");
        // 우리가 방금 디스크에 넣었으므로 실물은 이미 있다 → 수집 워커가 집어 가면 안 된다.
        param.setFetchedAt(OffsetDateTime.now());
        param.setModifiedBy(trimToNull(callerUserId));
        mailAttMapper.insert(param);

        Long mailAttIdx = param.getMailAttIdx();
        if (mailAttIdx == null) {
            throw new IllegalStateException("첨부 정보 저장에 실패했습니다.");
        }
        mailMstMapper.updateAttCnt(mailIdx);

        MailAttJdbcRow row = mailAttMapper.selectByIdx(mailAttIdx);
        if (row == null) {
            throw new IllegalStateException("업로드 후 첨부 정보를 조회할 수 없습니다.");
        }
        log.info("메일 첨부 업로드 mailIdx={} mailAttIdx={} by={}", mailIdx, mailAttIdx, callerUserId);
        return MailAttachmentDto.fromRow(row);
    }

    /**
     * 아직 실물을 못 받은 수신 첨부를 내려받는다(워커 전용, 트랜잭션 없음).
     *
     * @return 성공 건수
     */
    public int fetchPendingAttachments(int limit) {
        if (!resendClient.isEnabled()) {
            log.warn("Resend API 키가 없어 첨부 수집을 건너뜁니다(RESEND_API_KEY 미설정).");
            return 0;
        }
        ResendProperties.Sync sync = properties.getSync();
        List<MailAttJdbcRow> rows = mailAttMapper.selectFetchPending(
                clampBatch(limit), sync.getMaxTryCnt(), sync.getBackoffMinutes());
        int success = 0;
        for (MailAttJdbcRow row : rows) {
            try {
                if (fetchOne(row)) {
                    success++;
                }
            } catch (RuntimeException e) {
                log.warn("메일 첨부 수집 실패 mailAttIdx={}", row.mailAttIdx(), e);
            }
        }
        if (!rows.isEmpty()) {
            log.info("메일 첨부 수집 {}/{}건 완료", success, rows.size());
        }
        return success;
    }

    @Transactional(readOnly = true)
    public DownloadPayload download(long mailAttIdx) {
        MailAttJdbcRow row = requireAttachment(mailAttIdx);
        if (!StringUtils.hasText(row.storedName())) {
            throw new ResourceNotFoundException("첨부 파일이 아직 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.");
        }
        Path file = resolveInside(mailDir(row.mailIdx()), row.storedName());
        if (!Files.isRegularFile(file)) {
            throw new ResourceNotFoundException("첨부 파일", "mailAttIdx", mailAttIdx);
        }
        return new DownloadPayload(
                new FileSystemResource(file),
                row.fileName(),
                resolveContentType(row.contentType(), row.fileName()));
    }

    @Transactional
    public void delete(long mailAttIdx, String callerUserId) {
        MailAttJdbcRow row = requireAttachment(mailAttIdx);
        int deleted = mailAttMapper.softDelete(mailAttIdx, trimToNull(callerUserId));
        if (deleted == 0) {
            throw new IllegalStateException("첨부 삭제에 실패했습니다.");
        }
        mailMstMapper.updateAttCnt(row.mailIdx());
        if (StringUtils.hasText(row.storedName())) {
            try {
                Files.deleteIfExists(resolveInside(mailDir(row.mailIdx()), row.storedName()));
            } catch (IOException | IllegalArgumentException e) {
                // 메타는 이미 지워졌다. 디스크 정리 실패로 요청을 되돌리면 오히려 상태가 꼬인다.
                log.warn("메일 첨부 실물 삭제 실패 mailAttIdx={}", mailAttIdx, e);
            }
        }
        log.info("메일 첨부 삭제 mailAttIdx={} by={}", mailAttIdx, callerUserId);
    }

    /**
     * 발송 요청에 실을 첨부를 Base64 로 만든다.
     *
     * <p>{@code @Transactional} 을 붙이지 않는 이유: 파일을 통째로 읽어 Base64 로 바꾸는
     * 시간 동안 DB 커넥션을 쥐고 있을 이유가 없다. 메타 조회는 단발성 SELECT 하나뿐이다.
     * 읽지 못한 파일은 건너뛴다 — 첨부 하나 때문에 메일 전체를 못 보내는 것보다 낫다.
     */
    public List<ResendSendAttachmentDto> buildSendAttachments(long mailIdx) {
        List<MailAttJdbcRow> rows = mailAttMapper.selectByMailIdx(mailIdx);
        if (rows == null || rows.isEmpty()) {
            return List.of();
        }
        List<ResendSendAttachmentDto> attachments = new ArrayList<>();
        for (MailAttJdbcRow row : rows) {
            if (Boolean.TRUE.equals(row.deletedYn()) || !StringUtils.hasText(row.storedName())) {
                continue;
            }
            Path file = resolveInside(mailDir(row.mailIdx()), row.storedName());
            if (!Files.isRegularFile(file)) {
                log.warn("첨부 실물이 없어 발송에서 제외 mailAttIdx={}", row.mailAttIdx());
                continue;
            }
            try {
                byte[] bytes = Files.readAllBytes(file);
                if (bytes.length > properties.getAttachmentMaxBytes()) {
                    log.warn("첨부가 너무 커서 발송에서 제외 mailAttIdx={} size={}",
                            row.mailAttIdx(), bytes.length);
                    continue;
                }
                attachments.add(new ResendSendAttachmentDto(
                        row.fileName(),
                        Base64.getEncoder().encodeToString(bytes),
                        clip(row.contentType(), CONTENT_TYPE_MAX),
                        // cid 는 인라인 이미지에만 의미가 있다. 일반 첨부에 넣으면
                        // 수신 클라이언트가 본문에 끼워 넣으려다 깨진 이미지를 보여 준다.
                        "Y".equals(row.inlineYn()) ? row.contentId() : null));
            } catch (IOException e) {
                log.warn("첨부 읽기 실패 — 발송에서 제외 mailAttIdx={}", row.mailAttIdx(), e);
            }
        }
        return attachments;
    }

    public record DownloadPayload(Resource resource, String fileName, String contentType) {
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    private boolean fetchOne(MailAttJdbcRow row) {
        final long mailAttIdx = row.mailAttIdx();
        txTemplate.executeWithoutResult(status -> mailAttMapper.markFetchTried(mailAttIdx));

        MailMstJdbcRow mail = mailMstMapper.selectByIdx(row.mailIdx());
        String resendEmailId = mail == null ? null : mail.resendEmailId();
        if (!StringUtils.hasText(resendEmailId) || !StringUtils.hasText(row.resendAttId())) {
            txTemplate.executeWithoutResult(status -> mailAttMapper.updateFetchFailed(
                    mailAttIdx, "Resend 첨부 식별자가 없어 파일을 받을 수 없습니다."));
            return false;
        }

        try {
            // download_url 은 1시간 만료라 저장해 두지 않고 받을 때마다 새로 얻는다.
            ResendAttachmentMetaDto meta = resendClient.getAttachment(resendEmailId, row.resendAttId());
            if (meta == null || !StringUtils.hasText(meta.downloadUrl())) {
                txTemplate.executeWithoutResult(status -> mailAttMapper.updateFetchFailed(
                        mailAttIdx, "Resend 응답에 다운로드 URL 이 없습니다."));
                return false;
            }
            byte[] bytes = resendClient.downloadAttachment(meta.downloadUrl());

            String originalName = sanitizeFileName(
                    StringUtils.hasText(meta.filename()) ? meta.filename() : row.fileName());
            if (originalName.isBlank()) {
                originalName = "attachment";
            }
            String storedName = clip(UUID.randomUUID() + "_" + originalName, STORED_NAME_MAX);
            Path targetDir = mailDir(row.mailIdx());
            Path targetFile = resolveInside(targetDir, storedName);
            Files.createDirectories(targetDir);
            Files.write(targetFile, bytes);

            String contentType = clip(
                    resolveContentType(
                            StringUtils.hasText(meta.contentType()) ? meta.contentType() : row.contentType(),
                            originalName),
                    CONTENT_TYPE_MAX);
            long size = bytes.length;
            txTemplate.executeWithoutResult(status ->
                    mailAttMapper.updateFetched(mailAttIdx, storedName, size, contentType));
            log.debug("메일 첨부 수집 완료 mailAttIdx={} size={}", mailAttIdx, size);
            return true;
        } catch (ResendApiException e) {
            int tried = (row.fetchTryCnt() == null ? 0 : row.fetchTryCnt()) + 1;
            if (e.retryable() && tried < properties.getSync().getMaxTryCnt()) {
                log.warn("메일 첨부 수집 일시 실패(재시도 예정) mailAttIdx={} status={} try={}",
                        mailAttIdx, e.statusCode(), tried);
                return false;
            }
            txTemplate.executeWithoutResult(status ->
                    mailAttMapper.updateFetchFailed(mailAttIdx, clip(e.getMessage(), ERR_MAX)));
            return false;
        } catch (IOException e) {
            log.error("메일 첨부 디스크 저장 실패 mailAttIdx={}", mailAttIdx, e);
            txTemplate.executeWithoutResult(status ->
                    mailAttMapper.updateFetchFailed(mailAttIdx, "파일 저장에 실패했습니다."));
            return false;
        }
    }

    private MailMstJdbcRow requireMail(long mailIdx) {
        MailMstJdbcRow row = mailMstMapper.selectByIdx(mailIdx);
        if (row == null || Boolean.TRUE.equals(row.deletedYn())) {
            throw new ResourceNotFoundException("메일", "mailIdx", mailIdx);
        }
        return row;
    }

    private MailAttJdbcRow requireAttachment(long mailAttIdx) {
        MailAttJdbcRow row = mailAttMapper.selectByIdx(mailAttIdx);
        if (row == null || Boolean.TRUE.equals(row.deletedYn())) {
            throw new ResourceNotFoundException("첨부 파일", "mailAttIdx", mailAttIdx);
        }
        return row;
    }

    private Path mailDir(long mailIdx) {
        return storageRoot.resolve("mails").resolve(String.valueOf(mailIdx)).normalize();
    }

    /**
     * 경로 탈출 방지. 파일명이 외부 발신자가 정한 값이라
     * {@code ../../} 이 섞여 들어오면 스토리지 밖에 파일을 쓰게 된다.
     */
    private static Path resolveInside(Path dir, String name) {
        Path target = dir.resolve(name).normalize();
        if (!target.startsWith(dir)) {
            throw new IllegalArgumentException("잘못된 파일 경로입니다.");
        }
        return target;
    }

    private static String sanitizeFileName(String name) {
        if (!StringUtils.hasText(name)) {
            return "";
        }
        String base = Path.of(name).getFileName().toString();
        return base.replaceAll("[\\\\/:*?\"<>|]", "_").trim();
    }

    private static String resolveContentType(String contentType, String fileName) {
        if (StringUtils.hasText(contentType)
                && !"application/octet-stream".equalsIgnoreCase(contentType.trim())) {
            return contentType.trim();
        }
        return inferContentType(fileName);
    }

    private static String inferContentType(String fileName) {
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
        if (lower.endsWith(".webp")) {
            return "image/webp";
        }
        if (lower.endsWith(".pdf")) {
            return "application/pdf";
        }
        if (lower.endsWith(".txt") || lower.endsWith(".csv")) {
            return "text/plain";
        }
        if (lower.endsWith(".zip")) {
            return "application/zip";
        }
        return "application/octet-stream";
    }

    private static int clampBatch(int limit) {
        return limit <= 0 ? 1 : Math.min(limit, MAX_BATCH);
    }

    private static String clip(String value, int max) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.length() <= max ? trimmed : trimmed.substring(0, max);
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
