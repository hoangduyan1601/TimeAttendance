package com.smartops.core.controller;

import com.smartops.core.dto.ApiResponse;
import com.smartops.core.entity.Department;
import com.smartops.core.service.DepartmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/departments")
@RequiredArgsConstructor
public class DepartmentController {

    private final DepartmentService departmentService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Department>>> getAll() {
        return ResponseEntity.ok(ApiResponse.success(departmentService.getAllDepartments(), "Lấy danh sách thành công"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Department>> create(@RequestBody Department department) {
        return ResponseEntity.ok(ApiResponse.success(departmentService.createDepartment(department), "Tạo phòng ban mới thành công"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Department>> getById(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(departmentService.getDepartmentById(id), "Lấy thông tin thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Department>> update(@PathVariable Long id, @RequestBody Department department) {
        department.setId(id);
        return ResponseEntity.ok(ApiResponse.success(departmentService.updateDepartment(department), "Cập nhật phòng ban thành công"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> delete(@PathVariable Long id) {
        departmentService.deleteDepartment(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Xóa phòng ban thành công"));
    }
}
