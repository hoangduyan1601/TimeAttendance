package com.smartops.core.config;

import com.smartops.core.entity.Department;
import com.smartops.core.entity.User;
import com.smartops.core.repository.DepartmentRepository;
import com.smartops.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "app.demo-data-enabled", havingValue = "true")
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {
    private final UserRepository userRepository;
    private final DepartmentRepository departmentRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.demo-password:}")
    private String demoPassword;

    @Override
    public void run(String... args) {
        if (demoPassword.length() < 8) {
            throw new IllegalStateException("DEMO_PASSWORD must contain at least 8 characters when demo data is enabled");
        }
        Department department = departmentRepository.findAll().stream().findFirst()
                .orElseGet(() -> departmentRepository.save(Department.builder()
                        .name("System Administration").description("Demo administration department").build()));
        upsert("admin", "System Administrator", "admin@smartops.com", "ADMIN", "ADMIN001", "APPROVED", department);
        upsert("anque", "An Que", "anque@smartops.com", "EMPLOYEE", "NV-ANQUE", "NOT_STARTED", department);
    }

    private void upsert(String username, String fullName, String email, String role,
                        String employeeCode, String ekycStatus, Department department) {
        User user = userRepository.findByUsername(username).orElseGet(User::new);
        user.setUsername(username);
        user.setPassword(passwordEncoder.encode(demoPassword));
        user.setFullName(fullName);
        user.setEmail(email);
        user.setRole(role);
        user.setEmployeeCode(employeeCode);
        user.setStatus("ACTIVE");
        user.setEkycStatus(ekycStatus);
        user.setDepartment(department);
        userRepository.save(user);
    }
}
