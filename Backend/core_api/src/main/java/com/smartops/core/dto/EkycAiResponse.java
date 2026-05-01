package com.smartops.core.dto;

import lombok.Data;
import java.util.Map;

@Data
public class EkycAiResponse {
    private double similarity;
    private boolean isMatch;
    private Map<String, Object> ocrData;
    private double[] vector;
    private String message;
}
