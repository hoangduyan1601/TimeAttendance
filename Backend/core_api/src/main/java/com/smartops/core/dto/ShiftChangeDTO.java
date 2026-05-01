package com.smartops.core.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShiftChangeDTO {
    private Long id;
    private Long userId;
    private String fullName;
    private Long oldShiftId;
    private String oldShiftName;
    private Long newShiftId;
    private String newShiftName;
    private String reason;
    private String status;
    private LocalDateTime createdAt;
}
