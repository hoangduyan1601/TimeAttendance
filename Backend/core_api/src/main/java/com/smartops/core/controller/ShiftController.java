package com.smartops.core.controller;

import com.smartops.core.dto.ApiResponse;
import com.smartops.core.dto.ShiftChangeDTO;
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
    public ResponseEntity<ApiResponse<ShiftConfigDTO>> create(@RequestBody ShiftConfigDTO request) {
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

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ShiftConfigDTO>> updateShift(@PathVariable Long id, @RequestBody ShiftConfigDTO request) {
        try {
            ShiftConfigDTO response = shiftConfigService.updateShift(id, request);
            return ResponseEntity.ok(ApiResponse.success(response, "Cập nhật ca làm việc thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteShift(@PathVariable Long id) {
        try {
            shiftConfigService.deleteShift(id);
            return ResponseEntity.ok(ApiResponse.success(null, "Xóa ca làm việc thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // Shift Change Requests
    @GetMapping("/change-requests")
    public ResponseEntity<ApiResponse<List<ShiftChangeDTO>>> getAllChangeRequests() {
        return ResponseEntity.ok(ApiResponse.success(shiftConfigService.getAllShiftChangeRequests(), "Lấy danh sách yêu cầu đổi ca thành công"));
    }

    @PostMapping("/change-requests/{id}/review")
    public ResponseEntity<ApiResponse<Void>> reviewChangeRequest(
            @PathVariable Long id,
            @RequestParam String status) {
        try {
            shiftConfigService.reviewShiftChangeRequest(id, status);
            return ResponseEntity.ok(ApiResponse.success(null, "Đã xử lý yêu cầu đổi ca"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
}
