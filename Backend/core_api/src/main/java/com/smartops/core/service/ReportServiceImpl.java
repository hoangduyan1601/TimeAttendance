package com.smartops.core.service;

import com.smartops.core.entity.AttendanceLog;
import com.smartops.core.entity.LeaveRequest;
import com.smartops.core.entity.User;
import com.smartops.core.repository.AttendanceLogRepository;
import com.smartops.core.repository.UserRepository;
import com.smartops.core.repository.LeaveRequestRepository;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.time.Duration;

@Service
@RequiredArgsConstructor
public class ReportServiceImpl implements ReportService {

    private final AttendanceLogRepository attendanceLogRepository;
    private final UserRepository userRepository;
    private final LeaveRequestRepository leaveRequestRepository;

    @Override
    public ByteArrayInputStream exportAttendanceToExcel(LocalDate startDate, LocalDate endDate) {
        // ... (existing implementation remains the same)
        String[] columns = {"STT", "Họ Tên", "Mã NV", "Phòng Ban", "Ngày", "Giờ Chấm Công", "Trạng Thái"};

        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Chi tiết chấm công");

            // Style cho Header
            Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            headerFont.setColor(IndexedColors.WHITE.getIndex());

            CellStyle headerCellStyle = workbook.createCellStyle();
            headerCellStyle.setFont(headerFont);
            headerCellStyle.setFillForegroundColor(IndexedColors.BLUE_GREY.getIndex());
            headerCellStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            headerCellStyle.setAlignment(HorizontalAlignment.CENTER);

            // Tạo Header Row
            Row headerRow = sheet.createRow(0);
            for (int col = 0; col < columns.length; col++) {
                Cell cell = headerRow.createCell(col);
                cell.setCellValue(columns[col]);
                cell.setCellStyle(headerCellStyle);
            }

            // Lấy dữ liệu
            List<AttendanceLog> logs = attendanceLogRepository.findByCheckInTimeBetweenOrderByCheckInTimeAsc(
                    startDate.atStartOfDay(), endDate.atTime(23, 59, 59));

            int rowIdx = 1;
            DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
            DateTimeFormatter timeFormatter = DateTimeFormatter.ofPattern("HH:mm:ss");

            for (AttendanceLog log : logs) {
                Row row = sheet.createRow(rowIdx++);

                row.createCell(0).setCellValue(rowIdx - 1);
                row.createCell(1).setCellValue(log.getUser().getFullName());
                row.createCell(2).setCellValue(log.getUser().getEmployeeCode());
                row.createCell(3).setCellValue(log.getUser().getDepartment() != null ? log.getUser().getDepartment().getName() : "N/A");
                row.createCell(4).setCellValue(log.getCheckInTime().format(dateFormatter));
                row.createCell(5).setCellValue(log.getCheckInTime().format(timeFormatter));
                row.createCell(6).setCellValue(log.getStatus());
            }

            for (int i = 0; i < columns.length; i++) {
                sheet.autoSizeColumn(i);
            }

            workbook.write(out);
            return new ByteArrayInputStream(out.toByteArray());
        } catch (IOException e) {
            throw new RuntimeException("Lỗi khi xuất file Excel: " + e.getMessage());
        }
    }

    @Override
    public ByteArrayInputStream exportAttendanceSummaryToExcel(LocalDate startDate, LocalDate endDate) {
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Bảng Chấm Công Tổng Hợp");

            // --- 1. STYLING & FONTS ---
            Font titleFont = workbook.createFont();
            titleFont.setBold(true);
            titleFont.setFontHeightInPoints((short) 18);
            titleFont.setColor(IndexedColors.DARK_BLUE.getIndex());

            CellStyle titleStyle = workbook.createCellStyle();
            titleStyle.setFont(titleFont);
            titleStyle.setAlignment(HorizontalAlignment.CENTER);

            CellStyle headerStyle = workbook.createCellStyle();
            Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            headerFont.setColor(IndexedColors.WHITE.getIndex());
            headerStyle.setFont(headerFont);
            headerStyle.setFillForegroundColor(IndexedColors.CORNFLOWER_BLUE.getIndex());
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            headerStyle.setAlignment(HorizontalAlignment.CENTER);
            headerStyle.setVerticalAlignment(VerticalAlignment.CENTER);
            headerStyle.setBorderBottom(BorderStyle.THIN);
            headerStyle.setBorderLeft(BorderStyle.THIN);
            headerStyle.setBorderRight(BorderStyle.THIN);
            headerStyle.setBorderTop(BorderStyle.THIN);

            CellStyle dayStyle = workbook.createCellStyle();
            dayStyle.setAlignment(HorizontalAlignment.CENTER);
            dayStyle.setBorderBottom(BorderStyle.THIN);
            dayStyle.setBorderLeft(BorderStyle.THIN);
            dayStyle.setBorderRight(BorderStyle.THIN);
            dayStyle.setBorderTop(BorderStyle.THIN);

            CellStyle weekendStyle = workbook.createCellStyle();
            weekendStyle.cloneStyleFrom(dayStyle);
            weekendStyle.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
            weekendStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);

            CellStyle summaryStyle = workbook.createCellStyle();
            summaryStyle.cloneStyleFrom(dayStyle);
            Font boldFont = workbook.createFont();
            boldFont.setBold(true);
            summaryStyle.setFont(boldFont);

            // --- 2. PREPARE COLUMNS ---
            int numDays = (int) Duration.between(startDate.atStartOfDay(), endDate.plusDays(1).atStartOfDay()).toDays();
            int startDataCol = 4;
            int totalCols = startDataCol + numDays + 5; // Basic info + Days + 5 Summary cols

            // --- 3. CREATE HEADERS ---
            // Row 0: Title
            Row titleRow = sheet.createRow(0);
            Cell titleCell = titleRow.createCell(0);
            titleCell.setCellValue("BẢNG TỔNG HỢP CÔNG NHÂN VIÊN");
            titleCell.setCellStyle(titleStyle);
            sheet.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(0, 0, 0, totalCols - 1));

            // Row 1: Date Range
            Row infoRow = sheet.createRow(1);
            infoRow.createCell(0).setCellValue("Kỳ báo cáo: " + startDate.toString() + " đến " + endDate.toString());
            sheet.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(1, 1, 0, totalCols - 1));

            // Row 3: Table Headers
            Row headerRow = sheet.createRow(3);
            String[] basicHeaders = {"STT", "Mã NV", "Họ và Tên", "Phòng Ban"};
            for (int i = 0; i < basicHeaders.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(basicHeaders[i]);
                cell.setCellStyle(headerStyle);
            }

            // Day columns
            for (int i = 0; i < numDays; i++) {
                LocalDate date = startDate.plusDays(i);
                Cell cell = headerRow.createCell(startDataCol + i);
                cell.setCellValue(date.getDayOfMonth());
                cell.setCellStyle(headerStyle);
            }

            // Summary headers
            String[] summaryHeaders = {"CÔNG", "MUỘN", "PHÉP", "VẮNG", "TỔNG GIỜ"};
            for (int i = 0; i < summaryHeaders.length; i++) {
                Cell cell = headerRow.createCell(startDataCol + numDays + i);
                cell.setCellValue(summaryHeaders[i]);
                cell.setCellStyle(headerStyle);
            }

            // --- 4. DATA AGGREGATION ---
            List<User> users = userRepository.findAll();
            List<AttendanceLog> logs = attendanceLogRepository.findByCheckInTimeBetweenOrderByCheckInTimeAsc(
                    startDate.atStartOfDay(), endDate.atTime(23, 59, 59));
            List<LeaveRequest> allLeaves = leaveRequestRepository.findAll();

            int rowIdx = 4;
            int stt = 1;

            for (User user : users) {
                Row row = sheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(stt++);
                row.createCell(1).setCellValue(user.getEmployeeCode());
                row.createCell(2).setCellValue(user.getFullName());
                row.createCell(3).setCellValue(user.getDepartment() != null ? user.getDepartment().getName() : "N/A");

                int totalPresent = 0;
                int totalLate = 0;
                int totalExcused = 0;
                int totalAbsent = 0;
                double totalHours = 0.0;

                for (int i = 0; i < numDays; i++) {
                    LocalDate currentDate = startDate.plusDays(i);
                    Cell cell = row.createCell(startDataCol + i);
                    
                    // Check if weekend
                    boolean isWeekend = currentDate.getDayOfWeek().getValue() == 7;
                    cell.setCellStyle(isWeekend ? weekendStyle : dayStyle);

                    // Find log for this day
                    AttendanceLog dayLog = logs.stream()
                        .filter(l -> l.getUser().getId().equals(user.getId()) && l.getCheckInTime().toLocalDate().equals(currentDate))
                        .findFirst().orElse(null);

                    // Find leave for this day
                    boolean isOnLeave = allLeaves.stream()
                        .anyMatch(l -> l.getUser().getId().equals(user.getId()) && "APPROVED".equals(l.getStatus()) 
                                     && !currentDate.isBefore(l.getStartDate()) && !currentDate.isAfter(l.getEndDate()));

                    if (dayLog != null) {
                        totalPresent++;
                        String status = "X"; // Present
                        if ("LATE".equals(dayLog.getStatus())) {
                            totalLate++;
                            status = "L"; // Late
                        }
                        cell.setCellValue(status);
                        
                        if (dayLog.getCheckOutTime() != null) {
                            totalHours += Duration.between(dayLog.getCheckInTime(), dayLog.getCheckOutTime()).toMinutes() / 60.0;
                        }
                    } else if (isOnLeave) {
                        totalExcused++;
                        cell.setCellValue("P"); // Leave
                    } else if (!isWeekend) {
                        totalAbsent++;
                        cell.setCellValue("V"); // Absent
                    }
                }

                // Fill summaries
                row.createCell(startDataCol + numDays).setCellValue(totalPresent);
                row.createCell(startDataCol + numDays + 1).setCellValue(totalLate);
                row.createCell(startDataCol + numDays + 2).setCellValue(totalExcused);
                row.createCell(startDataCol + numDays + 3).setCellValue(totalAbsent);
                row.createCell(startDataCol + numDays + 4).setCellValue(Math.round(totalHours * 10.0) / 10.0);

                // Style summary cells
                for (int i = 0; i < 5; i++) {
                    row.getCell(startDataCol + numDays + i).setCellStyle(summaryStyle);
                }
            }

            // Auto-size basic info columns
            for (int i = 0; i < 4; i++) sheet.autoSizeColumn(i);
            // Fix width for day columns
            for (int i = 0; i < numDays; i++) sheet.setColumnWidth(startDataCol + i, 1000);

            workbook.write(out);
            return new ByteArrayInputStream(out.toByteArray());
        } catch (IOException e) {
            throw new RuntimeException("Lỗi khi xuất bảng công matrix: " + e.getMessage());
        }
    }
}
