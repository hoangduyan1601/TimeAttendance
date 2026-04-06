package com.smartops.core.controller;

import com.smartops.core.dto.*;
import com.smartops.core.service.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/kiosk")
@RequiredArgsConstructor
public class KioskController {

    private final AttendanceService attendanceService;

    @PostMapping("/verify")
    public ResponseEntity<ApiResponse<KioskVerifyResponse>> verify(@RequestBody KioskVerifyRequest request) {
        try {
            KioskVerifyResponse response = attendanceService.verify(request);
            return ResponseEntity.ok(ApiResponse.success(response, "Xác thực chấm công thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/live-logs")
    public ResponseEntity<ApiResponse<List<AttendanceResponseDTO>>> getLiveLogs() {
        return ResponseEntity.ok(ApiResponse.success(attendanceService.getLiveLogs(), "Lấy nhật ký trực tiếp thành công"));
    }

    @PostMapping("/check-in")
    public ResponseEntity<ApiResponse<AttendanceResponseDTO>> checkIn(@RequestBody AttendanceRequestDTO request) {
        try {
            AttendanceResponseDTO response = attendanceService.checkIn(request);
            return ResponseEntity.ok(ApiResponse.success(response, "Chấm công thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
}
