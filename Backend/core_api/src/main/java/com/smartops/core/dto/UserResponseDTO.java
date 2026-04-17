package com.smartops.core.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class UserResponseDTO {
    private Long id;
    private String username;
    private String email;
    private String fullName;
    private String employeeCode;
    private String phoneNumber;
    private String role;
    private String ekycStatus;
    private String departmentName;
    private Long departmentId;
    private Long assignedShiftId;
    private String assignedShiftName;
    private String idCardUrl;
    private String selfieUrl;
}
