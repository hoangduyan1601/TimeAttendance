package com.smartops.core.service;

import com.smartops.core.dto.AttendanceHistoryDTO;
import com.smartops.core.dto.LeaveRequestDTO;
import com.smartops.core.dto.LeaveResponseDTO;
import com.smartops.core.entity.AttendanceLog;
import com.smartops.core.entity.LeaveRequest;
import com.smartops.core.entity.User;
import com.smartops.core.repository.AttendanceLogRepository;
import com.smartops.core.repository.LeaveRequestRepository;
import com.smartops.core.repository.UserRepository;
import com.smartops.core.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EmployeeServiceImpl implements EmployeeService {

    private final AttendanceLogRepository attendanceLogRepository;
    private final LeaveRequestRepository leaveRequestRepository;
    private final UserRepository userRepository;

    @Override
    public List<AttendanceHistoryDTO> getMyAttendanceHistory() {
        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) throw new RuntimeException("Người dùng chưa đăng nhập");

        return attendanceLogRepository.findByUserIdOrderByCheckInTimeDesc(userId).stream()
                .map(log -> AttendanceHistoryDTO.builder()
                        .id(log.getId())
                        .checkInTime(log.getCheckInTime())
                        .status(log.getStatus())
                        .method(log.getVerifiedByFace() ? "FACE_ID" : "MANUAL")
                        .deviceId(log.getLocation())
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    public LeaveResponseDTO submitLeaveRequest(LeaveRequestDTO dto) {
        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) throw new RuntimeException("Người dùng chưa đăng nhập");

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Nhân sự không tồn tại"));

        LeaveRequest leaveRequest = LeaveRequest.builder()
                .user(user)
                .startDate(dto.getFromDate())
                .endDate(dto.getToDate())
                .leaveType(dto.getLeaveType())
                .reason(dto.getReason())
                .status("PENDING")
                .build();

        LeaveRequest savedRequest = leaveRequestRepository.save(leaveRequest);

        return LeaveResponseDTO.builder()
                .id(savedRequest.getId())
                .fromDate(savedRequest.getStartDate())
                .toDate(savedRequest.getEndDate())
                .leaveType(savedRequest.getLeaveType())
                .reason(savedRequest.getReason())
                .status(savedRequest.getStatus())
                .build();
    }
}
