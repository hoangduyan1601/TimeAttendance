package com.smartops.core.scheduler;

import com.smartops.core.entity.AttendanceLog;
import com.smartops.core.entity.Notification;
import com.smartops.core.entity.ShiftConfig;
import com.smartops.core.repository.AttendanceLogRepository;
import com.smartops.core.repository.NotificationRepository;
import com.smartops.core.service.EmailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class AttendanceMonitoringScheduler {

    private final AttendanceLogRepository attendanceLogRepository;
    private final NotificationRepository notificationRepository;
    private final EmailService emailService;

    /**
     * Chạy mỗi 15 phút để kiểm tra nhân viên chưa tan ca
     */
    @Scheduled(cron = "0 0/15 * * * *")
    public void checkOverdueCheckOut() {
        log.info("Bắt đầu kiểm tra nhân viên chưa tan ca quá giờ...");

        List<AttendanceLog> activeLogs = attendanceLogRepository.findByCheckOutTimeIsNull();
        LocalDateTime now = LocalDateTime.now();

        for (AttendanceLog logEntry : activeLogs) {
            ShiftConfig shift = logEntry.getShift();
            if (shift != null) {
                LocalTime shiftEndTime = shift.getEndTime();
                LocalDateTime overdueThreshold = LocalDateTime.of(logEntry.getCheckInTime().toLocalDate(), shiftEndTime).plusHours(1);

                if (now.isAfter(overdueThreshold)) {
                    String employeeName = logEntry.getUser().getFullName();
                    String employeeCode = logEntry.getUser().getEmployeeCode();

                    // Kiểm tra xem đã gửi thông báo cho nhân viên này trong hôm nay chưa
                    String alertTitle = "Cảnh báo quá giờ: " + employeeCode;
                    boolean alreadyNotified = notificationRepository.findAllByOrderByCreatedAtDesc().stream()
                            .anyMatch(n -> n.getTitle().equals(alertTitle) && n.getCreatedAt().toLocalDate().equals(now.toLocalDate()));

                    if (!alreadyNotified) {
                        String message = String.format("Nhân viên %s (%s) đã quá giờ tan ca (> 1 tiếng) nhưng chưa check-out. Ca làm việc kết thúc lúc: %s",
                                employeeName, employeeCode, shiftEndTime);

                        log.warn(message);

                        // 1. Lưu vào Database (In-app Notification)
                        notificationRepository.save(Notification.builder()
                                .title(alertTitle)
                                .message(message)
                                .type("ALERT")
                                .isRead(false)
                                .build());

                        // 2. Gửi Email cho Admin
                        emailService.sendOvertimeAlert(employeeName, employeeCode, shiftEndTime.toString());
                    }
                }
            }
        }
    }
}

