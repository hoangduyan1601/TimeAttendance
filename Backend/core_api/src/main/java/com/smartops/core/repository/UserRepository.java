package com.smartops.core.repository;

import com.smartops.core.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Repository cho User
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select u from User u where u.id = :id")
    Optional<User> findByIdForUpdate(@Param("id") Long id);
    Optional<User> findByEmail(String email);
    Optional<User> findByEmployeeCode(String employeeCode);
    Optional<User> findByUsername(String username);
    java.util.List<User> findAllByEkycStatus(String status);
    java.util.List<User> findAllByDepartmentId(Long departmentId);
    java.util.List<User> findAllByAssignedShiftIsNotNull();
    
    long countByStatus(String status);
}
