package com.smartops.core.controller;

import com.smartops.core.dto.ApiResponse;
import com.smartops.core.dto.AuthResponse;
import com.smartops.core.dto.LoginRequest;
import com.smartops.core.dto.QrResponse;
import com.smartops.core.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import com.smartops.core.security.SecurityUtils;
import com.smartops.core.service.EkycService;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final EkycService ekycService;

    @PostMapping("/ekyc")
    public ResponseEntity<ApiResponse<String>> registerEkyc(
            @RequestParam("id_card") MultipartFile idCardImage,
            @RequestParam("selfie") MultipartFile selfieImage) {
        
        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("Người dùng chưa đăng nhập"));
        }

        try {
            ekycService.registerEkyc(userId, idCardImage, selfieImage);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success(null, "Đã gửi hồ sơ eKYC. Vui lòng chờ Admin phê duyệt."));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@RequestBody LoginRequest request) {
        try {
            AuthResponse response = authService.login(request);
            return ResponseEntity.ok(ApiResponse.success(response, "Đăng nhập thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/qr-code")
    public ResponseEntity<ApiResponse<QrResponse>> getQrCode(Authentication authentication) {
        // Giả sử userId được lưu trong principal của Authentication sau khi qua JWT filter
        // Ở đây tạm thời lấy ID từ authentication.getName() (Subject của JWT)
        try {
            Long userId = Long.parseLong(authentication.getName());
            QrResponse response = authService.generateQrCode(userId);
            return ResponseEntity.ok(ApiResponse.success(response, "Sinh mã QR thành công"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("Không thể sinh mã QR: " + e.getMessage()));
        }
    }
}
