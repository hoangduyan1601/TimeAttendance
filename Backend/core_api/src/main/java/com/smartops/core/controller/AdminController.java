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
}
