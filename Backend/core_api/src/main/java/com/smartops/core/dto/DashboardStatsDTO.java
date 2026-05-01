package com.smartops.core.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class DashboardStatsDTO {
    private long totalEmployees;
    private long presentToday;
    private long lateToday;
    private long onLeaveToday;
    private long absentToday;
    private long pendingLeaveRequests;
}
