package com.smartops.core.controller;

import com.smartops.core.dto.ApiResponse;
import com.smartops.core.dto.ShiftConfigDTO;
import com.smartops.core.service.ShiftConfigService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/shifts")
@RequiredArgsConstructor
public class ShiftController {

    private final ShiftConfigService shiftConfigService;

    @PostMapping
    public ResponseEntity<ApiResponse<ShiftConfigDTO>> createShift(@RequestBody ShiftConfigDTO request) {
        try {
            ShiftConfigDTO response = shiftConfigService.createShift(request);
            return ResponseEntity.ok(ApiResponse.success(response, "Tạo ca làm việc thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<ShiftConfigDTO>>> getAllShifts() {
        List<ShiftConfigDTO> shifts = shiftConfigService.getAllShifts();
        return ResponseEntity.ok(ApiResponse.success(shifts, "Lấy danh sách ca làm việc thành công"));
    }
}
