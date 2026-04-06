package com.smartops.core.service;

import com.smartops.core.dto.*;
import com.smartops.core.entity.AttendanceLog;
import com.smartops.core.entity.FaceData;
import com.smartops.core.entity.ShiftConfig;
import com.smartops.core.entity.User;
import com.smartops.core.repository.AttendanceLogRepository;
import com.smartops.core.repository.FaceDataRepository;
import com.smartops.core.repository.ShiftConfigRepository;
import com.smartops.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AttendanceServiceImpl implements AttendanceService {

    private final AttendanceLogRepository attendanceLogRepository;
    private final UserRepository userRepository;
    private final ShiftConfigRepository shiftConfigRepository;
    private final ShiftConfigService shiftConfigService;
    private final FaceDataRepository faceDataRepository;
    private final WebClient webClient;

    @Value("${ai-service.url}")
    private String aiServiceUrl;

    @Value("${ai-service.compare-endpoint}")
    private String compareEndpoint;

    @Override
    public KioskVerifyResponse verify(KioskVerifyRequest request) {
        // 1. Giải mã và kiểm tra QR Token
        String decodedToken;
        try {
            decodedToken = new String(Base64.getDecoder().decode(request.getQrToken()), StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new RuntimeException("Mã QR không hợp lệ");
        }

        String[] parts = decodedToken.split(":");
        if (parts.length != 2) throw new RuntimeException("Định dạng QR không đúng");

        Long userId = Long.parseLong(parts[0]);
        long timestamp = Long.parseLong(parts[1]);

        // Kiểm tra TTL 30 giây
        if (System.currentTimeMillis() - timestamp > 30000) {
            throw new RuntimeException("Mã QR đã hết hạn (quá 30 giây)");
        }

        // 2. Lấy thông tin User và FaceData
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Nhân sự không tồn tại"));
        
        FaceData faceData = faceDataRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Nhân sự chưa đăng ký khuôn mặt (eKYC)"));

        // 3. Gọi AI Microservice để so sánh
        AiCompareRequest aiRequest = AiCompareRequest.builder()
                .storedVector(faceData.getFaceVector())
                .liveImageBase64(request.getLiveImageBase64())
                .build();

        AiCompareResponse aiResponse = webClient.post()
                .uri(aiServiceUrl + compareEndpoint)
                .bodyValue(aiRequest)
                .retrieve()
                .bodyToMono(AiCompareResponse.class)
                .block();

        if (aiResponse == null || !aiResponse.isMatch()) {
            throw new RuntimeException("Xác thực khuôn mặt thất bại. Độ tương đồng: " 
                    + (aiResponse != null ? aiResponse.getSimilarity() : 0));
        }

        // 4. Xác định ca làm và ghi log
        LocalDateTime now = LocalDateTime.now();
        ShiftConfigDTO activeShiftDTO = shiftConfigService.getActiveShift(now.toLocalTime());
        if (activeShiftDTO == null) {
            throw new RuntimeException("Hiện không trong ca làm việc nào.");
        }

        ShiftConfig shiftConfig = shiftConfigRepository.findById(activeShiftDTO.getId())
                .orElseThrow(() -> new RuntimeException("Cấu hình ca làm việc không tồn tại"));
        
        String status = "ON_TIME";
        int gracePeriod = shiftConfig.getLateThresholdMinutes() != null ? shiftConfig.getLateThresholdMinutes() : 0;
        if (now.toLocalTime().isAfter(shiftConfig.getStartTime().plusMinutes(gracePeriod))) {
            status = "LATE";
        }

        AttendanceLog log = AttendanceLog.builder()
                .user(user)
                .shift(shiftConfig)
                .checkInTime(now)
                .status(status)
                .location(request.getKioskId())
                .verifiedByFace(true)
                .build();
        attendanceLogRepository.save(log);

        return KioskVerifyResponse.builder()
                .employeeName(user.getFullName())
                .time(now.format(DateTimeFormatter.ofPattern("HH:mm:ss")))
                .attendanceStatus(status)
                .similarityScore(aiResponse.getSimilarity())
                .build();
    }

    @Override
    public List<AttendanceResponseDTO> getLiveLogs() {
        return attendanceLogRepository.findTop10ByOrderByCheckInTimeDesc().stream()
                .map(log -> AttendanceResponseDTO.builder()
                        .id(log.getId())
                        .fullName(log.getUser().getFullName())
                        .employeeCode(log.getUser().getEmployeeCode())
                        .shiftName(log.getShift() != null ? log.getShift().getShiftName() : "N/A")
                        .checkInTime(log.getCheckInTime())
                        .status(log.getStatus())
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    public AttendanceResponseDTO checkIn(AttendanceRequestDTO request) {
        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new RuntimeException("Nhân sự không tồn tại"));

        LocalDateTime now = LocalDateTime.now();
        LocalTime currentTime = now.toLocalTime();

        ShiftConfigDTO activeShiftDTO = shiftConfigService.getActiveShift(currentTime);
        if (activeShiftDTO == null) {
            throw new RuntimeException("Không tìm thấy ca làm việc phù hợp tại thời điểm này.");
        }

        ShiftConfig shiftConfig = shiftConfigRepository.findById(activeShiftDTO.getId())
                .orElseThrow(() -> new RuntimeException("Cấu hình ca làm việc không hợp lệ."));

        LocalTime shiftStartTime = shiftConfig.getStartTime();
        int gracePeriod = shiftConfig.getLateThresholdMinutes() != null ? shiftConfig.getLateThresholdMinutes() : 0;
        LocalTime allowedStartTime = shiftStartTime.plusMinutes(gracePeriod);

        String status = "ON_TIME";
        long minutesLate = 0;

        if (currentTime.isAfter(allowedStartTime)) {
            status = "LATE";
            minutesLate = Duration.between(shiftStartTime, currentTime).toMinutes();
        }

        AttendanceLog log = AttendanceLog.builder()
                .user(user)
                .shift(shiftConfig)
                .checkInTime(now)
                .status(status)
                .location(request.getLocation())
                .verifiedByFace(true)
                .build();

        AttendanceLog savedLog = attendanceLogRepository.save(log);

        return AttendanceResponseDTO.builder()
                .id(savedLog.getId())
                .fullName(user.getFullName())
                .employeeCode(user.getEmployeeCode())
                .shiftName(shiftConfig.getShiftName())
                .checkInTime(now)
                .status(status)
                .minutesLate(minutesLate)
                .build();
    }
}
