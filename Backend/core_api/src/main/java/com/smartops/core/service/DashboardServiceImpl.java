package com.smartops.core.service;

import com.smartops.core.dto.DashboardStatsDTO;
import com.smartops.core.repository.AttendanceLogRepository;
import com.smartops.core.repository.LeaveRequestRepository;
import com.smartops.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Service
@RequiredArgsConstructor
public class DashboardServiceImpl implements DashboardService {

    private final UserRepository userRepository;
    private final AttendanceLogRepository attendanceLogRepository;
    private final LeaveRequestRepository leaveRequestRepository;

    @Override
    public DashboardStatsDTO getStats() {
        LocalDate today = LocalDate.now();
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.atTime(LocalTime.MAX);

        long totalEmployees = userRepository.countByStatus("ACTIVE");
        long presentToday = attendanceLogRepository.countPresentUsers(startOfDay, endOfDay);
        long lateToday = attendanceLogRepository.countLateUsers(startOfDay, endOfDay);
        long onLeaveToday = leaveRequestRepository.countUsersOnLeave(today);
        long pendingLeaveRequests = leaveRequestRepository.countByStatus("PENDING");

        // Vắng mặt = Tổng - (Có mặt + Đang nghỉ phép)
        // Lưu ý: Có thể một người vừa nghỉ phép vừa đi làm (tùy logic doanh nghiệp), 
        // nhưng ở đây giả định là 2 tập hợp rời nhau.
        long absentToday = totalEmployees - presentToday - onLeaveToday;
        if (absentToday < 0) absentToday = 0;

        return DashboardStatsDTO.builder()
                .totalEmployees(totalEmployees)
                .presentToday(presentToday)
                .lateToday(lateToday)
                .onLeaveToday(onLeaveToday)
                .absentToday(absentToday)
                .pendingLeaveRequests(pendingLeaveRequests)
                .build();
    }
}
