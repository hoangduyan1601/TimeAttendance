package com.smartops.core.service;

import com.smartops.core.dto.UserRequestDTO;
import com.smartops.core.dto.UserResponseDTO;
import java.util.List;

public interface UserService {
    UserResponseDTO createUser(UserRequestDTO request);
    UserResponseDTO updateUser(Long id, UserRequestDTO request);
    void deleteUser(Long id);
    List<UserResponseDTO> getAllUsers();
}
