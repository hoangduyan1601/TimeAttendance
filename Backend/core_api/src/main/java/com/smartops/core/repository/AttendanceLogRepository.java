package com.smartops.core.repository;

import com.smartops.core.entity.AttendanceLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

/**
 * Repository cho AttendanceLog
 */
import java.time.LocalDateTime;
import java.util.Optional;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

@Repository
public interface AttendanceLogRepository extends JpaRepository<AttendanceLog, Long> {
    List<AttendanceLog> findByUserIdOrderByCheckInTimeDesc(Long userId);
    
    Optional<AttendanceLog> findByUserIdAndCheckInTimeBetween(Long userId, LocalDateTime start, LocalDateTime end);
    
    List<AttendanceLog> findAllByUserIdAndCheckInTimeBetween(Long userId, LocalDateTime start, LocalDateTime end);

    @Query("SELECT COUNT(DISTINCT a.user.id) FROM AttendanceLog a WHERE a.checkInTime BETWEEN :start AND :end")
    long countPresentUsers(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    @Query("SELECT COUNT(DISTINCT a.user.id) FROM AttendanceLog a WHERE a.status = 'LATE' AND a.checkInTime BETWEEN :start AND :end")
    long countLateUsers(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    List<AttendanceLog> findByCheckInTimeBetweenOrderByCheckInTimeAsc(LocalDateTime start, LocalDateTime end);

    List<AttendanceLog> findTop10ByOrderByCheckInTimeDesc();
}
