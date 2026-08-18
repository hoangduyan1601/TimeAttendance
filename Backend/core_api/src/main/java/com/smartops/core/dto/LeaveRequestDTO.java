package com.smartops.core.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class LeaveRequestDTO {
    @NotNull
    private LocalDate fromDate;
    @NotNull
    private LocalDate toDate;
    @NotBlank
    @Size(max = 30)
    private String leaveType;
    @NotBlank
    @Size(max = 1000)
    private String reason;
}
