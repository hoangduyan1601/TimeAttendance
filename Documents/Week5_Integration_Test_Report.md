# BÁO CÁO KIỂM THỬ TÍCH HỢP - TUẦN 5

**Dự án:** Hệ thống quản lý chấm công thông minh SmartOps
**Nhiệm vụ:** Tích hợp Frontend (Flutter) và Backend (Spring Boot & Python AI)
**Ngày thực hiện:** 07/04/2026

---

## I. TỔNG QUAN CÔNG VIỆC ĐÃ THỰC HIỆN

1. **Cấu hình môi trường:**
   - Cập nhật `pubspec.yaml` với các thư viện: `dio`, `shared_preferences`, `qr_flutter`, `image_picker`, v.v.
   - Thiết lập `ApiService` để giao tiếp với Backend thông qua REST API.
   - Xử lý xác thực bằng JWT Token và lưu trữ cục bộ.

2. **Tích hợp các chức năng chính:**
   - **Đăng nhập:** Chuyển từ hardcoded sang xác thực qua `/api/v1/auth/login`.
   - **QR Động (Nhân viên):** Fetch `qrToken` từ backend mỗi 30 giây và hiển thị bằng `QrImageView`.
   - **eKYC:** Chụp ảnh thật bằng `image_picker` và upload file qua Multipart tới backend.
   - **Xác thực Kiosk:** Gửi QR Token và ảnh Live Feed (Base64) tới backend để AI đối chiếu.
   - **Dashboard Admin:** Hiển thị sĩ số, đi muộn, vắng mặt theo dữ liệu thực tế từ database.

---

## II. KỊCH BẢN KIỂM THỬ (TEST SCENARIOS)

| STT | Chức năng | Kịch bản kiểm thử | Kết quả mong đợi | Trạng thái |
| :--- | :--- | :--- | :--- | :---: |
| 1 | Auth | Đăng nhập với tài khoản hợp lệ | Trả về JWT Token, chuyển hướng đúng Role (ADMIN/EMPLOYEE). | **PASS** |
| 2 | Auth | Đăng nhập với mật khẩu sai | Hiển thị thông báo lỗi "Unauthorized" hoặc "Sai mật khẩu". | **PASS** |
| 3 | Employee | Sinh mã QR Động | Mã QR thay đổi sau mỗi 30 giây, data khớp với token từ Backend. | **PASS** |
| 4 | Employee | Đăng ký eKYC | Upload thành công ảnh CCCD & Selfie, nhận code 201 Created. | **PASS** |
| 5 | Kiosk | Xác thực chấm công | Backend giải mã QR, AI so khớp mặt và trả về kết quả Hợp lệ/Từ chối. | **PASS** |
| 6 | Admin | Dashboard Stats | Các con số (Tổng số, Đã check-in) cập nhật đúng theo log trong DB. | **PASS** |

---

## III. KẾT QUẢ KIỂM THỬ CHI TIẾT

### 1. Kiểm thử Đăng nhập & Phân quyền
- **Input:** `username: anhdv`, `password: password123`
- **Output:** Login thành công, Token được lưu vào `SharedPreferences`.
- **UI:** Chuyển đến màn hình Employee Dashboard.

### 2. Kiểm thử QR Động
- **Hành động:** Truy cập màn hình Home nhân viên.
- **Kết quả:** `ApiService.getQrCode()` được gọi thành công. Timer đếm ngược 30s hoạt động. Khi hết thời gian, mã QR mới được fetch và cập nhật UI.

### 3. Kiểm thử eKYC
- **Hành động:** Chụp ảnh mặt trước CCCD và Selfie.
- **Kết quả:** `Dio` gửi Multipart request thành công. File được lưu trên server Backend và AI Microservice trích xuất được Vector khuôn mặt.

### 4. Kiểm thử Kiosk (Tích hợp AI)
- **Hành động:** Sử dụng nút mô phỏng trên Kiosk với QR Token hợp lệ.
- **Kết quả:** Backend gọi AI Service thành công. AI trả về `similarity_score > 0.8`. Kiosk hiển thị popup "XÁC THỰC THÀNH CÔNG" và lưu vào Live Log.

---

## IV. KẾT LUẬN
- Dự án đã hoàn thành đầy đủ yêu cầu tích hợp Frontend và Backend cho Tuần 5.
- Các luồng nghiệp vụ chính từ eKYC, Sinh mã QR đến Xác thực Kiosk đã chạy thông suốt giữa 3 phân hệ: Flutter App <-> Spring Boot Backend <-> FastAPI AI Server.
