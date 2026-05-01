package com.smartops.core.repository;

import com.smartops.core.entity.ShiftConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repository cho ShiftConfig
 */
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface ShiftConfigRepository extends JpaRepository<ShiftConfig, Long> {

    // Tìm ca làm việc mà thời điểm hiện tại nằm trong khoảng (StartTime - 1h) đến (EndTime + 2h)
    @Query(value = "SELECT * FROM shift_configs s WHERE s.is_active = true AND " +
                   "(CAST(:time AS time) >= (s.start_time - interval '1 hour')) AND " +
                   "(CAST(:time AS time) <= (s.end_time + interval '2 hours'))", nativeQuery = true)
    List<ShiftConfig> findShiftsAtTime(@Param("time") LocalTime time);

    List<ShiftConfig> findByIsActiveTrue();
}
