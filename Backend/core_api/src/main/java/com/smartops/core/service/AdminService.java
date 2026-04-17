package com.smartops.core.service;

import com.smartops.core.dto.AttendanceAdjustDTO;
import com.smartops.core.dto.AttendanceResponseDTO;
import com.smartops.core.dto.LeaveResponseDTO;
import com.smartops.core.dto.LeaveReviewDTO;

import com.smartops.core.dto.EkycReviewDTO;

import java.time.LocalDate;
import java.util.List;
import com.smartops.core.dto.UserResponseDTO;

public interface AdminService {
    LeaveResponseDTO reviewLeave(Long leaveId, LeaveReviewDTO dto);
    AttendanceResponseDTO adjustAttendance(AttendanceAdjustDTO dto);
    void reviewEkyc(Long userId, EkycReviewDTO dto);
    List<UserResponseDTO> getPendingEkycRequests();
    List<LeaveResponseDTO> getAllLeaveRequests();
    List<AttendanceResponseDTO> getAttendanceReports(LocalDate startDate, LocalDate endDate);
    void assignShiftToUser(Long userId, Long shiftId);
    List<com.smartops.core.dto.ShiftMonitoringDTO> getDailyShiftMonitoring(LocalDate date);
    List<com.smartops.core.dto.ShiftMonitoringDTO> getWeeklyShiftMonitoring(LocalDate startDate);
}
