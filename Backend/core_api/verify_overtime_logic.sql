-- ========================================================
-- TEST SCRIPT FOR OVERTIME CAPPING LOGIC
-- ========================================================

-- 1. Chuẩn bị dữ liệu nhân viên (Lấy từ seed_data: nam.lh id=3, duc.pm id=4, shift_id=1)
-- Giả sử ID 3 là Nam, ID 4 là Đức. Giờ tan ca chuẩn là 17:30:00.

-- Xóa dữ liệu cũ của ngày hôm nay để test
DELETE FROM attendance_logs WHERE check_in_time >= CURRENT_DATE;
DELETE FROM overtime_requests WHERE date = CURRENT_DATE;

-- 2. Tạo đơn OT được duyệt cho Nam (ID 3), Đức (ID 4) KHÔNG có đơn.
INSERT INTO overtime_requests (user_id, date, start_time, end_time, reason, status, created_at)
VALUES (3, CURRENT_DATE, '17:30:00', '20:00:00', 'Test OT Approved', 'APPROVED', CURRENT_TIMESTAMP);

-- 3. Giả lập Check-in sáng nay cho cả 2
INSERT INTO attendance_logs (user_id, shift_id, check_in_time, status, location, verified_by_face)
VALUES (3, 1, CURRENT_DATE + TIME '08:00:00', 'ON_TIME', 'Office', true),
       (4, 1, CURRENT_DATE + TIME '08:00:00', 'ON_TIME', 'Office', true);

-- 4. Giả lập Check-out lúc 21:00 (Muộn hơn cả giờ OT đã xin)
-- Ở đây ta thực hiện logic UPDATE tương đương với AttendanceServiceImpl.verify()
-- Đối với Nam (ID 3): Có đơn OT đến 20:00 -> Giờ về bị CAP tại 20:00
UPDATE attendance_logs 
SET check_out_time = CASE 
    WHEN (SELECT COUNT(*) FROM overtime_requests o WHERE o.user_id = 3 AND o.date = CURRENT_DATE AND o.status = 'APPROVED') > 0
    THEN (CURRENT_DATE + TIME '20:00:00') -- Lấy Max OT Time
    ELSE (CURRENT_DATE + TIME '17:30:00') -- Giờ kết thúc ca
END,
status = 'CHECK_OUT_TEST_OT'
WHERE user_id = 3 AND check_in_time >= CURRENT_DATE;

-- Đối với Đức (ID 4): KHÔNG có đơn OT -> Giờ về bị CAP tại 17:30
UPDATE attendance_logs 
SET check_out_time = CASE 
    WHEN (SELECT COUNT(*) FROM overtime_requests o WHERE o.user_id = 4 AND o.date = CURRENT_DATE AND o.status = 'APPROVED') > 0
    THEN (CURRENT_DATE + TIME '20:00:00')
    ELSE (CURRENT_DATE + TIME '17:30:00') -- Chốt chặn tại đây
END,
status = 'CHECK_OUT_TEST_NO_OT'
WHERE user_id = 4 AND check_in_time >= CURRENT_DATE;

-- 5. HIỂN THỊ KẾT QUẢ ĐỂ KIỂM TRA
SELECT 
    u.full_name, 
    a.check_in_time, 
    a.check_out_time, 
    a.status,
    (CASE WHEN o.status = 'APPROVED' THEN 'CÓ ĐƠN OT' ELSE 'KHÔNG CÓ OT' END) as ot_status
FROM users u
JOIN attendance_logs a ON u.id = a.user_id
LEFT JOIN overtime_requests o ON u.id = o.user_id AND o.date = CURRENT_DATE
WHERE a.check_in_time >= CURRENT_DATE;
