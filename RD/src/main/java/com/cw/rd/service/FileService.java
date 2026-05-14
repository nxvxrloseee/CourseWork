package com.cw.rd.service;

import io.minio.*;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class FileService {

    private final MinioClient minioClient;
    private final AesEncryptionService aesEncryptionService;

    @Value("${minio.bucket}")
    private String bucket;

    @Value("${minio.public-url:}")
    private String publicUrl;

    @PostConstruct
    public void init() {
        try {
            ensureBucketExists();
            log.info("MinIO bucket '{}' ready with public read policy", bucket);
        } catch (Exception e) {
            log.error("Failed to initialize MinIO bucket: {}", e.getMessage());
        }
    }

    public String uploadFile(MultipartFile file) {
        try {
            ensureBucketExists();

            String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();

            byte[] encrypted = aesEncryptionService.encryptBytes(file.getBytes());

            minioClient.putObject(PutObjectArgs.builder()
                    .bucket(bucket)
                    .object(filename)
                    .stream(new java.io.ByteArrayInputStream(encrypted), encrypted.length, -1)
                    .contentType("application/octet-stream")
                    .build());

            return filename;
        } catch (Exception e) {
            throw new RuntimeException("Ошибка загрузки файла: " + e.getMessage(), e);
        }
    }

    public byte[] downloadDecrypted(String filename) {
        try {
            byte[] raw;
            try (var stream = minioClient.getObject(GetObjectArgs.builder()
                    .bucket(bucket)
                    .object(filename)
                    .build())) {
                raw = stream.readAllBytes();
            }
            try {
                return aesEncryptionService.decryptBytes(raw);
            } catch (Exception e) {
                log.debug("File not encrypted, returning raw: {}", filename);
                return raw;
            }
        } catch (Exception e) {
            throw new RuntimeException("Ошибка скачивания файла: " + e.getMessage(), e);
        }
    }

    public String getOriginalContentType(String filename) {
        if (filename == null) return "application/octet-stream";
        String lower = filename.toLowerCase();
        if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
        if (lower.endsWith(".png")) return "image/png";
        if (lower.endsWith(".gif")) return "image/gif";
        if (lower.endsWith(".webp")) return "image/webp";
        if (lower.endsWith(".mp4")) return "video/mp4";
        if (lower.endsWith(".mov")) return "video/quicktime";
        if (lower.endsWith(".avi")) return "video/x-msvideo";
        return "application/octet-stream";
    }

    public String getFileUrl(String filename) {
        return "/api/files/" + filename;
    }

    private void ensureBucketExists() throws Exception {
        boolean exists = minioClient.bucketExists(BucketExistsArgs.builder().bucket(bucket).build());
        if (!exists) {
            minioClient.makeBucket(MakeBucketArgs.builder().bucket(bucket).build());
        }
        String policy = """
                {
                    "Version": "2012-10-17",
                    "Statement": [{
                        "Effect": "Allow",
                        "Principal": {"AWS": ["*"]},
                        "Action": ["s3:GetObject"],
                        "Resource": ["arn:aws:s3:::%s/*"]
                    }]
                }
                """.formatted(bucket);
        minioClient.setBucketPolicy(SetBucketPolicyArgs.builder()
                .bucket(bucket)
                .config(policy)
                .build());
    }
}
