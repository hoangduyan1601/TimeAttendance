package com.smartops.core.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class KioskVerifyRequest {
    @NotBlank
    @Size(max = 100)
    private String kioskId;
    @NotBlank
    private String qrToken;
    private String liveImageBase64; // Ảnh chụp từ camera Kiosk
    private List<String> framesBase64; // Chuỗi frame để challenge–response
    private String challengeType; // TURN_LEFT, TURN_RIGHT, BLINK
}
