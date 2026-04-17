package com.smartops.core.controller;

import com.smartops.core.dto.ApiResponse;
import com.smartops.core.dto.AttendanceAdjustDTO;
import com.smartops.core.dto.AttendanceResponseDTO;
import com.smartops.core.dto.LeaveResponseDTO;
import com.smartops.core.dto.LeaveReviewDTO;
import com.smartops.core.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.smartops.core.service.ReportService;
import com.smartops.core.service.DashboardService;
import com.smartops.core.dto.DashboardStatsDTO;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import java.time.LocalDate;
import java.io.ByteArrayInputStream;

import com.smartops.core.dto.EkycReviewDTO;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final DashboardService dashboardService;
    private final ReportService reportService;

    @GetMapping("/ekyc/pending")
    public ResponseEntity<ApiResponse<java.util.List<com.smartops.core.dto.UserResponseDTO>>> getPendingEkyc() {
        return ResponseEntity.ok(ApiResponse.success(adminService.getPendingEkycRequests(), "Lấy danh sách yêu cầu eKYC thành công"));
    }

    @GetMapping("/leaves")
    public ResponseEntity<ApiResponse<java.util.List<com.smartops.core.dto.LeaveResponseDTO>>> getAllLeaves() {
        return ResponseEntity.ok(ApiResponse.success(adminService.getAllLeaveRequests(), "Lấy danh sách đơn từ thành công"));
    }

    @GetMapping("/attendance")
    public ResponseEntity<ApiResponse<java.util.List<com.smartops.core.dto.AttendanceResponseDTO>>> getAttendanceReports(
            @RequestParam("startDate") String startDate,
            @RequestParam("endDate") String endDate) {
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        return ResponseEntity.ok(ApiResponse.success(adminService.getAttendanceReports(start, end), "Lấy báo cáo chấm công thành công"));
    }

    @PutMapping("/ekyc/{userId}/review")
    public ResponseEntity<ApiResponse<String>> reviewEkyc(
            @PathVariable Long userId,
            @RequestBody EkycReviewDTO dto) {
        try {
            adminService.reviewEkyc(userId, dto);
            return ResponseEntity.ok(ApiResponse.success(null, "Cập nhật trạng thái eKYC thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/reports/export")
    public ResponseEntity<InputStreamResource> exportReport(
            @RequestParam("startDate") String startDate,
            @RequestParam("endDate") String endDate) {

        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        
        ByteArrayInputStream in = reportService.exportAttendanceToExcel(start, end);
        
        HttpHeaders headers = new HttpHeaders();
        headers.add("Content-Disposition", "attachment; filename=attendance_report_" + startDate + "_to_" + endDate + ".xlsx");

        return ResponseEntity
                .ok()
                .headers(headers)
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(new InputStreamResource(in));
    }

    @GetMapping("/dashboard/stats")
    public ResponseEntity<ApiResponse<DashboardStatsDTO>> getStats() {
        return ResponseEntity.ok(ApiResponse.success(dashboardService.getStats(), "Lấy thống kê thành công"));
    }

    @PutMapping("/leaves/{id}/review")
    public ResponseEntity<ApiResponse<LeaveResponseDTO>> reviewLeave(
            @PathVariable Long id,
            @RequestBody LeaveReviewDTO dto) {
        try {
            LeaveResponseDTO response = adminService.reviewLeave(id, dto);
            return ResponseEntity.ok(ApiResponse.success(response, "Cập nhật trạng thái đơn từ thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @PostMapping("/attendance/adjust")
    public ResponseEntity<ApiResponse<AttendanceResponseDTO>> adjustAttendance(
            @RequestBody AttendanceAdjustDTO dto) {
        try {
            AttendanceResponseDTO response = adminService.adjustAttendance(dto);
            return ResponseEntity.ok(ApiResponse.success(response, "Hiệu chỉnh chấm công thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @PutMapping("/users/{userId}/assign-shift")
    public ResponseEntity<ApiResponse<Void>> assignShift(
            @PathVariable Long userId,
            @RequestParam Long shiftId) {
        try {
            adminService.assignShiftToUser(userId, shiftId);
            return ResponseEntity.ok(ApiResponse.success(null, "Phân công ca làm việc thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/shifts/monitoring/daily")
    public ResponseEntity<ApiResponse<java.util.List<com.smartops.core.dto.ShiftMonitoringDTO>>> getDailyShiftMonitoring(
            @RequestParam("date") String date) {
        LocalDate localDate = LocalDate.parse(date);
        return ResponseEntity.ok(ApiResponse.success(adminService.getDailyShiftMonitoring(localDate), "Lấy bảng phân ca theo ngày thành công"));
    }

    @GetMapping("/shifts/monitoring/weekly")
    public ResponseEntity<ApiResponse<java.util.List<com.smartops.core.dto.ShiftMonitoringDTO>>> getWeeklyShiftMonitoring(
            @RequestParam("startDate") String startDate) {
        LocalDate start = LocalDate.parse(startDate);
        return ResponseEntity.ok(ApiResponse.success(adminService.getWeeklyShiftMonitoring(start), "Lấy bảng phân ca theo tuần thành công"));
    }
}
