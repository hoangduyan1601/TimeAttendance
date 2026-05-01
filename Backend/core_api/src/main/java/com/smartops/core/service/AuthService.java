package com.smartops.core.service;

import com.smartops.core.dto.AuthResponse;
import com.smartops.core.dto.LoginRequest;
import com.smartops.core.dto.QrResponse;

public interface AuthService {
    AuthResponse login(LoginRequest request);
    QrResponse generateQrCode(Long userId);
}
