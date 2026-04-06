package com.smartops.core.service;

import com.smartops.core.dto.AttendanceAdjustDTO;
import com.smartops.core.dto.AttendanceResponseDTO;
import com.smartops.core.dto.LeaveResponseDTO;
import com.smartops.core.dto.LeaveReviewDTO;

import com.smartops.core.dto.EkycReviewDTO;

public interface AdminService {
    LeaveResponseDTO reviewLeave(Long leaveId, LeaveReviewDTO dto);
    AttendanceResponseDTO adjustAttendance(AttendanceAdjustDTO dto);
    void reviewEkyc(Long userId, EkycReviewDTO dto);
}
