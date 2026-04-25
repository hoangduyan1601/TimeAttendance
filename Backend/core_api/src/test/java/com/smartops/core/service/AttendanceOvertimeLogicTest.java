package com.smartops.core.service;

import com.smartops.core.dto.AuthResponse;
import com.smartops.core.dto.KioskVerifyRequest;
import com.smartops.core.dto.KioskVerifyResponse;
import com.smartops.core.entity.AttendanceLog;
import com.smartops.core.entity.OvertimeRequest;
import com.smartops.core.entity.ShiftConfig;
import com.smartops.core.entity.User;
import com.smartops.core.repository.AttendanceLogRepository;
import com.smartops.core.repository.FaceDataRepository;
import com.smartops.core.repository.OvertimeRequestRepository;
import com.smartops.core.repository.ShiftConfigRepository;
import com.smartops.core.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class AttendanceOvertimeLogicTest {

    @InjectMocks
    private AttendanceServiceImpl attendanceService;

    @Mock private AttendanceLogRepository attendanceLogRepository;
    @Mock private UserRepository userRepository;
    @Mock private ShiftConfigRepository shiftConfigRepository;
    @Mock private ShiftConfigService shiftConfigService;
    @Mock private FaceDataRepository faceDataRepository;
    @Mock private OvertimeRequestRepository overtimeRequestRepository;
    @Mock private WebClient webClient;

    private User testUser;
    private ShiftConfig testShift;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        
        testShift = ShiftConfig.builder()
                .id(1L)
                .shiftName("Hành chính")
                .startTime(LocalTime.of(8, 0))
                .endTime(LocalTime.of(17, 30))
                .build();

        testUser = User.builder()
                .id(1L)
                .fullName("Nguyễn Văn A")
                .assignedShift(testShift)
                .build();
    }

    @Test
    void testCheckOut_WithoutOvertime_ShouldCapTime() {
        // Giả lập: Nhân viên đã check-in lúc 8:00 sáng
        LocalDateTime checkInTime = LocalDateTime.of(LocalDate.now(), LocalTime.of(8, 0));
        AttendanceLog existingLog = AttendanceLog.builder()
                .id(100L)
                .user(testUser)
                .shift(testShift)
                .checkInTime(checkInTime)
                .build();

        // Giả lập: Hiện tại là 19:00 (muộn hơn giờ tan ca 17:30)
        // Lưu ý: Trong Service dùng LocalDateTime.now(), ở đây ta mock logic xử lý kết quả
        
        when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));
        when(attendanceLogRepository.findAllByUserIdAndCheckInTimeBetween(any(), any(), any()))
                .thenReturn(List.of(existingLog));
        
        // Mock KHÔNG có đơn OT nào được duyệt
        when(overtimeRequestRepository.findByUserIdAndDateAndStatus(any(), any(), eq("APPROVED")))
                .thenReturn(Collections.emptyList());

        // Thực hiện logic (Sử dụng một spy hoặc mock getUserByQrToken để tránh giải mã phức tạp)
        // Ở đây tôi sẽ giả định getUserByQrToken trả về user 1
        // Vì verify gọi getUserByQrToken nội bộ, tôi sẽ sửa service để nhận User trực tiếp hoặc mock private method (khó)
        // Cách tốt nhất là mock getUserByQrToken nếu nó public
    }
}
