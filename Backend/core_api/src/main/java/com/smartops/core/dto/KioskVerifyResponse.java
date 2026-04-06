package com.smartops.core.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class KioskVerifyResponse {
    private String employeeName;
    private String time;
    private String attendanceStatus; // ON_TIME, LATE
    private double similarityScore;
}
