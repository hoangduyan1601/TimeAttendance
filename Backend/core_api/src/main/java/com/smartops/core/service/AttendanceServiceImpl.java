package com.smartops.core.service;

import com.smartops.core.dto.*;
import com.smartops.core.entity.*;
import com.smartops.core.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
@Slf4j
public class AttendanceServiceImpl implements AttendanceService {

    private final AttendanceLogRepository attendanceLogRepository;
    private final UserRepository userRepository;
    private final ShiftConfigRepository shiftConfigRepository;
    private final ShiftConfigService shiftConfigService;
    private final FaceDataRepository faceDataRepository;
    private final OvertimeRequestRepository overtimeRequestRepository;
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

        // CHỈ CHO PHÉP NẾU ĐÃ DUYỆT EKYC
        if (!"APPROVED".equals(user.getEkycStatus())) {
            throw new RuntimeException("Tài khoản chưa được phê duyệt định danh eKYC. Vui lòng liên hệ Admin.");
        }

        // 2. Gọi AI (Xác thực khuôn mặt)
        double similarity = 0.0;
        boolean isMatch = false;
        
        FaceData faceData = faceDataRepository.findByUserId(user.getId())
                .orElseThrow(() -> new RuntimeException("Dữ liệu khuôn mặt chưa được khởi tạo. Vui lòng thực hiện eKYC."));
        
        String liveImage = request.getLiveImageBase64();
        if (liveImage == null || liveImage.isEmpty()) {
            throw new RuntimeException("Không nhận được hình ảnh từ Camera.");
        }

        try {
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
                isMatch = aiResponse.isMatch(); // Sử dụng isMatch từ AI Service
            }
        } catch (Exception e) {
            log.error("Lỗi AI Service: {}", e.getMessage());
            throw new RuntimeException("Hệ thống nhận diện khuôn mặt đang gặp sự cố. Thử lại sau.");
        }

        if (!isMatch) {
            throw new RuntimeException("Xác thực khuôn mặt thất bại (Độ khớp: " + Math.round(similarity * 100) + "%). Vui lòng thử lại.");
        }

        // 3. Xác định trạng thái VÀO CA hoặc TAN CA
        LocalDateTime now = LocalDateTime.now();
        java.time.LocalDate today = now.toLocalDate();
        
        // Tìm bản ghi đầu tiên trong ngày để xem là Check-in hay Check-out
        List<AttendanceLog> logsToday = attendanceLogRepository.findAllByUserIdAndCheckInTimeBetween(
                user.getId(), today.atStartOfDay(), today.atTime(23, 59, 59));

        AttendanceLog attendanceLog;
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

            attendanceLog = AttendanceLog.builder()
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
            attendanceLog = logsToday.get(logsToday.size() - 1);
            
            LocalDateTime checkOutTime = now;
            ShiftConfig shift = attendanceLog.getShift();
            
            if (shift != null) {
                LocalTime shiftEndTime = shift.getEndTime();
                if (now.toLocalTime().isAfter(shiftEndTime)) {
                    // Kiểm tra xem có đơn OT được duyệt không
                    List<OvertimeRequest> otRequests = overtimeRequestRepository.findByUserIdAndDateAndStatus(
                            user.getId(), today, "APPROVED");
                    
                    if (otRequests.isEmpty()) {
                        // Không có đơn OT -> Giới hạn giờ về đúng giờ ca làm việc
                        checkOutTime = LocalDateTime.of(today, shiftEndTime);
                        status = "CHECK_OUT_CAP_NO_OT";
                    } else {
                        // Có đơn OT -> Kiểm tra xem có về quá giờ OT không
                        LocalTime maxOtTime = otRequests.stream()
                                .map(OvertimeRequest::getEndTime)
                                .max(LocalTime::compareTo)
                                .orElse(shiftEndTime);
                        
                        if (now.toLocalTime().isAfter(maxOtTime)) {
                            checkOutTime = LocalDateTime.of(today, maxOtTime);
                            status = "CHECK_OUT_CAP_OT_EXCEEDED";
                        } else {
                            status = "CHECK_OUT_WITH_OT";
                        }
                    }
                } else {
                    status = "CHECK_OUT_NORMAL";
                }
            } else {
                status = "CHECK_OUT";
            }
            
            attendanceLog.setCheckOutTime(checkOutTime);
        }
        
        attendanceLogRepository.save(attendanceLog);

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

        AttendanceLog attendanceLog = AttendanceLog.builder()
                .user(user)
                .shift(shiftConfig)
                .checkInTime(now)
                .status(status)
                .location(request.getLocation())
                .verifiedByFace(true)
                .build();

        AttendanceLog savedLog = attendanceLogRepository.save(attendanceLog);

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
