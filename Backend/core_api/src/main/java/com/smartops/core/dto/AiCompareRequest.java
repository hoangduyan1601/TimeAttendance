package com.smartops.core.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class AiCompareRequest {
    private double[] storedVector;
    private String liveImageBase64;
}
