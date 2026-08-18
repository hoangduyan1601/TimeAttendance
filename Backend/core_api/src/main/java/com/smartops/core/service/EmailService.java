package com.smartops.core.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username:noreply@example.com}")
    private String fromEmail;

    @Value("${admin.email}")
    private String adminEmail;

    public void sendOvertimeAlert(String employeeName, String employeeCode, String endTime) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(adminEmail);
            message.setSubject("CẢNH BÁO: Nhân viên ở lại quá giờ - SmartOps");
            message.setText(String.format(
                "Kính gửi Admin,\n\n" +
                "Hệ thống phát hiện nhân viên sau đây đã quá giờ tan ca hơn 1 tiếng nhưng chưa thực hiện check-out:\n\n" +
                "- Họ tên: %s\n" +
                "- Mã nhân viên: %s\n" +
                "- Giờ kết thúc ca: %s\n" +
                "- Thời điểm phát hiện: %s\n\n" +
                "Vui lòng kiểm tra và xử lý.\n" +
                "Trân trọng,\nSmartOps System",
                employeeName, employeeCode, endTime, java.time.LocalDateTime.now()
            ));

            // mailSender.send(message); // Tạm thời tắt để không lỗi khi chưa có pass
            log.info("MÔ PHỎNG: Đã gửi email cảnh báo tới {} cho nhân viên {}", adminEmail, employeeName);
        } catch (Exception e) {
            log.error("Lỗi khi gửi email: {}", e.getMessage());
        }
    }
}
