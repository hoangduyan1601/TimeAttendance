package com.smartops.core.controller;

import com.smartops.core.dto.ApiResponse;
import com.smartops.core.dto.AttendanceHistoryDTO;
import com.smartops.core.dto.LeaveRequestDTO;
import com.smartops.core.dto.LeaveResponseDTO;
import com.smartops.core.dto.ShiftChangeDTO;
import com.smartops.core.dto.UserResponseDTO;
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
    public ResponseEntity<ApiResponse<List<AttendanceHistoryDTO>>> getMyAttendance(
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate) {
        try {
            List<AttendanceHistoryDTO> history = employeeService.getMyAttendanceHistory(startDate, endDate);
            return ResponseEntity.ok(ApiResponse.success(history, "Lấy lịch sử chấm công thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @PostMapping("/leave")
    public ResponseEntity<ApiResponse<LeaveResponseDTO>> submitLeave(@RequestBody LeaveRequestDTO request) {
        try {
            LeaveResponseDTO response = employeeService.submitLeaveRequest(request);
            return ResponseEntity.ok(ApiResponse.success(response, "Gửi đơn từ thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/leave")
    public ResponseEntity<ApiResponse<List<LeaveResponseDTO>>> getMyLeaves() {
        return ResponseEntity.ok(ApiResponse.success(employeeService.getMyLeaveRequests(), "Lấy danh sách đơn từ thành công"));
    }

    @PostMapping("/shift-change")
    public ResponseEntity<ApiResponse<ShiftChangeDTO>> submitShiftChange(@RequestBody ShiftChangeDTO request) {
        try {
            ShiftChangeDTO response = employeeService.submitShiftChangeRequest(request);
            return ResponseEntity.ok(ApiResponse.success(response, "Gửi yêu cầu đổi ca thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/shift-change")
    public ResponseEntity<ApiResponse<List<ShiftChangeDTO>>> getMyShiftChanges() {
        return ResponseEntity.ok(ApiResponse.success(employeeService.getMyShiftChangeRequests(), "Lấy danh sách yêu cầu đổi ca thành công"));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserResponseDTO>> getMyProfile() {
        try {
            return ResponseEntity.ok(ApiResponse.success(employeeService.getMyProfile(), "Lấy thông tin cá nhân thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
}
