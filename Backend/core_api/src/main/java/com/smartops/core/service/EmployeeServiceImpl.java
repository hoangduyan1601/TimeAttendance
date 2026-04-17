package com.smartops.core.service;

import com.smartops.core.dto.*;
import com.smartops.core.entity.*;
import com.smartops.core.repository.*;
import com.smartops.core.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EmployeeServiceImpl implements EmployeeService {

    private final AttendanceLogRepository attendanceLogRepository;
    private final LeaveRequestRepository leaveRequestRepository;
    private final ShiftChangeRequestRepository shiftChangeRequestRepository;
    private final ShiftConfigRepository shiftConfigRepository;
    private final UserRepository userRepository;

    @Override
    public List<AttendanceHistoryDTO> getMyAttendanceHistory(String startDate, String endDate) {
        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) throw new RuntimeException("Người dùng chưa đăng nhập");

        List<AttendanceLog> logs;
        if (startDate != null && endDate != null) {
            LocalDateTime start = LocalDate.parse(startDate).atStartOfDay();
            LocalDateTime end = LocalDate.parse(endDate).atTime(LocalTime.MAX);
            logs = attendanceLogRepository.findAllByUserIdAndCheckInTimeBetween(userId, start, end);
        } else {
            logs = attendanceLogRepository.findByUserIdOrderByCheckInTimeDesc(userId);
        }

        return logs.stream()
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
                .createdAt(savedRequest.getCreatedAt())
                .build();
    }

    @Override
    public ShiftChangeDTO submitShiftChangeRequest(ShiftChangeDTO request) {
        Long userId = SecurityUtils.getCurrentUserId();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại"));

        ShiftConfig oldShift = user.getAssignedShift();
        if (oldShift == null) {
            throw new RuntimeException("Bạn hiện chưa được gán ca làm việc cố định nào.");
        }

        ShiftConfig newShift = shiftConfigRepository.findById(request.getNewShiftId())
                .orElseThrow(() -> new RuntimeException("Ca làm việc mới không tồn tại"));

        if (oldShift.getId().equals(newShift.getId())) {
            throw new RuntimeException("Ca làm việc mới phải khác ca hiện tại.");
        }

        ShiftChangeRequest changeRequest = ShiftChangeRequest.builder()
                .user(user)
                .oldShift(oldShift)
                .newShift(newShift)
                .reason(request.getReason())
                .status("PENDING")
                .build();

        ShiftChangeRequest saved = shiftChangeRequestRepository.save(changeRequest);

        return mapToShiftChangeDTO(saved);
    }

    @Override
    public List<ShiftChangeDTO> getMyShiftChangeRequests() {
        Long userId = SecurityUtils.getCurrentUserId();
        return shiftChangeRequestRepository.findByUserId(userId).stream()
                .map(this::mapToShiftChangeDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<LeaveResponseDTO> getMyLeaveRequests() {
        Long userId = SecurityUtils.getCurrentUserId();
        return leaveRequestRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(leave -> LeaveResponseDTO.builder()
                        .id(leave.getId())
                        .fromDate(leave.getStartDate())
                        .toDate(leave.getEndDate())
                        .leaveType(leave.getLeaveType())
                        .reason(leave.getReason())
                        .status(leave.getStatus())
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    public UserResponseDTO getMyProfile() {
        Long userId = SecurityUtils.getCurrentUserId();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại"));
        
        return UserResponseDTO.builder()
                .id(user.getId())
                .username(user.getUsername())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .employeeCode(user.getEmployeeCode())
                .phoneNumber(user.getPhoneNumber())
                .role(user.getRole())
                .ekycStatus(user.getEkycStatus())
                .departmentName(user.getDepartment() != null ? user.getDepartment().getName() : null)
                .departmentId(user.getDepartment() != null ? user.getDepartment().getId() : null)
                .assignedShiftId(user.getAssignedShift() != null ? user.getAssignedShift().getId() : null)
                .assignedShiftName(user.getAssignedShift() != null ? user.getAssignedShift().getShiftName() : null)
                .idCardUrl(user.getFaceData() != null ? user.getFaceData().getIdCardUrl() : null)
                .selfieUrl(user.getFaceData() != null ? user.getFaceData().getSelfieUrl() : null)
                .build();
    }

    private ShiftChangeDTO mapToShiftChangeDTO(ShiftChangeRequest request) {
        return ShiftChangeDTO.builder()
                .id(request.getId())
                .userId(request.getUser().getId())
                .fullName(request.getUser().getFullName())
                .oldShiftId(request.getOldShift().getId())
                .oldShiftName(request.getOldShift().getShiftName())
                .newShiftId(request.getNewShift().getId())
                .newShiftName(request.getNewShift().getShiftName())
                .reason(request.getReason())
                .status(request.getStatus())
                .createdAt(request.getCreatedAt())
                .build();
    }
}

