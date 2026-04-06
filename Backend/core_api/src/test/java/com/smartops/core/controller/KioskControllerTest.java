package com.smartops.core.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartops.core.dto.KioskVerifyRequest;
import com.smartops.core.dto.KioskVerifyResponse;
import com.smartops.core.service.AttendanceService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
public class KioskControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AttendanceService attendanceService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testVerifyKioskSuccess() throws Exception {
        // Dữ liệu giả lập
        KioskVerifyResponse mockResponse = KioskVerifyResponse.builder()
                .employeeName("Hoàng Duy An")
                .attendanceStatus("ON_TIME")
                .similarityScore(0.95)
                .time("07:45:00")
                .build();

        when(attendanceService.verify(any(KioskVerifyRequest.class))).thenReturn(mockResponse);

        KioskVerifyRequest verifyRequest = KioskVerifyRequest.builder()
                .kioskId("K01")
                .qrToken("valid-token")
                .liveImageBase64("data:image/jpeg;base64,...")
                .build();

        mockMvc.perform(post("/api/v1/kiosk/verify")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(verifyRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.employeeName").value("Hoàng Duy An"))
                .andExpect(jsonPath("$.data.attendanceStatus").value("ON_TIME"));
    }
}
