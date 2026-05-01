package com.smartops.core.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.time.LocalTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class AttendanceAdjustDTO {
    private String employeeCode; // Dùng mã nhân viên (NV...) để admin dễ nhập
    private LocalDate date;
    private LocalTime newCheckInTime;
    private String reason;
}
