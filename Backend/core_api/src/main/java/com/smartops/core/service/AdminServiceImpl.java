package com.smartops.core.service;

import com.smartops.core.dto.AttendanceAdjustDTO;
import com.smartops.core.dto.AttendanceResponseDTO;
import com.smartops.core.dto.LeaveResponseDTO;
import com.smartops.core.dto.LeaveReviewDTO;
import com.smartops.core.entity.AttendanceLog;
import com.smartops.core.entity.LeaveRequest;
import com.smartops.core.entity.User;
import com.smartops.core.repository.AttendanceLogRepository;
import com.smartops.core.repository.LeaveRequestRepository;
import com.smartops.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.time.LocalTime;

import com.smartops.core.dto.EkycReviewDTO;

@Service
@RequiredArgsConstructor
public class AdminServiceImpl implements AdminService {

    private final LeaveRequestRepository leaveRequestRepository;
    private final AttendanceLogRepository attendanceLogRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional
    public void reviewEkyc(Long userId, EkycReviewDTO dto) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy nhân sự với ID: " + userId));
        
        user.setEkycStatus(dto.getStatus());
        userRepository.save(user);
    }

    @Override
    @Transactional
    public LeaveResponseDTO reviewLeave(Long leaveId, LeaveReviewDTO dto) {
        LeaveRequest leaveRequest = leaveRequestRepository.findById(leaveId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy đơn xin nghỉ với ID: " + leaveId));

        leaveRequest.setStatus(dto.getStatus());
        LeaveRequest updated = leaveRequestRepository.save(leaveRequest);

        return LeaveResponseDTO.builder()
                .id(updated.getId())
                .fromDate(updated.getStartDate())
                .toDate(updated.getEndDate())
                .leaveType(updated.getLeaveType())
                .reason(updated.getReason())
                .status(updated.getStatus())
                .build();
    }

    @Override
    @Transactional
    public AttendanceResponseDTO adjustAttendance(AttendanceAdjustDTO dto) {
        User user = userRepository.findByEmployeeCode(dto.getEmployeeCode())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy nhân sự với mã: " + dto.getEmployeeCode()));

        LocalDateTime startOfDay = dto.getDate().atStartOfDay();
        LocalDateTime endOfDay = dto.getDate().atTime(LocalTime.MAX);

        AttendanceLog log = attendanceLogRepository.findByUserIdAndCheckInTimeBetween(user.getId(), startOfDay, endOfDay)
                .orElse(new AttendanceLog());

        log.setUser(user);
        log.setCheckInTime(dto.getDate().atTime(dto.getNewCheckInTime()));
        log.setStatus("MANUAL_ADJUST"); // Đánh dấu là hiệu chỉnh thủ công
        log.setLocation("Hệ thống Admin - Lý do: " + dto.getReason());
        log.setVerifiedByFace(false); // Hiệu chỉnh thủ công thì không qua mặt

        AttendanceLog savedLog = attendanceLogRepository.save(log);

        return AttendanceResponseDTO.builder()
                .id(savedLog.getId())
                .fullName(user.getFullName())
                .employeeCode(user.getEmployeeCode())
                .checkInTime(savedLog.getCheckInTime())
                .status(savedLog.getStatus())
                .build();
    }
}
