package com.smartops.core.repository;

import com.smartops.core.entity.ShiftChangeRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ShiftChangeRequestRepository extends JpaRepository<ShiftChangeRequest, Long> {
    List<ShiftChangeRequest> findByUserId(Long userId);
    List<ShiftChangeRequest> findByStatus(String status);
}
