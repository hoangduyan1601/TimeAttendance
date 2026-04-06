package com.smartops.core.service;

import com.smartops.core.dto.ShiftConfigDTO;
import java.time.LocalTime;
import java.util.List;

public interface ShiftConfigService {
    ShiftConfigDTO createShift(ShiftConfigDTO dto);
    List<ShiftConfigDTO> getAllShifts();
    ShiftConfigDTO getActiveShift(LocalTime currentTime);
}
