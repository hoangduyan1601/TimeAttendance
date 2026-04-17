package com.smartops.core.service;

import com.smartops.core.dto.ShiftChangeDTO;
import com.smartops.core.dto.ShiftConfigDTO;
import java.time.LocalTime;
import java.util.List;

public interface ShiftConfigService {
    ShiftConfigDTO createShift(ShiftConfigDTO dto);
    ShiftConfigDTO updateShift(Long id, ShiftConfigDTO dto);
    void deleteShift(Long id);
    List<ShiftConfigDTO> getAllShifts();
    ShiftConfigDTO getActiveShift(LocalTime currentTime);

    // Admin review
    List<ShiftChangeDTO> getAllShiftChangeRequests();
    void reviewShiftChangeRequest(Long requestId, String status);
}
