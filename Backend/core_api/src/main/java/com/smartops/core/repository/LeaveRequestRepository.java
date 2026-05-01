package com.smartops.core.repository;

import com.smartops.core.entity.LeaveRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

/**
 * Repository cho LeaveRequest
 */
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;

@Repository
public interface LeaveRequestRepository extends JpaRepository<LeaveRequest, Long> {
    List<LeaveRequest> findByUserIdOrderByCreatedAtDesc(Long userId);

    @Query("SELECT COUNT(DISTINCT l.user.id) FROM LeaveRequest l WHERE l.status = 'APPROVED' " +
           "AND :today BETWEEN l.startDate AND l.endDate")
    long countUsersOnLeave(@Param("today") LocalDate today);

    long countByStatus(String status);
}
