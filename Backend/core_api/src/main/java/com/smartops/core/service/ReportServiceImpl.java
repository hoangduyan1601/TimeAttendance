package com.smartops.core.service;

import com.smartops.core.entity.AttendanceLog;
import com.smartops.core.repository.AttendanceLogRepository;
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

@Service
@RequiredArgsConstructor
public class ReportServiceImpl implements ReportService {

    private final AttendanceLogRepository attendanceLogRepository;

    @Override
    public ByteArrayInputStream exportAttendanceToExcel(LocalDate startDate, LocalDate endDate) {
        String[] columns = {"STT", "Họ Tên", "Mã NV", "Phòng Ban", "Ngày", "Giờ Chấm Công", "Trạng Thái"};

        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Báo cáo chấm công");

            // Style cho Header
            Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            headerFont.setColor(IndexedColors.WHITE.getIndex());

            CellStyle headerCellStyle = workbook.createCellStyle();
            headerCellStyle.setFont(headerFont);
            headerCellStyle.setFillForegroundColor(IndexedColors.BLUE_GREY.getIndex());
            headerCellStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);

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

            // Tự động căn chỉnh độ rộng cột
            for (int i = 0; i < columns.length; i++) {
                sheet.autoSizeColumn(i);
            }

            workbook.write(out);
            return new ByteArrayInputStream(out.toByteArray());
        } catch (IOException e) {
            throw new RuntimeException("Lỗi khi xuất file Excel: " + e.getMessage());
        }
    }
}
