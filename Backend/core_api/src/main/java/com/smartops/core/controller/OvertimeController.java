package com.smartops.core.controller;

import com.smartops.core.dto.ApiResponse;
import com.smartops.core.dto.OvertimeRequestDTO;
import com.smartops.core.service.AdminService;
import com.smartops.core.service.EmployeeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class OvertimeController {

    private final AdminService adminService;
    private final EmployeeService employeeService;

    // --- Employee APIs ---
    
    @PostMapping("/employee/overtime")
    public ResponseEntity<ApiResponse<OvertimeRequestDTO>> submitOvertime(@RequestBody OvertimeRequestDTO dto) {
        OvertimeRequestDTO saved = employeeService.submitOvertimeRequest(dto);
        return ResponseEntity.ok(ApiResponse.success(saved, "Gửi yêu cầu OT thành công"));
    }

    @GetMapping("/employee/overtime")
    public ResponseEntity<ApiResponse<List<OvertimeRequestDTO>>> getMyOvertimeRequests() {
        List<OvertimeRequestDTO> list = employeeService.getMyOvertimeRequests();
        return ResponseEntity.ok(ApiResponse.success(list, "Lấy danh sách OT thành công"));
    }

    // --- Admin APIs ---

    @GetMapping("/admin/overtime")
    public ResponseEntity<ApiResponse<List<OvertimeRequestDTO>>> getAllOvertimeRequests() {
        List<OvertimeRequestDTO> list = adminService.getAllOvertimeRequests();
        return ResponseEntity.ok(ApiResponse.success(list, "Lấy danh sách OT thành công"));
    }

    @PutMapping("/admin/overtime/{otId}/review")
    public ResponseEntity<ApiResponse<OvertimeRequestDTO>> reviewOvertime(
            @PathVariable Long otId,
            @RequestParam String status) {
        OvertimeRequestDTO updated = adminService.reviewOvertime(otId, status);
        return ResponseEntity.ok(ApiResponse.success(updated, "Duyệt yêu cầu OT thành công"));
    }
}
