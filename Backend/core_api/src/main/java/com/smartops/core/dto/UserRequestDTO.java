package com.smartops.core.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class UserRequestDTO {
    @NotBlank
    @Size(min = 3, max = 100)
    private String username;
    @NotBlank
    @Size(min = 8, max = 128)
    private String password;
    @Email
    @Size(max = 255)
    private String email; // Thêm trường này
    @NotBlank
    @Size(max = 150)
    private String fullName;
    @Pattern(regexp = "^$|^[0-9+() .-]{8,20}$", message = "Phone number is invalid")
    private String phoneNumber;
    @Pattern(regexp = "ADMIN|EMPLOYEE", message = "Role must be ADMIN or EMPLOYEE")
    private String role;
    private Long departmentId;
    private Long assignedShiftId;
}
