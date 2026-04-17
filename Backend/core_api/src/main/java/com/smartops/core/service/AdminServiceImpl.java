package com.smartops.core.service;

import com.smartops.core.dto.AttendanceAdjustDTO;
import com.smartops.core.dto.AttendanceResponseDTO;
import com.smartops.core.dto.LeaveResponseDTO;
import com.smartops.core.dto.LeaveReviewDTO;
import com.smartops.core.entity.AttendanceLog;
import com.smartops.core.entity.LeaveRequest;
import com.smartops.core.entity.ShiftConfig;
import com.smartops.core.entity.User;
import com.smartops.core.repository.AttendanceLogRepository;
import com.smartops.core.repository.LeaveRequestRepository;
import com.smartops.core.repository.ShiftConfigRepository;
import com.smartops.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

import com.smartops.core.dto.EkycReviewDTO;

import com.smartops.core.dto.UserResponseDTO;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminServiceImpl implements AdminService {

    private final LeaveRequestRepository leaveRequestRepository;
    private final AttendanceLogRepository attendanceLogRepository;
    private final UserRepository userRepository;
    private final ShiftConfigRepository shiftConfigRepository;

    @Override
    public List<AttendanceResponseDTO> getAttendanceReports(LocalDate startDate, LocalDate endDate) {
        LocalDateTime start = startDate.atStartOfDay();
        LocalDateTime end = endDate.atTime(23, 59, 59);
        
        return attendanceLogRepository.findByCheckInTimeBetweenOrderByCheckInTimeAsc(start, end).stream()
                .map(log -> AttendanceResponseDTO.builder()
                        .id(log.getId())
                        .fullName(log.getUser() != null ? log.getUser().getFullName() : "N/A")
                        .employeeCode(log.getUser() != null ? log.getUser().getEmployeeCode() : "N/A")
                        .shiftName(log.getShift() != null ? log.getShift().getShiftName() : "N/A")
                        .checkInTime(log.getCheckInTime())
                        .checkOutTime(log.getCheckOutTime())
                        .status(log.getStatus())
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    public List<LeaveResponseDTO> getAllLeaveRequests() {
        return leaveRequestRepository.findAll().stream()
                .map(leave -> LeaveResponseDTO.builder()
                        .id(leave.getId())
                        .fromDate(leave.getStartDate())
                        .toDate(leave.getEndDate())
                        .leaveType(leave.getLeaveType())
                        .reason(leave.getReason())
                        .status(leave.getStatus())
                        .fullName(leave.getUser() != null ? leave.getUser().getFullName() : "N/A")
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    public List<UserResponseDTO> getPendingEkycRequests() {
        return userRepository.findAllByEkycStatus("PENDING").stream()
                .map(user -> UserResponseDTO.builder()
                        .id(user.getId())
                        .username(user.getUsername())
                        .fullName(user.getFullName())
                        .role(user.getRole())
                        .ekycStatus(user.getEkycStatus())
                        .departmentName(user.getDepartment() != null ? user.getDepartment().getName() : null)
                        .idCardUrl(user.getFaceData() != null ? user.getFaceData().getIdCardUrl() : null)
                        .selfieUrl(user.getFaceData() != null ? user.getFaceData().getSelfieUrl() : null)
                        .build())
                .collect(Collectors.toList());
    }

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

        // FIX: Lấy danh sách thay vì kỳ vọng 1 bản ghi để tránh crash (NonUniqueResultException)
        List<AttendanceLog> logs = attendanceLogRepository.findAllByUserIdAndCheckInTimeBetween(user.getId(), startOfDay, endOfDay);
        
        AttendanceLog log;
        if (logs.isEmpty()) {
            log = new AttendanceLog();
        } else {
            // Nếu có nhiều bản ghi, lấy bản ghi đầu tiên (Check-in) để sửa
            log = logs.get(0);
        }

        log.setUser(user);
        log.setCheckInTime(dto.getDate().atTime(dto.getNewCheckInTime()));
        log.setStatus("MANUAL_ADJUST"); 
        log.setLocation("Hệ thống Admin - Lý do: " + dto.getReason());
        log.setVerifiedByFace(false); 

        AttendanceLog savedLog = attendanceLogRepository.save(log);

        return AttendanceResponseDTO.builder()
                .id(savedLog.getId())
                .fullName(user.getFullName())
                .employeeCode(user.getEmployeeCode())
                .checkInTime(savedLog.getCheckInTime())
                .status(savedLog.getStatus())
                .build();
    }

    @Override
    @Transactional
    public void assignShiftToUser(Long userId, Long shiftId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy nhân sự với ID: " + userId));

        ShiftConfig shift = shiftConfigRepository.findById(shiftId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy ca làm việc với ID: " + shiftId));

        user.setAssignedShift(shift);
        userRepository.save(user);
    }

    @Override
    public List<com.smartops.core.dto.ShiftMonitoringDTO> getDailyShiftMonitoring(LocalDate date) {
        return userRepository.findAllByAssignedShiftIsNotNull().stream()
                .map(user -> com.smartops.core.dto.ShiftMonitoringDTO.builder()
                        .userId(user.getId())
                        .fullName(user.getFullName())
                        .employeeCode(user.getEmployeeCode())
                        .departmentName(user.getDepartment() != null ? user.getDepartment().getName() : "N/A")
                        .shiftId(user.getAssignedShift().getId())
                        .shiftName(user.getAssignedShift().getShiftName())
                        .startTime(user.getAssignedShift().getStartTime().toString())
                        .endTime(user.getAssignedShift().getEndTime().toString())
                        .workDate(date.toString())
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    public List<com.smartops.core.dto.ShiftMonitoringDTO> getWeeklyShiftMonitoring(LocalDate startDate) {
        List<com.smartops.core.dto.ShiftMonitoringDTO> weeklyMonitoring = new java.util.ArrayList<>();
        List<User> usersWithShifts = userRepository.findAllByAssignedShiftIsNotNull();

        for (int i = 0; i < 7; i++) {
            LocalDate currentDate = startDate.plusDays(i);
            for (User user : usersWithShifts) {
                weeklyMonitoring.add(com.smartops.core.dto.ShiftMonitoringDTO.builder()
                        .userId(user.getId())
                        .fullName(user.getFullName())
                        .employeeCode(user.getEmployeeCode())
                        .departmentName(user.getDepartment() != null ? user.getDepartment().getName() : "N/A")
                        .shiftId(user.getAssignedShift().getId())
                        .shiftName(user.getAssignedShift().getShiftName())
                        .startTime(user.getAssignedShift().getStartTime().toString())
                        .endTime(user.getAssignedShift().getEndTime().toString())
                        .workDate(currentDate.toString())
                        .build());
            }
        }
        return weeklyMonitoring;
    }
}
