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

    @Query("SELECT s FROM ShiftConfig s WHERE :time >= s.startTime AND :time <= s.endTime AND s.isActive = true")
    List<ShiftConfig> findShiftsAtTime(@Param("time") LocalTime time);

    List<ShiftConfig> findByIsActiveTrue();
}
