-- ========================================================
-- SEED DATA FOR SMARTOPS ATTENDANCE SYSTEM
-- Purposing: Simulate 2+ years of operation (2024-2026)
-- Database: PostgreSQL
-- ========================================================

-- 1. CLEANUP (Optional - Uncomment if you want a fresh start)
-- DELETE FROM attendance_logs;
-- DELETE FROM leave_requests;
-- DELETE FROM shift_change_requests;
-- DELETE FROM users WHERE username NOT IN ('admin');
-- DELETE FROM departments;
-- DELETE FROM shift_configs;

-- 2. DEPARTMENTS
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Phòng Giám đốc', 'Ban điều hành và chiến lược công ty', '2023-12-01 08:00:00', '2023-12-01 08:00:00'),
('Phòng Nhân sự (HR)', 'Quản lý nhân sự, tuyển dụng và tiền lương', '2023-12-01 08:00:00', '2023-12-01 08:00:00'),
('Phòng Kỹ thuật (IT)', 'Phát triển phần mềm và hạ tầng hệ thống', '2023-12-01 08:00:00', '2023-12-01 08:00:00'),
('Phòng Kinh doanh', 'Tiếp thị và bán hàng sản phẩm SmartOps', '2023-12-01 08:00:00', '2023-12-01 08:00:00'),
('Phòng Kế toán', 'Quản lý tài chính và thuế', '2023-12-01 08:00:00', '2023-12-01 08:00:00'),
('Phòng Sản xuất', 'Vận hành và sản xuất trực tiếp', '2023-12-01 08:00:00', '2023-12-01 08:00:00')
ON CONFLICT (name) DO NOTHING;

-- 3. SHIFT CONFIGURATIONS
INSERT INTO shift_configs (shift_name, start_time, end_time, late_threshold_minutes, is_active, location) VALUES
('Ca Hành chính', '08:00:00', '17:30:00', 15, true, 'Văn phòng chính'),
('Ca Sáng', '06:00:00', '14:00:00', 10, true, 'Nhà máy A'),
('Ca Chiều', '14:00:00', '22:00:00', 10, true, 'Nhà máy A'),
('Ca Đêm', '22:00:00', '06:00:00', 5, true, 'Nhà máy A')
ON CONFLICT DO NOTHING;

-- 4. USERS (Password is plain text '123456' as per NoOpPasswordEncoder)
-- Note: id might vary, usually safe to assume sequential if clean
INSERT INTO users (full_name, username, employee_code, email, phone_number, password, role, status, ekyc_status, department_id, assigned_shift_id, created_at) VALUES
('Nguyễn Văn Quản Trị', 'admin', 'ADM001', 'admin@smartops.com', '0901234567', '123456', 'ADMIN', 'ACTIVE', 'APPROVED', 1, 1, '2023-12-01 08:00:00'),
('Trần Thị Nhân Sự', 'hr_manager', 'HR001', 'hr@smartops.com', '0901234568', '123456', 'ADMIN', 'ACTIVE', 'APPROVED', 2, 1, '2023-12-05 08:00:00'),
('Lê Hoàng Nam', 'nam.lh', 'IT001', 'nam.lh@smartops.com', '0901234569', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 3, 1, '2024-01-10 09:00:00'),
('Phạm Minh Đức', 'duc.pm', 'IT002', 'duc.pm@smartops.com', '0901234570', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 3, 1, '2024-01-15 09:00:00'),
('Hoàng Thùy Linh', 'linh.ht', 'SAL001', 'linh.ht@smartops.com', '0901234571', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 4, 1, '2024-02-01 08:30:00'),
('Vũ Văn Hùng', 'hung.vv', 'PRO001', 'hung.vv@smartops.com', '0901234572', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 6, 2, '2024-03-01 06:00:00'),
('Đặng Thu Thảo', 'thao.dt', 'ACC001', 'thao.dt@smartops.com', '0901234573', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 5, 1, '2024-04-15 08:00:00'),
('Bùi Anh Tuấn', 'tuan.ba', 'PRO002', 'tuan.ba@smartops.com', '0901234574', '123456', 'EMPLOYEE', 'ACTIVE', 'PENDING', 6, 2, '2025-01-10 06:00:00'),
('Nguyễn Mai Phương', 'phuong.nm', 'SAL002', 'phuong.nm@smartops.com', '0901234575', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 4, 1, '2025-02-20 08:30:00'),
('Đỗ Hùng Dũng', 'dung.dh', 'IT003', 'dung.dh@smartops.com', '0901234576', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 3, 1, '2025-03-01 09:00:00')
ON CONFLICT (username) DO NOTHING;

-- 5. HISTORICAL ATTENDANCE LOGS (Past years - Random sampling)
-- We'll add some records for 2024 and 2025
-- For employee IT001 (Lê Hoàng Nam)
INSERT INTO attendance_logs (user_id, shift_id, check_in_time, check_out_time, status, location, verified_by_face)
SELECT 
    (SELECT id FROM users WHERE username = 'nam.lh'),
    1,
    d::timestamp + '07:50:00'::interval + (random() * '25 minutes'::interval),
    d::timestamp + '17:35:00'::interval + (random() * '20 minutes'::interval),
    CASE WHEN random() > 0.9 THEN 'LATE' ELSE 'ON_TIME' END,
    'Văn phòng chính',
    true
FROM generate_series('2024-01-15'::date, '2024-12-31'::date, '1 day'::interval) d
WHERE extract(dow from d) NOT IN (0, 6) -- Excluding Sunday and Saturday
  AND random() > 0.05; -- 5% chance of being absent

-- For employee PRO001 (Vũ Văn Hùng) - Factory worker (Ca Sáng)
INSERT INTO attendance_logs (user_id, shift_id, check_in_time, check_out_time, status, location, verified_by_face)
SELECT 
    (SELECT id FROM users WHERE username = 'hung.vv'),
    2,
    d::timestamp + '05:45:00'::interval + (random() * '20 minutes'::interval),
    d::timestamp + '14:05:00'::interval + (random() * '15 minutes'::interval),
    CASE WHEN random() > 0.85 THEN 'LATE' ELSE 'ON_TIME' END,
    'Nhà máy A',
    true
FROM generate_series('2024-03-01'::date, '2025-12-31'::date, '1 day'::interval) d
WHERE extract(dow from d) NOT IN (0) -- Factory workers work Saturday
  AND random() > 0.03;

-- 6. ATTENDANCE LOGS FOR 2026 (Recent months)
-- For all users in March 2026
INSERT INTO attendance_logs (user_id, shift_id, check_in_time, check_out_time, status, location, verified_by_face)
SELECT 
    u.id,
    u.assigned_shift_id,
    d::timestamp + (s.start_time - '10 minutes'::interval) + (random() * '20 minutes'::interval),
    d::timestamp + (s.end_time + '5 minutes'::interval) + (random() * '30 minutes'::interval),
    'ON_TIME', -- Will update later
    s.location,
    true
FROM users u
JOIN shift_configs s ON u.assigned_shift_id = s.id
CROSS JOIN generate_series('2026-03-01'::date, '2026-03-31'::date, '1 day'::interval) d
WHERE extract(dow from d) NOT IN (0, 6) AND u.role = 'EMPLOYEE' AND random() > 0.1;

-- Correct status for latecomers in March 2026
UPDATE attendance_logs 
SET status = 'LATE' 
WHERE check_in_time::time > (SELECT start_time + '15 minutes'::interval FROM shift_configs WHERE id = attendance_logs.shift_id)
  AND check_in_time >= '2026-03-01';

-- 7. LEAVE REQUESTS
INSERT INTO leave_requests (user_id, leave_type, start_date, end_date, reason, status, created_at) VALUES
((SELECT id FROM users WHERE username = 'nam.lh'), 'SICK', '2024-05-10', '2024-05-11', 'Sốt xuất huyết', 'APPROVED', '2024-05-09 10:00:00'),
((SELECT id FROM users WHERE username = 'linh.ht'), 'ANNUAL', '2024-08-15', '2024-08-20', 'Nghỉ hè gia đình', 'APPROVED', '2024-08-01 09:00:00'),
((SELECT id FROM users WHERE username = 'thao.dt'), 'PERSONAL', '2025-01-20', '2025-01-20', 'Việc gia đình riêng', 'APPROVED', '2025-01-18 14:00:00'),
((SELECT id FROM users WHERE username = 'duc.pm'), 'SICK', '2026-03-10', '2026-03-12', 'Đau mắt đỏ', 'APPROVED', '2026-03-09 08:30:00'),
((SELECT id FROM users WHERE username = 'phuong.nm'), 'ANNUAL', '2026-04-20', '2026-04-25', 'Đi du lịch nước ngoài', 'PENDING', '2026-04-10 16:00:00'),
((SELECT id FROM users WHERE username = 'hung.vv'), 'PERSONAL', '2026-04-26', '2026-04-26', 'Về quê có giỗ', 'PENDING', '2026-04-20 10:00:00');

-- 8. SHIFT CHANGE REQUESTS (If table exists)
-- Assuming the table exists based on the directory listing
-- INSERT INTO shift_change_requests ... (Skipping for now as structure wasn't fully checked, but similar to above)
