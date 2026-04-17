package com.smartops.core.repository;

import com.smartops.core.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

/**
 * Repository cho User
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    Optional<User> findByEmployeeCode(String employeeCode);
    Optional<User> findByUsername(String username);
    java.util.List<User> findAllByEkycStatus(String status);
    java.util.List<User> findAllByDepartmentId(Long departmentId);
    java.util.List<User> findAllByAssignedShiftIsNotNull();
    
    long countByStatus(String status);
}
