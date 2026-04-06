package com.smartops.core.repository;

import com.smartops.core.entity.Department;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repository cho Department
 */
@Repository
public interface DepartmentRepository extends JpaRepository<Department, Long> {
}
