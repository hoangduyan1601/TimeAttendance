# KẾ HOẠCH CHI TIẾT: HỆ THỐNG ĐỊNH DANH EKYC VÀ CHẤM CÔNG CHỐNG GIAN LẬN

## 1. Mục tiêu
Xây dựng hệ thống định danh và chấm công thông minh, đảm bảo:
- **Tiện lợi:** Chấm công không tiếp xúc qua QR và Khuôn mặt.
- **Chính xác:** Xác thực đúng nhân sự đã được phê duyệt.
- **Bảo mật (Quan trọng):** Ngăn chặn tuyệt đối các hành vi gian lận như sử dụng ảnh chụp, video hoặc màn hình điện thoại của người khác để chấm công hộ (Anti-spoofing).

## 2. Phạm vi triển khai
- **Loại bỏ:** Tạm thời không yêu cầu chụp Căn cước công dân (CCCD) để tối giản quy trình cho nhân viên.
- **Tập trung:** Hoàn thiện luồng đăng ký khuôn mặt, phê duyệt của Admin và xác thực đa lớp tại Kiosk.

---

## 3. Quy trình chi tiết

### A. Đăng ký khuôn mặt (Phía Nhân viên)
1. **Chụp ảnh chân dung:** Nhân viên dùng Camera trước chụp ảnh nhìn thẳng rõ nét.
2. **Trích xuất Face Vector:** AI Service phân tích ảnh và chuyển đổi khuôn mặt thành dãy số định danh (Vector) duy nhất.
3. **Lưu trữ:** Dữ liệu ảnh và Vector được lưu trữ bảo mật trên server.
4. **Trạng thái:** Hồ sơ ở trạng thái `PENDING` và chờ Admin phê duyệt.

### B. Phê duyệt định danh (Phía Quản trị viên)
1. **Kiểm tra hồ sơ:** Admin truy cập danh sách chờ duyệt, xem ảnh gốc của nhân viên.
2. **Đối soát:** Xác nhận ảnh rõ nét, không bị che khuất và đúng là nhân sự trong công ty.
3. **Quyết định:** 
   - `APPROVED`: Nhân viên bắt đầu được phép chấm công.
   - `REJECTED`: Từ chối và yêu cầu nhân viên thực hiện lại.

### C. Quy trình Chấm công 3 lớp (Tại Kiosk)
Để đảm bảo tính trung thực, quy trình chấm công tại Kiosk được thực hiện qua 3 lớp:

1. **Lớp 1 - Định danh (QR Code):** 
   - Nhân viên quét mã QR cá nhân trên App.
   - Hệ thống xác định đây là ai và lấy dữ liệu khuôn mặt gốc để chuẩn bị đối soát.
2. **Lớp 2 - Xác thực thực thể (Liveness Detection - CHỐNG GIAN LẬN):**
   - AI quét các đặc điểm sống thực của đối tượng trước camera.
   - **Mục tiêu:** Phân biệt khuôn mặt thật với:
     - Ảnh in trên giấy.
     - Video/Ảnh hiển thị trên màn hình điện thoại/máy tính bảng.
     - Mặt nạ 3D hoặc các công cụ giả mạo khác.
   - Nếu phát hiện là vật thể tĩnh hoặc không có đặc điểm sống, hệ thống **từ chối lập tức** và báo lỗi "Phát hiện gian lận".
3. **Lớp 3 - Đối soát sinh trắc học (Face Matching):**
   - Chỉ khi vượt qua lớp Liveness, hệ thống mới so sánh ảnh live với Face Vector gốc.
   - Nếu tỷ lệ khớp >= 40% (ngưỡng an toàn VGG-Face), ghi nhận chấm công thành công.

---

## 4. Đặc tả kỹ thuật & Công nghệ

### Phân hệ AI (Python FastAPI)
- **Model chính:** `VGG-Face` (DeepFace).
- **Liveness Detection:** 
  - Sử dụng các kỹ thuật như: Phân tích tần suất (Frequency Analysis), Kiểm tra độ sâu (Depth Map/Texture analysis) hoặc yêu cầu hành động ngẫu nhiên (chớp mắt, quay đầu nhẹ).
- **Anti-Spoofing:** Tích hợp các bộ lọc để nhận diện ánh sáng phản chiếu từ màn hình điện thoại hoặc vân giấy in.

### Phân hệ Backend (Java Spring Boot)
- **Security:** Chặn mọi yêu cầu chấm công nếu tài khoản chưa ở trạng thái `APPROVED`.
- **Logic:** Xử lý tuần tự QR -> Liveness -> Matching. Chỉ lưu log khi cả 3 bước thành công.

### Phân hệ Frontend (Flutter)
- **Kiosk UI:** Hiển thị khung quét xanh/đỏ dựa trên kết quả liveness.
- **Employee App:** Dashboard theo dõi trạng thái "Đang chờ duyệt", "Đã duyệt" hoặc "Bị từ chối".

---

## 5. Lịch trình phát triển
1. **Tuần 1:** Hoàn thiện luồng Đăng ký và Phê duyệt Admin (Sửa lỗi 403 hiện tại).
2. **Tuần 2:** Tích hợp thư viện Liveness Detection vào AI Service.
3. **Tuần 3:** Cấu hình Kiosk thực hiện quét 2 bước (QR trước - Mặt sau).
4. **Tuần 4:** Kiểm thử khả năng chống gian lận với nhiều loại ảnh và màn hình khác nhau.
