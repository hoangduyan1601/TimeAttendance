package com.smartops.core.config;

import com.smartops.core.entity.Department;
import com.smartops.core.entity.User;
import com.smartops.core.repository.DepartmentRepository;
import com.smartops.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final DepartmentRepository departmentRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        // 1. Đảm bảo có ít nhất một phòng ban
        Department dept;
        if (departmentRepository.count() == 0) {
            dept = Department.builder()
                    .name("Ban Quản Trị")
                    .description("Phòng ban dành cho Admin hệ thống")
                    .build();
            dept = departmentRepository.save(dept);
        } else {
            dept = departmentRepository.findAll().get(0);
        }

        // 2. Tạo hoặc Cập nhật tài khoản Admin với mật khẩu 123456
        Optional<User> existingAdmin = userRepository.findByUsername("admin");
        User admin;
        
        if (existingAdmin.isPresent()) {
            admin = existingAdmin.get();
            admin.setPassword(passwordEncoder.encode("123456"));
            admin.setRole("ADMIN"); // Đảm bảo đúng quyền
            admin.setStatus("ACTIVE");
            System.out.println(">>> Đã CẬP NHẬT mật khẩu Admin thành: 123456");
        } else {
            admin = User.builder()
                    .username("admin")
                    .password(passwordEncoder.encode("123456"))
                    .fullName("System Administrator")
                    .email("admin@smartops.com")
                    .role("ADMIN")
                    .employeeCode("ADMIN001")
                    .status("ACTIVE")
                    .ekycStatus("APPROVED")
                    .department(dept)
                    .build();
            System.out.println(">>> Đã TẠO MỚI tài khoản Admin: admin / 123456");
        }
        
        userRepository.save(admin);
    }
}
