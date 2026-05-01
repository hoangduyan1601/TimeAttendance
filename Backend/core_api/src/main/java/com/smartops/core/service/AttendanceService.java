package com.smartops.core.service;

import com.smartops.core.dto.AttendanceRequestDTO;
import com.smartops.core.dto.AttendanceResponseDTO;
import com.smartops.core.dto.KioskVerifyRequest;
import com.smartops.core.dto.KioskVerifyResponse;
import com.smartops.core.dto.AuthResponse;
import java.util.List;

public interface AttendanceService {
    AttendanceResponseDTO checkIn(AttendanceRequestDTO request);
    KioskVerifyResponse verify(KioskVerifyRequest request);
    List<AttendanceResponseDTO> getLiveLogs();
    AuthResponse.UserSummary getUserByQrToken(String qrToken);
}
