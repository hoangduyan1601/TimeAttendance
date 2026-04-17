package com.smartops.core.service;

import com.smartops.core.dto.ShiftChangeDTO;
import com.smartops.core.dto.ShiftConfigDTO;
import com.smartops.core.entity.ShiftChangeRequest;
import com.smartops.core.entity.ShiftConfig;
import com.smartops.core.entity.User;
import com.smartops.core.repository.ShiftChangeRequestRepository;
import com.smartops.core.repository.ShiftConfigRepository;
import com.smartops.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ShiftConfigServiceImpl implements ShiftConfigService {

    private final ShiftConfigRepository shiftConfigRepository;
    private final ShiftChangeRequestRepository shiftChangeRequestRepository;
    private final UserRepository userRepository;
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm");

    @Override
    public List<ShiftChangeDTO> getAllShiftChangeRequests() {
        return shiftChangeRequestRepository.findAll().stream()
                .map(this::mapToShiftChangeDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void reviewShiftChangeRequest(Long requestId, String status) {
        ShiftChangeRequest request = shiftChangeRequestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu đổi ca"));

        request.setStatus(status);
        
        if ("APPROVED".equals(status)) {
            User user = request.getUser();
            user.setAssignedShift(request.getNewShift());
            userRepository.save(user);
        }

        shiftChangeRequestRepository.save(request);
    }

    private ShiftChangeDTO mapToShiftChangeDTO(ShiftChangeRequest request) {
        return ShiftChangeDTO.builder()
                .id(request.getId())
                .userId(request.getUser().getId())
                .fullName(request.getUser().getFullName())
                .oldShiftId(request.getOldShift().getId())
                .oldShiftName(request.getOldShift().getShiftName())
                .newShiftId(request.getNewShift().getId())
                .newShiftName(request.getNewShift().getShiftName())
                .reason(request.getReason())
                .status(request.getStatus())
                .createdAt(request.getCreatedAt())
                .build();
    }

    @Override
    public ShiftConfigDTO createShift(ShiftConfigDTO dto) {
        try {
            LocalTime start = LocalTime.parse(dto.getStartTime(), TIME_FORMATTER);
            LocalTime end = LocalTime.parse(dto.getEndTime(), TIME_FORMATTER);

            ShiftConfig shift = ShiftConfig.builder()
                    .shiftName(dto.getShiftName())
                    .startTime(start)
                    .endTime(end)
                    .lateThresholdMinutes(dto.getGracePeriod())
                    .isActive(true)
                    .build();

            ShiftConfig saved = shiftConfigRepository.save(shift);
            return mapToDTO(saved);
        } catch (DateTimeParseException e) {
            throw new RuntimeException("Định dạng thời gian không hợp lệ (HH:mm): " + e.getMessage());
        }
    }

    @Override
    public ShiftConfigDTO updateShift(Long id, ShiftConfigDTO dto) {
        ShiftConfig shift = shiftConfigRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy ca làm việc với id: " + id));
        
        try {
            shift.setShiftName(dto.getShiftName());
            shift.setStartTime(LocalTime.parse(dto.getStartTime(), TIME_FORMATTER));
            shift.setEndTime(LocalTime.parse(dto.getEndTime(), TIME_FORMATTER));
            shift.setLateThresholdMinutes(dto.getGracePeriod());
            shift.setIsActive(dto.getIsActive() != null ? dto.getIsActive() : true);

            ShiftConfig updated = shiftConfigRepository.save(shift);
            return mapToDTO(updated);
        } catch (DateTimeParseException e) {
            throw new RuntimeException("Định dạng thời gian không hợp lệ (HH:mm): " + e.getMessage());
        }
    }

    @Override
    public void deleteShift(Long id) {
        if (!shiftConfigRepository.existsById(id)) {
            throw new RuntimeException("Không tìm thấy ca làm việc với id: " + id);
        }
        shiftConfigRepository.deleteById(id);
    }

    @Override
    public List<ShiftConfigDTO> getAllShifts() {
        return shiftConfigRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public ShiftConfigDTO getActiveShift(LocalTime currentTime) {
        List<ShiftConfig> activeShifts = shiftConfigRepository.findShiftsAtTime(currentTime);
        if (activeShifts.isEmpty()) {
            return null; // Hoặc ném lỗi nếu muốn
        }
        // Trả về ca làm việc đầu tiên tìm thấy phù hợp với khung giờ
        return mapToDTO(activeShifts.get(0));
    }

    private ShiftConfigDTO mapToDTO(ShiftConfig shift) {
        return ShiftConfigDTO.builder()
                .id(shift.getId())
                .shiftName(shift.getShiftName())
                .startTime(shift.getStartTime().format(TIME_FORMATTER))
                .endTime(shift.getEndTime().format(TIME_FORMATTER))
                .gracePeriod(shift.getLateThresholdMinutes() != null ? shift.getLateThresholdMinutes() : 0)
                .isActive(shift.getIsActive() != null ? shift.getIsActive() : true)
                .build();
    }
}
