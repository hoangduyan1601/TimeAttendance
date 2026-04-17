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
        // 1. Giải mã QR lấy User
        AuthResponse.UserSummary userSummary = getUserByQrToken(request.getQrToken());
        User user = userRepository.findById(userSummary.getId())
                .orElseThrow(() -> new RuntimeException("Nhân sự không tồn tại"));

        // 2. Gọi AI (Xác thực khuôn mặt)
        double similarity = 0.0;
        boolean isMatch = false;
        try {
            FaceData faceData = faceDataRepository.findByUserId(user.getId()).orElse(null);
            String liveImage = request.getLiveImageBase64();
            
            if (faceData != null && liveImage != null && !liveImage.isEmpty()) {
                AiCompareRequest aiRequest = AiCompareRequest.builder()
                        .storedVector(faceData.getFaceVector())
                        .liveImageBase64(liveImage)
                        .build();
                
                AiCompareResponse aiResponse = webClient.post()
                        .uri(aiServiceUrl + compareEndpoint)
                        .bodyValue(aiRequest)
                        .retrieve()
                        .bodyToMono(AiCompareResponse.class)
                        .block();
                if (aiResponse != null) {
                    similarity = aiResponse.getSimilarity();
                    isMatch = similarity >= 0.4; // Ngưỡng chấp nhận
                }
            }
        } catch (Exception e) {
            System.err.println("AI Service Error (Bypassed): " + e.getMessage());
            // Bỏ qua lỗi AI để tiếp tục chấm công
        }

        // 3. Xác định trạng thái VÀO CA hoặc TAN CA
        LocalDateTime now = LocalDateTime.now();
        java.time.LocalDate today = now.toLocalDate();
        
        // Tìm bản ghi đầu tiên trong ngày để xem là Check-in hay Check-out
        List<AttendanceLog> logsToday = attendanceLogRepository.findAllByUserIdAndCheckInTimeBetween(
                user.getId(), today.atStartOfDay(), today.atTime(23, 59, 59));

        AttendanceLog log;
        String attendanceType;
        String status = "SUCCESS";

        if (logsToday.isEmpty()) {
            // Lần quét đầu tiên trong ngày -> CHECK-IN
            attendanceType = "VÀO CA";
            
            ShiftConfig shiftConfig = user.getAssignedShift();
            
            // Nếu không có ca cố định, mới tìm ca linh hoạt
            if (shiftConfig == null) {
                ShiftConfigDTO activeShiftDTO = shiftConfigService.getActiveShift(now.toLocalTime());
                if (activeShiftDTO != null) {
                    shiftConfig = shiftConfigRepository.findById(activeShiftDTO.getId()).orElse(null);
                }
            }
            
            if (shiftConfig != null) {
                int grace = shiftConfig.getLateThresholdMinutes() != null ? shiftConfig.getLateThresholdMinutes() : 0;
                status = now.toLocalTime().isAfter(shiftConfig.getStartTime().plusMinutes(grace)) ? "LATE" : "ON_TIME";
            }

            log = AttendanceLog.builder()
                    .user(user)
                    .shift(shiftConfig)
                    .checkInTime(now)
                    .status(status)
                    .location(request.getKioskId())
                    .verifiedByFace(true)
                    .build();
        } else {
            // Đã có bản ghi -> Cập nhật CHECK-OUT vào bản ghi cuối cùng của ngày
            attendanceType = "TAN CA";
            log = logsToday.get(logsToday.size() - 1);
            log.setCheckOutTime(now);
            status = "CHECK_OUT";
            // Nếu cần có thể tính toán xem có về sớm không ở đây
        }
        
        attendanceLogRepository.save(log);

        return KioskVerifyResponse.builder()
                .employeeName(user.getFullName() + " [" + attendanceType + "]")
                .time(now.format(DateTimeFormatter.ofPattern("HH:mm:ss")))
                .attendanceStatus(status)
                .similarityScore(similarity)
                .build();
    }

    @Override
    public AuthResponse.UserSummary getUserByQrToken(String qrToken) {
        try {
            // Giải mã Base64
            String decoded = new String(Base64.getDecoder().decode(qrToken), StandardCharsets.UTF_8);
            
            // Xử lý định dạng mới: "SMARTOPS_USER_" + ID
            if (!decoded.startsWith("SMARTOPS_USER_")) {
                throw new RuntimeException("Mã QR không hợp lệ (Sai định dạng hệ thống)");
            }
            
            String idStr = decoded.replace("SMARTOPS_USER_", "");
            Long userId = Long.parseLong(idStr);

            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy nhân viên"));

            return AuthResponse.UserSummary.builder()
                    .id(user.getId())
                    .fullName(user.getFullName())
                    .role(user.getRole())
                    .build();
        } catch (Exception e) {
            throw new RuntimeException("Mã QR không hợp lệ hoặc đã hết hạn: " + e.getMessage());
        }
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
                        .checkOutTime(log.getCheckOutTime())
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
