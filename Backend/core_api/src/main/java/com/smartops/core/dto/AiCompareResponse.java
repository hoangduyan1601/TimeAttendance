package com.smartops.core.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class AiCompareResponse {
    private double similarity; // Tỉ lệ trùng khớp (0.0 - 1.0)
    
    @JsonProperty("isMatch")
    private boolean isMatch;   // AI đánh giá là trùng khớp hay không
    
    private String message;
}
