# KẾ HOẠCH TRIỂN KHAI HỆ THỐNG ĐỊNH DANH (EKYC) VÀ XÁC THỰC KHUÔN MẶT

## 1. Mục tiêu
Xây dựng quy trình định danh nhân sự khép kín, bảo mật và chính xác bằng công nghệ nhận diện khuôn mặt (Face Recognition). Đảm bảo nhân viên chỉ có thể chấm công khi đã được xác thực danh tính bởi hệ thống và phê duyệt bởi quản trị viên.

## 2. Phạm vi giai đoạn 1 (Hiện tại)
Tạm thời loại bỏ phần chụp và bóc tách dữ liệu CCCD để tập trung tối ưu hóa luồng xác thực khuôn mặt (Face-only eKYC) nhằm đảm bảo tính ổn định của Camera trên đa nền tảng.

---

## 3. Quy trình chi tiết

### A. Đăng ký khuôn mặt (Phía Nhân viên)
1. **Thực hiện chụp ảnh:** Nhân viên sử dụng Camera trước trên Mobile/Web để chụp ảnh chân dung (nhìn thẳng).
2. **Trích xuất đặc trưng (Face Embedding):** 
   - Ảnh được gửi lên AI Service (DeepFace - Model VGG-Face).
   - Hệ thống trích xuất ra một Vector 128 (hoặc 4096) chiều đại diện cho khuôn mặt.
3. **Lưu trữ:** 
   - Ảnh gốc được lưu tại thư mục `/uploads/ekyc/`.
   - Face Vector và đường dẫn ảnh được lưu vào bảng `face_data`.
4. **Trạng thái:** Hồ sơ chuyển sang trạng thái `PENDING` (Chờ phê duyệt).

### B. Phê duyệt định danh (Phía Quản trị viên)
1. **Danh sách chờ:** Admin xem danh sách nhân viên vừa đăng ký định danh.
2. **Đối soát thủ công:** Admin nhấn "Xem ảnh" để kiểm tra tính hợp lệ của ảnh (rõ nét, đúng người).
3. **Quyết định:**
   - **Duyệt (Approve):** Chuyển trạng thái eKYC thành `APPROVED`. Nhân viên chính thức có quyền chấm công.
   - **Từ chối (Reject):** Chuyển trạng thái thành `REJECTED`. Yêu cầu nhân viên chụp lại.

### C. Xác thực chấm công (Quy trình 2 bước tại Kiosk)
1. **Bước 1: Quét mã QR định danh (Identification):** 
   - Mỗi nhân viên được cấp một mã QR định danh duy nhất trên ứng dụng di động.
   - Nhân viên đưa mã QR vào vùng nhận diện của camera Kiosk.
   - Hệ thống giải mã QR để xác định danh tính nhân viên và truy xuất **Face Vector** gốc tương ứng từ cơ sở dữ liệu.
2. **Bước 2: Xác thực khuôn mặt (Verification):** 
   - Ngay sau khi nhận diện được nhân viên qua QR, Kiosk tự động kích hoạt chế độ chụp ảnh khuôn mặt.
   - Camera chụp ảnh thực tế của người đang đứng trước máy (Live Image).
3. **So khớp và Đối soát AI:**
   - Hệ thống AI so sánh ảnh vừa chụp với Face Vector gốc đã lấy được ở Bước 1.
   - Sử dụng thuật toán **Cosine Similarity** để tính toán tỷ lệ tương đồng.
4. **Kết quả chấm công:**
   - **Thành công:** Nếu tỷ lệ khớp đạt ngưỡng an toàn (>= 40%), hệ thống tự động ghi nhận giờ vào/ra ca và hiển thị thông báo chào mừng kèm tên nhân viên.
   - **Thất bại:** Nếu tỷ lệ khớp thấp hoặc tài khoản chưa được Admin duyệt định danh, hệ thống sẽ từ chối chấm công và hiển thị cảnh báo lỗi chi tiết.

---

## 4. Đặc tả kỹ thuật

### Phân hệ AI (Python FastAPI)
- **Thư viện:** DeepFace, OpenCV, TensorFlow.
- **Model:** `VGG-Face` (Độ chính xác cao với ảnh từ Webcam/Mobile).
- **Endpoints:**
  - `/internal/ai/embed`: Trích xuất Vector từ ảnh.
  - `/internal/ai/compare`: So sánh ảnh trực tiếp với Vector lưu sẵn.

### Phân hệ Backend (Java Spring Boot)
- **Dữ liệu:** Quản lý bảng `users` (trạng thái ekyc) và `face_data` (vector, url ảnh).
- **Bảo mật:** 
  - Cấu hình Resource Handler cho phép truy cập ảnh định danh qua URL bảo mật.
  - Tích hợp điều kiện `ekyc_status == 'APPROVED'` vào logic chấm công.

### Phân hệ Frontend (Flutter)
- **Giao diện chụp ảnh:** Tối ưu hóa 1 bước chụp để tránh treo camera.
- **Theo dõi trạng thái:** Hiển thị Dashboard định danh cho nhân viên (Chờ duyệt/Thành công/Từ chối).
- **Kiosk UI:** Hiển thị độ khớp (%) và phản hồi real-time từ AI.

---

## 5. Lộ trình phát triển tiếp theo (Giai đoạn 2)
1. **Liveness Detection:** Thêm các yêu cầu như chớp mắt, mỉm cười hoặc quay đầu để chống giả mạo bằng ảnh tĩnh.
2. **Tích hợp OCR CCCD:** Chụp mặt trước/sau CCCD, tự động trích xuất thông tin và so khớp khuôn mặt trên CCCD với ảnh Selfie.
3. **Cảnh báo Admin:** Tự động gửi thông báo khi có yêu cầu eKYC mới hoặc khi có người cố tình chấm công sai khuôn mặt nhiều lần.
