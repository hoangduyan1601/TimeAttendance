package com.smartops.core.service;

import com.smartops.core.dto.ShiftConfigDTO;
import com.smartops.core.entity.ShiftConfig;
import com.smartops.core.repository.ShiftConfigRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ShiftConfigServiceImpl implements ShiftConfigService {

    private final ShiftConfigRepository shiftConfigRepository;
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm");

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
                .build();
    }
}
