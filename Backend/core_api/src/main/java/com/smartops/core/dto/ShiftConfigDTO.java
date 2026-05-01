package com.smartops.core.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ShiftConfigDTO {
    private Long id;
    private String shiftName;
    private String startTime; // "HH:mm"
    private String endTime;   // "HH:mm"
    private int gracePeriod;  // số phút châm chước
    private Boolean isActive;
}
