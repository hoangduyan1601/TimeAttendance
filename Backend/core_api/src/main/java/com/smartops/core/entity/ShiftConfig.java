package com.smartops.core.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalTime;

/**
 * Entity cấu hình ca làm (ShiftConfig)
 */
@Entity
@Table(name = "shift_configs")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ShiftConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "shift_name", nullable = false, unique = true)
    private String shiftName; // VD: Sáng, Chiều, Hành chính

    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    @Column(name = "break_start_time")
    private LocalTime breakStartTime;

    @Column(name = "break_end_time")
    private LocalTime breakEndTime;

    // Ngưỡng cho phép đi muộn (phút)
    @Column(name = "late_threshold_minutes")
    private Integer lateThresholdMinutes;

    @Column(name = "location")
    private String location; // VD: Tầng 5 - Văn phòng chính

    @Column(name = "notes")
    private String notes; // VD: Chấm công đúng giờ

    @Column(name = "is_active")
    private Boolean isActive;
}
