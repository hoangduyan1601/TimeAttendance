-- ========================================================
-- SEED DATA FOR SMARTOPS - 100% COMPATIBLE & RICH DATA
-- Target Month: April 2026 (Full month simulation)
-- ========================================================

-- 1. CLEANUP
TRUNCATE attendance_logs, leave_requests, shift_change_requests, users, shift_configs, departments RESTART IDENTITY CASCADE;

-- 2. DEPARTMENTS
INSERT INTO departments (name, description) VALUES ('Ban Giam doc', 'Lanh dao');
INSERT INTO departments (name, description) VALUES ('Phong Nhan su', 'HR');
INSERT INTO departments (name, description) VALUES ('Phong IT', 'Ky thuat');
INSERT INTO departments (name, description) VALUES ('Phong Kinh doanh', 'Sales');
INSERT INTO departments (name, description) VALUES ('Phong Ke toan', 'Finance');
INSERT INTO departments (name, description) VALUES ('Phong San xuat', 'Factory');

-- 3. SHIFT CONFIGS
INSERT INTO shift_configs (shift_name, start_time, end_time, late_threshold_minutes, is_active) VALUES ('Hanh chinh', '08:00:00', '17:30:00', 15, true);
INSERT INTO shift_configs (shift_name, start_time, end_time, late_threshold_minutes, is_active) VALUES ('Ca Sang', '06:00:00', '14:00:00', 10, true);

-- 4. USERS (Mật khẩu là '123456' được mã hóa bằng NoOp hoặc Bcrypt tùy config, ở đây giả định NoOp theo logs trước)
-- Sẽ sử dụng ID tự tăng, chúng ta sẽ tham chiếu bằng username trong các lệnh sau
INSERT INTO users (full_name, username, employee_code, email, password, role, status, ekyc_status, department_id, assigned_shift_id) VALUES 
('Nguyen Van Quan Tri', 'admin', 'ADM001', 'admin@smartops.com', '123456', 'ADMIN', 'ACTIVE', 'APPROVED', 1, 1),
('Tran Thi Nhan Su', 'hr_manager', 'HR001', 'hr@smartops.com', '123456', 'ADMIN', 'ACTIVE', 'APPROVED', 2, 1),
('Le Hoang Nam', 'nam.lh', 'IT001', 'nam.lh@smartops.com', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 3, 1),
('Pham Minh Duc', 'duc.pm', 'IT002', 'duc.pm@smartops.com', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 3, 1),
('Hoang Thuy Linh', 'linh.ht', 'SAL001', 'linh.ht@smartops.com', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 4, 1),
('Vu Van Hung', 'hung.vv', 'PRO001', 'hung.vv@smartops.com', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 6, 2),
('Dang Thu Thao', 'thao.dt', 'ACC001', 'thao.dt@smartops.com', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 5, 1),
('Bui Anh Tuan', 'tuan.ba', 'PRO002', 'tuan.ba@smartops.com', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 6, 2),
('Nguyen Mai Phuong', 'phuong.nm', 'SAL002', 'phuong.nm@smartops.com', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 4, 1),
('Do Hung Dung', 'dung.dh', 'IT003', 'dung.dh@smartops.com', '123456', 'EMPLOYEE', 'ACTIVE', 'APPROVED', 3, 1);

-- 5. RICH ATTENDANCE LOGS (Sử dụng subquery để lấy user_id và shift_id cho chính xác)
-- NV Nam (IT001) - ~18 ngày
INSERT INTO attendance_logs (user_id, shift_id, check_in_time, check_out_time, status) 
SELECT (SELECT id FROM users WHERE username='nam.lh'), 1, d + '07:55:00'::time, d + '17:35:00'::time, 'ON_TIME' FROM generate_series('2026-04-01'::date, '2026-04-24'::date, '1 day'::interval) d WHERE extract(dow from d) NOT IN (0, 6);

-- NV Duc (IT002) - ~18 ngày (Hay đi muộn)
INSERT INTO attendance_logs (user_id, shift_id, check_in_time, check_out_time, status) 
SELECT (SELECT id FROM users WHERE username='duc.pm'), 1, d + '08:25:00'::time, d + '17:40:00'::time, 'LATE' FROM generate_series('2026-04-01'::date, '2026-04-24'::date, '1 day'::interval) d WHERE extract(dow from d) NOT IN (0, 6);

-- NV Linh (SAL001) - ~18 ngày
INSERT INTO attendance_logs (user_id, shift_id, check_in_time, check_out_time, status) 
SELECT (SELECT id FROM users WHERE username='linh.ht'), 1, d + '07:50:00'::time, d + '17:30:00'::time, 'ON_TIME' FROM generate_series('2026-04-01'::date, '2026-04-24'::date, '1 day'::interval) d WHERE extract(dow from d) NOT IN (0, 6);

-- NV Hung (PRO001) - ~20 ngày (Làm cả Thứ 7)
INSERT INTO attendance_logs (user_id, shift_id, check_in_time, check_out_time, status) 
SELECT (SELECT id FROM users WHERE username='hung.vv'), 2, d + '05:55:00'::time, d + '14:05:00'::time, 'ON_TIME' FROM generate_series('2026-04-01'::date, '2026-04-24'::date, '1 day'::interval) d WHERE extract(dow from d) NOT IN (0);

-- Các NV còn lại (Dùng Subquery cho ID)
INSERT INTO attendance_logs (user_id, shift_id, check_in_time, check_out_time, status)
SELECT u.id, u.assigned_shift_id, d + '08:00:00'::time, d + '17:30:00'::time, 'ON_TIME'
FROM users u CROSS JOIN generate_series('2026-04-01'::date, '2026-04-24'::date, '1 day'::interval) d
WHERE u.id > 6 AND extract(dow from d) NOT IN (0);

-- 6. LEAVE REQUESTS
INSERT INTO leave_requests (user_id, leave_type, start_date, end_date, reason, status) 
VALUES ((SELECT id FROM users WHERE username='linh.ht'), 'ANNUAL', '2026-04-10', '2026-04-12', 'Nghi phep nam', 'APPROVED');

-- 7. TODAY LOGS (April 25, 2026) - Incomplete check-outs
INSERT INTO attendance_logs (user_id, shift_id, check_in_time, status) VALUES ((SELECT id FROM users WHERE username='admin'), 1, '2026-04-25 08:00:00', 'ON_TIME');
INSERT INTO attendance_logs (user_id, shift_id, check_in_time, status) VALUES ((SELECT id FROM users WHERE username='nam.lh'), 1, '2026-04-25 07:55:00', 'ON_TIME');
INSERT INTO attendance_logs (user_id, shift_id, check_in_time, status) VALUES ((SELECT id FROM users WHERE username='duc.pm'), 1, '2026-04-25 08:45:00', 'LATE');
