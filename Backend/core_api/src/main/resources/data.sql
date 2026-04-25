-- ========================================================
-- DỮ LIỆU MẪU BỔ SUNG CHO OT VÀ THÔNG BÁO
-- ========================================================

-- Thêm đơn OT mẫu (Lưu ý: User ID 3 và 4 phải tồn tại từ các lệnh insert trước đó)
-- Nếu dùng ON CONFLICT để tránh lỗi khi chạy lại nhiều lần
INSERT INTO overtime_requests (user_id, date, start_time, end_time, reason, status, created_at, updated_at)
VALUES 
(3, CURRENT_DATE, '17:30:00', '20:00:00', 'Hoàn thành báo cáo quý cho bộ phận kinh doanh', 'PENDING', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, CURRENT_DATE, '18:00:00', '21:00:00', 'Hỗ trợ triển khai server mới tại chi nhánh', 'APPROVED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, CURRENT_DATE - 1, '17:30:00', '19:00:00', 'Dọn dẹp kho dữ liệu cũ', 'REJECTED', CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day');

-- Thêm thông báo mẫu dành cho Admin
INSERT INTO notifications (title, message, type, is_read, created_at)
VALUES 
('Cảnh báo quá giờ: NV003', 'Nhân viên Lê Hoàng Nam (NV003) đã quá giờ tan ca (> 1 tiếng) nhưng chưa check-out. Ca kết thúc: 17:30:00', 'ALERT', false, CURRENT_TIMESTAMP),
('Thông báo hệ thống', 'Phiên bản SmartOps 2.0 đã được cập nhật thành công.', 'INFO', true, CURRENT_TIMESTAMP - INTERVAL '2 hours');
