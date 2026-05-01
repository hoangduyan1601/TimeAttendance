package com.smartops.core.service;

import com.smartops.core.dto.AuthResponse;
import com.smartops.core.dto.LoginRequest;
import com.smartops.core.dto.QrResponse;
import com.smartops.core.entity.User;
import com.smartops.core.repository.UserRepository;
import com.smartops.core.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import java.util.Base64;
import java.nio.charset.StandardCharsets;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;

    @Override
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new RuntimeException("Sai thông tin đăng nhập"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("Sai thông tin đăng nhập");
        }

        String token = tokenProvider.generateToken(user.getId().toString(), user.getRole());

        return AuthResponse.builder()
                .accessToken(token)
                .expiresIn(tokenProvider.getExpirationInMs())
                .user(AuthResponse.UserSummary.builder()
                        .id(user.getId())
                        .fullName(user.getFullName())
                        .role(user.getRole())
                        .build())
                .build();
    }

    @Override
    public QrResponse generateQrCode(Long userId) {
        // Chuyển sang QR tĩnh: Chỉ chứa User ID, không có thời gian hết hạn
        String rawData = "SMARTOPS_USER_" + userId; 
        String qrToken = Base64.getEncoder().encodeToString(rawData.getBytes(StandardCharsets.UTF_8));

        return QrResponse.builder()
                .qrToken(qrToken)
                .expiresAt(0L) // 0 nghĩa là không bao giờ hết hạn
                .build();
    }
}
