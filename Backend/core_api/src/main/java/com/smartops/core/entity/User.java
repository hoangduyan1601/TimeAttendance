package com.smartops.core.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Entity đại diện cho Nhân sự (User)
 */
@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(name = "username", nullable = false, unique = true)
    private String username;

    @Column(name = "employee_code", nullable = false, unique = true)
    private String employeeCode;

    @Column(unique = true)
    private String email;

    @Column(name = "phone_number")
    private String phoneNumber;

    @Column(nullable = false)
    private String password;

    @Column(name = "role")
    private String role; // VD: ADMIN, EMPLOYEE, MANAGER

    @Column(name = "status")
    private String status; // VD: ACTIVE, INACTIVE

    @Column(name = "ekyc_status")
    private String ekycStatus; // VD: PENDING, APPROVED, REJECTED

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Nhiều nhân sự thuộc một phòng ban
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id")
    private Department department;

    // Một nhân sự có một dữ liệu khuôn mặt (quan hệ 1-1)
    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL)
    private FaceData faceData;

    // Một nhân sự có nhiều bản ghi chấm công
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<AttendanceLog> attendanceLogs;

    // Một nhân sự có nhiều đơn xin nghỉ
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<LeaveRequest> leaveRequests;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
