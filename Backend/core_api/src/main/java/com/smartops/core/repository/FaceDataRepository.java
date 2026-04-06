package com.smartops.core.repository;

import com.smartops.core.entity.FaceData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

/**
 * Repository cho FaceData
 */
@Repository
public interface FaceDataRepository extends JpaRepository<FaceData, Long> {
    Optional<FaceData> findByUserId(Long userId);
}
