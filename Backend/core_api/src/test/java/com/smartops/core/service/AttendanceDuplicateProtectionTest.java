package com.smartops.core.service;

import com.smartops.core.dto.AttendanceRequestDTO;
import com.smartops.core.dto.ShiftConfigDTO;
import com.smartops.core.entity.AttendanceLog;
import com.smartops.core.entity.ShiftConfig;
import com.smartops.core.entity.User;
import com.smartops.core.exception.BusinessConflictException;
import com.smartops.core.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AttendanceDuplicateProtectionTest {
    @Mock AttendanceLogRepository attendanceLogRepository;
    @Mock UserRepository userRepository;
    @Mock ShiftConfigRepository shiftConfigRepository;
    @Mock ShiftConfigService shiftConfigService;
    @Mock FaceDataRepository faceDataRepository;
    @Mock OvertimeRequestRepository overtimeRequestRepository;
    @Mock WebClient webClient;

    private AttendanceServiceImpl service;
    private User user;
    private ShiftConfig shift;

    @BeforeEach
    void setUp() {
        service = new AttendanceServiceImpl(attendanceLogRepository, userRepository,
                shiftConfigRepository, shiftConfigService, faceDataRepository,
                overtimeRequestRepository, webClient);
        user = User.builder().id(7L).employeeCode("EMP-7").fullName("Test User").build();
        shift = ShiftConfig.builder().id(3L).shiftName("Day")
                .startTime(LocalTime.MIN).endTime(LocalTime.MAX).lateThresholdMinutes(0).build();
    }

    @Test
    void firstCheckInCreatesOneRecordWhileHoldingUserLock() {
        when(userRepository.findByIdForUpdate(7L)).thenReturn(Optional.of(user));
        when(attendanceLogRepository.findAllByUserIdAndCheckInTimeBetweenOrderByCheckInTimeAsc(any(), any(), any()))
                .thenReturn(List.of());
        when(shiftConfigService.getActiveShift(any())).thenReturn(ShiftConfigDTO.builder().id(3L).build());
        when(shiftConfigRepository.findById(3L)).thenReturn(Optional.of(shift));
        when(attendanceLogRepository.save(any())).thenAnswer(invocation -> {
            AttendanceLog log = invocation.getArgument(0);
            log.setId(99L);
            return log;
        });

        service.checkIn(new AttendanceRequestDTO(7L, "KIOSK-1"));

        verify(userRepository).findByIdForUpdate(7L);
        verify(attendanceLogRepository, times(1)).save(any(AttendanceLog.class));
    }

    @Test
    void duplicateCheckInIsRejectedWithoutInsert() {
        when(userRepository.findByIdForUpdate(7L)).thenReturn(Optional.of(user));
        when(attendanceLogRepository.findAllByUserIdAndCheckInTimeBetweenOrderByCheckInTimeAsc(any(), any(), any()))
                .thenReturn(List.of(AttendanceLog.builder().id(1L).user(user).build()));

        assertThrows(BusinessConflictException.class,
                () -> service.checkIn(new AttendanceRequestDTO(7L, "KIOSK-1")));
        verify(attendanceLogRepository, never()).save(any());
    }
}
