-- ========================================================
-- DATA INITIALIZATION FOR SMARTOPS
-- ========================================================

-- 1. DEPARTMENTS
INSERT INTO departments (id, name, description, created_at, updated_at) VALUES
(1, 'Phòng Giám đốc', 'Ban điều hành và chiến lược công ty', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 'Phòng Nhân sự (HR)', 'Quản lý nhân sự, tuyển dụng và tiền lương', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 'Phòng Kỹ thuật (IT)', 'Phát triển phần mềm và hạ tầng hệ thống', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 'Phòng Kinh doanh', 'Tiếp thị và bán hàng sản phẩm SmartOps', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(5, 'Phòng Kế toán', 'Quản lý tài chính và thuế', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(6, 'Phòng Sản xuất', 'Vận hành và sản xuất trực tiếp', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- 2. SHIFT CONFIGURATIONS
INSERT INTO shift_configs (id, shift_name, start_time, end_time, late_threshold_minutes, is_active, location) VALUES
(1, 'Ca Hành chính', '08:00:00', '17:30:00', 15, true, 'Văn phòng chính'),
(2, 'Ca Sáng', '06:00:00', '14:00:00', 10, true, 'Nhà máy A'),
(3, 'Ca Chiều', '14:00:00', '22:00:00', 10, true, 'Nhà máy A'),
(4, 'Ca Đêm', '22:00:00', '06:00:00', 5, true, 'Nhà máy A')
ON CONFLICT (id) DO UPDATE SET shift_name = EXCLUDED.shift_name;

-- 3. USERS (Mật khẩu '123456' dạng văn bản thô)
INSERT INTO users (full_name, username, employee_code, email, phone_number, password, role, status, ekyc_status, department_id, assigned_shift_id, created_at) VALUES
('Nguyễn Văn Quản Trị', 'admin', 'ADM001', 'admin@smartops.com', '0901234567', '123456', 'ADMIN', 'ACTIVE', 'APPROVED', 1, 1, CURRENT_TIMESTAMP),
('Trần Thị Nhân Sự', 'hr_manager', 'HR001', 'hr@smartops.com', '0901234568', '123456', 'ADMIN', 'ACTIVE', 'APPROVED', 2, 1, CURRENT_TIMESTAMP),
('Lê Hoàng Nam', 'nam.lh', 'IT001', 'nam.lh@smartops.com', '0901234569', '123456', 'EMPLOYEE', 'ACTIVE', 'NOT_STARTED', 3, 1, CURRENT_TIMESTAMP),
('Phạm Minh Đức', 'duc.pm', 'IT002', 'duc.pm@smartops.com', '0901234570', '123456', 'EMPLOYEE', 'ACTIVE', 'NOT_STARTED', 3, 1, CURRENT_TIMESTAMP),
('Vũ Văn Hùng', 'hung.vv', 'PRO001', 'hung.vv@smartops.com', '0901234572', '123456', 'EMPLOYEE', 'ACTIVE', 'NOT_STARTED', 6, 2, CURRENT_TIMESTAMP)
ON CONFLICT (username) DO NOTHING;

-- 4. OT REQUESTS & NOTIFICATIONS
INSERT INTO overtime_requests (user_id, date, start_time, end_time, reason, status, created_at, updated_at)
VALUES 
(3, CURRENT_DATE, '17:30:00', '20:00:00', 'Hoàn thành báo cáo quý', 'PENDING', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, CURRENT_DATE, '18:00:00', '21:00:00', 'Hỗ trợ triển khai server', 'APPROVED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO notifications (title, message, type, is_read, created_at)
VALUES 
('Cảnh báo quá giờ: NV003', 'Nhân viên Lê Hoàng Nam (NV003) đã quá giờ tan ca.', 'ALERT', false, CURRENT_TIMESTAMP),
('Thông báo hệ thống', 'Phiên bản SmartOps 2.0 đã được cập nhật.', 'INFO', true, CURRENT_TIMESTAMP - INTERVAL '2 hours');
