package com.smartops.core.service;

import java.io.ByteArrayInputStream;
import java.time.LocalDate;

public interface ReportService {
    ByteArrayInputStream exportAttendanceToExcel(LocalDate startDate, LocalDate endDate);
    ByteArrayInputStream exportAttendanceSummaryToExcel(LocalDate startDate, LocalDate endDate);
}
