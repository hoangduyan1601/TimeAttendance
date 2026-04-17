package com.smartops.core.controller;

import com.smartops.core.dto.AttendanceHistoryDTO;
import com.smartops.core.dto.LeaveRequestDTO;
import com.smartops.core.dto.LeaveResponseDTO;
import com.smartops.core.service.EmployeeService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.Collections;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc(addFilters = false)
public class EmployeeControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private EmployeeService employeeService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testGetMyAttendance() throws Exception {
        AttendanceHistoryDTO mockHistory = AttendanceHistoryDTO.builder()
                .status("ON_TIME")
                .checkInTime(LocalDateTime.now())
                .build();

        when(employeeService.getMyAttendanceHistory(anyString(), anyString())).thenReturn(Collections.singletonList(mockHistory));

        mockMvc.perform(get("/api/v1/employee/attendance")
                        .param("startDate", "2024-01-01")
                        .param("endDate", "2024-01-31"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data[0].status").value("ON_TIME"));
    }

    @Test
    public void testSubmitLeave() throws Exception {
        LeaveRequestDTO request = LeaveRequestDTO.builder()
                .reason("Nghỉ ốm")
                .fromDate(java.time.LocalDate.now())
                .toDate(java.time.LocalDate.now().plusDays(1))
                .build();

        LeaveResponseDTO mockResponse = LeaveResponseDTO.builder()
                .id(1L)
                .status("PENDING")
                .reason("Nghỉ ốm")
                .build();

        when(employeeService.submitLeaveRequest(any(LeaveRequestDTO.class))).thenReturn(mockResponse);

        mockMvc.perform(post("/api/v1/employee/leaves")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("PENDING"));
    }
}
