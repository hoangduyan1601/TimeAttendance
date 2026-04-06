package com.smartops.core.service;

import com.smartops.core.dto.AiVectorResponse;
import com.smartops.core.entity.FaceData;
import com.smartops.core.entity.User;
import com.smartops.core.repository.FaceDataRepository;
import com.smartops.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.MultipartBodyBuilder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class EkycServiceImpl implements EkycService {

    private final UserRepository userRepository;
    private final FaceDataRepository faceDataRepository;
    private final WebClient webClient;

    @Value("${upload.path}")
    private String uploadPath;

    @Value("${ai-service.url}")
    private String aiServiceUrl;

    @Value("${ai-service.extract-endpoint}")
    private String extractEndpoint;

    @Override
    @Transactional
    public void registerEkyc(Long userId, MultipartFile idCardImage, MultipartFile selfieImage) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Nhân sự không tồn tại"));

        // 1. Lưu ảnh cục bộ (Local Storage)
        String idCardFileName = saveFile(idCardImage, "ID_" + userId);
        String selfieFileName = saveFile(selfieImage, "SELFIE_" + userId);

        // 2. Gọi AI Microservice để lấy Face Vector
        double[] faceVector = callAiServiceToExtractVector(selfieImage);

        // 3. Lưu hoặc cập nhật FaceData
        FaceData faceData = faceDataRepository.findByUserId(userId)
                .orElse(FaceData.builder().user(user).build());

        faceData.setFaceVector(faceVector);
        // URL để hiển thị: http://localhost:8081/uploads/ekyc/SELFIE_...
        String selfieUrl = "/uploads/ekyc/" + selfieFileName;
        faceData.setLastUpdated(LocalDateTime.now());
        faceDataRepository.save(faceData);

        // 4. Cập nhật trạng thái User
        user.setEkycStatus("PENDING");
        userRepository.save(user);

        log.info("Đã đăng ký eKYC thành công cho User ID: {}. Ảnh lưu tại: {}", userId, selfieUrl);
    }

    private String saveFile(MultipartFile file, String prefix) {
        try {
            File directory = new File(uploadPath);
            if (!directory.exists()) {
                directory.mkdirs();
            }

            String fileName = prefix + "_" + UUID.randomUUID().toString() + "_" + file.getOriginalFilename();
            Path path = Paths.get(uploadPath, fileName);
            Files.copy(file.getInputStream(), path);
            return fileName;
        } catch (IOException e) {
            log.error("Lỗi khi lưu file: {}", e.getMessage());
            throw new RuntimeException("Không thể lưu ảnh cục bộ: " + e.getMessage());
        }
    }

    private double[] callAiServiceToExtractVector(MultipartFile file) {
        try {
            MultipartBodyBuilder builder = new MultipartBodyBuilder();
            builder.part("file", file.getResource());

            AiVectorResponse response = webClient.post()
                    .uri(aiServiceUrl + extractEndpoint)
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(BodyInserters.fromMultipartData(builder.build()))
                    .retrieve()
                    .bodyToMono(AiVectorResponse.class)
                    .block();
            
            if (response == null || response.getVector() == null) {
                throw new RuntimeException("Không thể nhận diện khuôn mặt từ ảnh Selfie");
            }
            
            return response.getVector();

        } catch (Exception e) {
            log.error("Lỗi khi gọi AI Service: {}", e.getMessage());
            throw new RuntimeException("Hệ thống nhận diện khuôn mặt đang gặp sự cố: " + e.getMessage());
        }
    }
}
