package com.smartops.core.controller;

import com.smartops.core.dto.*;
import com.smartops.core.service.AttendanceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/kiosk")
@RequiredArgsConstructor
public class KioskController {
    private final AttendanceService attendanceService;

    @PostMapping("/verify")
    public ResponseEntity<ApiResponse<KioskVerifyResponse>> verify(@Valid @RequestBody KioskVerifyRequest request) {
        return ResponseEntity.ok(ApiResponse.success(attendanceService.verify(request), "Attendance recorded successfully"));
    }

    @PostMapping("/resolve-qr")
    public ResponseEntity<ApiResponse<AuthResponse.UserSummary>> resolveQr(@RequestBody Map<String, String> request) {
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.getUserByQrToken(request.get("qrToken")), "Employee resolved successfully"));
    }

    @GetMapping("/live-logs")
    public ResponseEntity<ApiResponse<List<AttendanceResponseDTO>>> getLiveLogs() {
        return ResponseEntity.ok(ApiResponse.success(attendanceService.getLiveLogs(), "Live attendance logs retrieved"));
    }

    @PostMapping("/check-in")
    public ResponseEntity<ApiResponse<AttendanceResponseDTO>> checkIn(@Valid @RequestBody AttendanceRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(attendanceService.checkIn(request), "Attendance recorded successfully"));
    }
}
