package com.smartops.core.service;

import com.smartops.core.dto.AttendanceHistoryDTO;
import com.smartops.core.dto.LeaveRequestDTO;
import com.smartops.core.dto.LeaveResponseDTO;
import java.util.List;

public interface EmployeeService {
    List<AttendanceHistoryDTO> getMyAttendanceHistory();
    LeaveResponseDTO submitLeaveRequest(LeaveRequestDTO dto);
}
