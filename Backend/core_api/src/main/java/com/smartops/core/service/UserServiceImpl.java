package com.smartops.core.service;

import com.smartops.core.dto.UserRequestDTO;
import com.smartops.core.dto.UserResponseDTO;
import com.smartops.core.entity.Department;
import com.smartops.core.entity.User;
import com.smartops.core.entity.ShiftConfig;
import com.smartops.core.repository.DepartmentRepository;
import com.smartops.core.repository.ShiftConfigRepository;
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
    private final ShiftConfigRepository shiftConfigRepository;
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

        // 3. Lấy Shift từ DB nếu có
        ShiftConfig shift = null;
        if (request.getAssignedShiftId() != null) {
            shift = shiftConfigRepository.findById(request.getAssignedShiftId())
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy ca làm việc với id: " + request.getAssignedShiftId()));
        }

        // 4. Sinh employeeCode tự động
        String employeeCode = "NV" + (1000 + new Random().nextInt(9000));
        while (userRepository.findByEmployeeCode(employeeCode).isPresent()) {
            employeeCode = "NV" + (1000 + new Random().nextInt(9000));
        }

        // 5. Mã hóa password
        String encodedPassword = passwordEncoder.encode(request.getPassword());

        // 6. Build User entity
        User user = User.builder()
                .username(request.getUsername())
                .password(encodedPassword)
                .email(request.getEmail())
                .fullName(request.getFullName())
                .phoneNumber(request.getPhoneNumber())
                .role(request.getRole())
                .employeeCode(employeeCode)
                .department(department)
                .assignedShift(shift)
                .ekycStatus("PENDING")
                .status("ACTIVE")
                .build();

        // 7. Lưu xuống DB
        User savedUser = userRepository.save(user);

        return mapToResponseDTO(savedUser);
    }

    @Override
    public UserResponseDTO updateUser(Long id, UserRequestDTO request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy nhân viên với id: " + id));

        user.setFullName(request.getFullName());
        user.setEmail(request.getEmail());
        user.setPhoneNumber(request.getPhoneNumber());
        user.setRole(request.getRole());

        if (request.getPassword() != null && !request.getPassword().isEmpty()) {
            user.setPassword(passwordEncoder.encode(request.getPassword()));
        }

        if (request.getDepartmentId() != null) {
            Department department = departmentRepository.findById(request.getDepartmentId())
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy phòng ban với id: " + request.getDepartmentId()));
            user.setDepartment(department);
        }

        if (request.getAssignedShiftId() != null) {
            ShiftConfig shift = shiftConfigRepository.findById(request.getAssignedShiftId())
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy ca làm việc với id: " + request.getAssignedShiftId()));
            user.setAssignedShift(shift);
        }

        User updatedUser = userRepository.save(user);
        return mapToResponseDTO(updatedUser);
    }

    @Override
    public void deleteUser(Long id) {
        if (!userRepository.existsById(id)) {
            throw new RuntimeException("Không tìm thấy nhân viên với id: " + id);
        }
        userRepository.deleteById(id);
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
                .email(user.getEmail())
                .fullName(user.getFullName())
                .employeeCode(user.getEmployeeCode())
                .phoneNumber(user.getPhoneNumber())
                .role(user.getRole())
                .ekycStatus(user.getEkycStatus())
                .departmentName(user.getDepartment() != null ? user.getDepartment().getName() : null)
                .departmentId(user.getDepartment() != null ? user.getDepartment().getId() : null)
                .assignedShiftId(user.getAssignedShift() != null ? user.getAssignedShift().getId() : null)
                .assignedShiftName(user.getAssignedShift() != null ? user.getAssignedShift().getShiftName() : null)
                .idCardUrl(user.getFaceData() != null ? user.getFaceData().getIdCardUrl() : null)
                .selfieUrl(user.getFaceData() != null ? user.getFaceData().getSelfieUrl() : null)
                .build();
    }
}
