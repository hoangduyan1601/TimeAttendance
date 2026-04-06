package com.smartops.core.service;

import com.smartops.core.dto.UserRequestDTO;
import com.smartops.core.dto.UserResponseDTO;
import com.smartops.core.entity.Department;
import com.smartops.core.entity.User;
import com.smartops.core.repository.DepartmentRepository;
import com.smartops.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final DepartmentRepository departmentRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public UserResponseDTO createUser(UserRequestDTO request) {
        // 1. Kiểm tra username đã tồn tại chưa
        if (userRepository.findByUsername(request.getUsername()).isPresent()) {
            throw new RuntimeException("Username đã tồn tại: " + request.getUsername());
        }

        // 2. Lấy Department từ DB
        Department department = departmentRepository.findById(request.getDepartmentId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phòng ban với id: " + request.getDepartmentId()));

        // 3. Sinh employeeCode tự động (VD: NV + 4 số ngẫu nhiên)
        String employeeCode = "NV" + (1000 + new Random().nextInt(9000));
        // Kiểm tra xem mã nhân viên có trùng không (nếu xui)
        while (userRepository.findByEmployeeCode(employeeCode).isPresent()) {
            employeeCode = "NV" + (1000 + new Random().nextInt(9000));
        }

        // 4. Mã hóa password
        String encodedPassword = passwordEncoder.encode(request.getPassword());

        // 5. Build User entity
        User user = User.builder()
                .username(request.getUsername())
                .password(encodedPassword)
                .email(request.getEmail()) // Lấy từ request
                .fullName(request.getFullName())
                .role(request.getRole())
                .employeeCode(employeeCode)
                .department(department)
                .ekycStatus("PENDING")
                .status("ACTIVE")
                .build();

        // 6. Lưu xuống DB
        User savedUser = userRepository.save(user);

        // 7. Mapping sang Response DTO
        return mapToResponseDTO(savedUser);
    }

    @Override
    public List<UserResponseDTO> getAllUsers() {
        return userRepository.findAll().stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }

    private UserResponseDTO mapToResponseDTO(User user) {
        return UserResponseDTO.builder()
                .id(user.getId())
                .username(user.getUsername())
                .fullName(user.getFullName())
                .role(user.getRole())
                .ekycStatus(user.getEkycStatus())
                .departmentName(user.getDepartment() != null ? user.getDepartment().getName() : null)
                .build();
    }
}
