package com.smartops.core.service;

import com.smartops.core.dto.AiVectorResponse;
import com.smartops.core.dto.EkycAiResponse;
import com.smartops.core.entity.FaceData;
import com.smartops.core.entity.Notification;
import com.smartops.core.entity.User;
import com.smartops.core.repository.FaceDataRepository;
import com.smartops.core.repository.NotificationRepository;
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
    private final NotificationRepository notificationRepository;
    private final WebClient webClient;

    @Value("${upload.path}")
    private String uploadPath;

    @Value("${ai-service.url}")
    private String aiServiceUrl;

    @Value("${ai-service.extract-endpoint}")
    private String extractEndpoint;

    @Override
    @Transactional
    public void registerEkyc(Long userId, MultipartFile selfieImage) {
        registerEkyc(userId, null, selfieImage);
    }

    @Override
    @Transactional
    public void registerEkyc(Long userId, MultipartFile idCardImage, MultipartFile selfieImage) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Nhân sự không tồn tại"));

        // 1. Lưu ảnh cục bộ
        String selfieFileName = saveFile(selfieImage, "FACE_" + userId);
        String idCardFileName = null;
        if (idCardImage != null && !idCardImage.isEmpty()) {
            idCardFileName = saveFile(idCardImage, "ID_" + userId);
        }

        // 2. Gọi AI Service
        double[] faceVector;
        Double ekycSimilarity = null;
        String idNumber = null;
        String fullNameOnId = null;

        if (idCardImage != null && !idCardImage.isEmpty()) {
            // Luồng eKYC nâng cao: so khớp CCCD vs selfie và lấy vector từ selfie
            EkycAiResponse verify = callAiServiceToVerifyEkyc(idCardImage, selfieImage);
            ekycSimilarity = verify.getSimilarity();
            faceVector = verify.getVector();

            if (verify.getOcrData() != null) {
                Object idNum = verify.getOcrData().get("idNumber");
                Object name = verify.getOcrData().get("fullName");
                idNumber = idNum != null ? idNum.toString() : null;
                fullNameOnId = name != null ? name.toString() : null;
            }
        } else {
            // Luồng selfie-only: chỉ trích vector
            faceVector = callAiServiceToExtractVector(selfieImage);
        }

        // 3. Lưu FaceData
        FaceData faceData = faceDataRepository.findByUserId(userId)
                .orElse(FaceData.builder().user(user).build());

        faceData.setFaceVector(faceVector);
        faceData.setSelfieUrl("/uploads/ekyc/" + selfieFileName);
        if (idCardFileName != null) {
            faceData.setIdCardUrl("/uploads/ekyc/" + idCardFileName);
        }
        if (ekycSimilarity != null) {
            faceData.setEkycSimilarity(ekycSimilarity);
        }
        if (idNumber != null) {
            faceData.setIdNumber(idNumber);
        }
        if (fullNameOnId != null) {
            faceData.setFullNameOnId(fullNameOnId);
        }
        faceData.setLastUpdated(LocalDateTime.now());
        faceDataRepository.save(faceData);

        // 4. Chuyển về PENDING để Admin duyệt thủ công
        user.setEkycStatus("PENDING");
        userRepository.save(user);

        // 5. Tạo thông báo cho Admin
        notificationRepository.save(Notification.builder()
                .title("Yêu cầu phê duyệt eKYC mới")
                .message("Nhân viên " + user.getFullName() + " (" + user.getEmployeeCode() + ") vừa gửi yêu cầu định danh eKYC.")
                .type("SYSTEM")
                .isRead(false)
                .build());

        log.info("Đã đăng ký khuôn mặt thành công cho User ID: {}. Chờ duyệt.", userId);
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

    private EkycAiResponse callAiServiceToVerifyEkyc(MultipartFile idCard, MultipartFile selfie) {
        try {
            MultipartBodyBuilder builder = new MultipartBodyBuilder();
            builder.part("id_card", idCard.getResource());
            builder.part("selfie", selfie.getResource());

            EkycAiResponse response = webClient.post()
                    .uri(aiServiceUrl + "/internal/ai/verify-ekyc")
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(BodyInserters.fromMultipartData(builder.build()))
                    .retrieve()
                    .bodyToMono(EkycAiResponse.class)
                    .block();
            
            if (response == null) {
                throw new RuntimeException("AI Service không phản hồi");
            }
            
            return response;

        } catch (Exception e) {
            log.error("Lỗi khi gọi AI Service (Verify eKYC): {}", e.getMessage());
            throw new RuntimeException("Hệ thống nhận diện đang gặp sự cố: " + e.getMessage());
        }
    }

    private double[] callAiServiceToExtractVector(MultipartFile file) {
        try {
            MultipartBodyBuilder builder = new MultipartBodyBuilder();
            // Đảm bảo truyền đủ Filename và Content-Type cho AI Service
            builder.part("file", file.getResource())
                   .filename(file.getOriginalFilename())
                   .contentType(MediaType.parseMediaType(file.getContentType() != null ? file.getContentType() : "image/jpeg"));

            AiVectorResponse response = webClient.post()
                    .uri(aiServiceUrl + "/internal/ai/embed")
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(BodyInserters.fromMultipartData(builder.build()))
                    .retrieve()
                    .bodyToMono(AiVectorResponse.class)
                    .block();
            
            if (response == null || response.getVector() == null) {
                throw new RuntimeException("Không thể nhận diện khuôn mặt từ ảnh chụp");
            }
            
            return response.getVector();

        } catch (Exception e) {
            log.error("Lỗi khi gọi AI Service (Embed): {}", e.getMessage());
            throw new RuntimeException("Hệ thống nhận diện đang gặp sự cố: " + e.getMessage());
        }
    }
}
