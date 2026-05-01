package com.smartops.core.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartops.core.dto.AttendanceResponseDTO;
import com.smartops.core.dto.DashboardStatsDTO;
import com.smartops.core.dto.EkycReviewDTO;
import com.smartops.core.service.AdminService;
import com.smartops.core.service.DashboardService;
import com.smartops.core.service.ReportService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc(addFilters = false) // Tạm tắt filter security để test logic controller
public class AdminControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AdminService adminService;

    @MockBean
    private DashboardService dashboardService;

    @MockBean
    private ReportService reportService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testGetDashboardStats() throws Exception {
        DashboardStatsDTO mockStats = DashboardStatsDTO.builder()
                .totalEmployees(100)
                .presentToday(80)
                .build();

        when(dashboardService.getStats()).thenReturn(mockStats);

        mockMvc.perform(get("/api/v1/admin/dashboard/stats"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.totalEmployees").value(100));
    }

    @Test
    public void testReviewEkyc() throws Exception {
        EkycReviewDTO reviewDTO = EkycReviewDTO.builder()
                .status("APPROVED")
                .build();

        doNothing().when(adminService).reviewEkyc(eq(1L), any(EkycReviewDTO.class));

        mockMvc.perform(put("/api/v1/admin/ekyc/1/review")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(reviewDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Cập nhật trạng thái eKYC thành công"));
    }
}
