package com.smartops.core.controller;

import com.smartops.core.dto.ApiResponse;
import com.smartops.core.dto.AttendanceHistoryDTO;
import com.smartops.core.dto.LeaveRequestDTO;
import com.smartops.core.dto.LeaveResponseDTO;
import com.smartops.core.dto.ShiftChangeDTO;
import com.smartops.core.dto.UserResponseDTO;
import com.smartops.core.service.EmployeeService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import java.util.List;

import com.smartops.core.service.EkycService;
import com.smartops.core.security.SecurityUtils;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.HttpStatus;

import org.springframework.http.MediaType;

@RestController
@RequestMapping("/api/v1/employee")
@RequiredArgsConstructor
@Slf4j
public class EmployeeController {

    private final EmployeeService employeeService;
    private final EkycService ekycService;

    @PostMapping(value = "/ekyc", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<String>> registerEkyc(
            @RequestPart(value = "idCard", required = false) MultipartFile idCardImage,
            @RequestPart("selfie") MultipartFile selfieImage) {
        
        log.info(">>> Nhận yêu cầu đăng ký eKYC. File: {}, Size: {} bytes", 
                selfieImage.getOriginalFilename(), selfieImage.getSize());

        if (selfieImage.isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("File ảnh không được để trống"));
        }

        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("Người dùng chưa đăng nhập"));
        }

        try {
            ekycService.registerEkyc(userId, idCardImage, selfieImage);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success(null, "Đăng ký khuôn mặt thành công."));
        } catch (Exception e) {
            log.error(">>> Lỗi đăng ký eKYC: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("Lỗi: " + e.getMessage()));
        }
    }

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
    public ResponseEntity<ApiResponse<LeaveResponseDTO>> submitLeave(@Valid @RequestBody LeaveRequestDTO request) {
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
