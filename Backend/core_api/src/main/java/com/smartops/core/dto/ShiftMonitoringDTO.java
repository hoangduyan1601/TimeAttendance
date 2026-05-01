package com.smartops.core.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ShiftMonitoringDTO {
    private Long userId;
    private String fullName;
    private String employeeCode;
    private String departmentName;
    private Long shiftId;
    private String shiftName;
    private String startTime;
    private String endTime;
    private String workDate; // Dùng cho theo dõi theo ngày/tuần
}
