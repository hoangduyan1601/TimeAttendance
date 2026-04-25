package com.smartops.core.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.time.LocalTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OvertimeRequestDTO {
    private Long id;
    private Long userId;
    private String fullName;
    private LocalDate date;
    private LocalTime startTime;
    private LocalTime endTime;
    private String reason;
    private String status;
}
