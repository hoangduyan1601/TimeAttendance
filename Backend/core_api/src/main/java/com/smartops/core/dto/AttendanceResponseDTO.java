package com.smartops.core.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class AttendanceResponseDTO {
    private Long id;
    private String fullName;
    private String employeeCode;
    private String shiftName;
    private LocalDateTime checkInTime;
    private String status; // ON_TIME, LATE
    private long minutesLate; // Số phút đi muộn (nếu có)
}
