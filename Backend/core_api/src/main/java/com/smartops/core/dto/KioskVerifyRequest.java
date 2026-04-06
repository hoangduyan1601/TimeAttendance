package com.smartops.core.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class KioskVerifyRequest {
    private String kioskId;
    private String qrToken;
    private String liveImageBase64; // Ảnh chụp từ camera Kiosk
}
