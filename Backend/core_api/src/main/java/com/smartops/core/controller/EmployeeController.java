package com.smartops.core.controller;

import com.smartops.core.dto.ApiResponse;
import com.smartops.core.dto.AttendanceHistoryDTO;
import com.smartops.core.dto.LeaveRequestDTO;
import com.smartops.core.dto.LeaveResponseDTO;
import com.smartops.core.service.EmployeeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/employee")
@RequiredArgsConstructor
public class EmployeeController {

    private final EmployeeService employeeService;

    @GetMapping("/attendance")
    public ResponseEntity<ApiResponse<List<AttendanceHistoryDTO>>> getMyAttendance() {
        try {
            List<AttendanceHistoryDTO> history = employeeService.getMyAttendanceHistory();
            return ResponseEntity.ok(ApiResponse.success(history, "Lấy lịch sử chấm công thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @PostMapping("/leaves")
    public ResponseEntity<ApiResponse<LeaveResponseDTO>> submitLeave(@RequestBody LeaveRequestDTO request) {
        try {
            LeaveResponseDTO response = employeeService.submitLeaveRequest(request);
            return ResponseEntity.ok(ApiResponse.success(response, "Gửi đơn từ thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
}
