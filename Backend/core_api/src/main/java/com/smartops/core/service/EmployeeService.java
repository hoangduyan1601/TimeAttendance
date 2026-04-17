package com.smartops.core.service;

import com.smartops.core.dto.AttendanceHistoryDTO;
import com.smartops.core.dto.LeaveRequestDTO;
import com.smartops.core.dto.LeaveResponseDTO;
import com.smartops.core.dto.ShiftChangeDTO;
import com.smartops.core.dto.UserResponseDTO;
import java.util.List;

public interface EmployeeService {
    List<AttendanceHistoryDTO> getMyAttendanceHistory(String startDate, String endDate);
    LeaveResponseDTO submitLeaveRequest(LeaveRequestDTO request);
    ShiftChangeDTO submitShiftChangeRequest(ShiftChangeDTO request);
    List<ShiftChangeDTO> getMyShiftChangeRequests();
    List<LeaveResponseDTO> getMyLeaveRequests();
    UserResponseDTO getMyProfile();
}
