# 🚀 Hướng dẫn Triển khai & Bàn giao Hệ thống SmartOps

Tài liệu này hướng dẫn chi tiết cách thiết lập, vận hành và bàn giao hệ thống quản lý chấm công thông minh SmartOps.

---

## 🏗 1. Cấu hình Môi trường (Environment Setup)

### A. Cơ sở dữ liệu (PostgreSQL)
1. **Cài đặt**: PostgreSQL 13+.
2. **Khởi tạo**: Tạo database tên `smartops_db`.
3. **Cấu hình**: Chỉnh sửa file `Backend/core_api/src/main/resources/application.yml`:
   ```yaml
   spring:
     datasource:
       url: jdbc:postgresql://127.0.0.1:5433/smartops_db
       username: postgres
       password: <your_password>
   ```
4. **Data Seed**: Hệ thống tự động chạy `seed_data.sql` khi khởi động lần đầu (nếu để `ddl-auto: update`).

### B. AI Microservice (Python)
1. **Yêu cầu**: Python 3.9 - 3.11.
2. **Cài đặt thư viện**:
   ```bash
   cd Backend/ai_service
   python -m venv venv
   .\venv\Scripts\activate
   pip install -r requirements.txt
   ```
3. **Chạy dịch vụ**: `python main.py` (Mặc định chạy tại port 8080).

### C. Core Backend (Java Spring Boot)
1. **Yêu cầu**: JDK 17, Maven.
2. **Chạy dịch vụ**:
   ```bash
   cd Backend/core_api
   ./mvnw spring-boot:run
   ```
   (Mặc định chạy tại port 9090).

### D. Frontend (Flutter)
1. **Yêu cầu**: Flutter SDK mới nhất.
2. **Cấu hình API**: Chỉnh sửa `Frontend/smartops_app/lib/core/constants.dart` để trỏ về IP của Server Backend.
3. **Build**:
   - Web: `flutter build web`
   - Android: `flutter build apk`

---

## 🛠 2. Quy trình Vận hành Thực tế (Operational Flow)

### Bước 1: Khởi tạo dữ liệu Admin
- Sử dụng tài khoản mặc định: `admin` / `123456`.
- Tạo các **Phòng ban** (Departments) và **Ca làm việc** (Shifts) trong menu Admin.

### Bước 2: Đăng ký Nhân sự (eKYC)
1. Tạo tài khoản nhân viên mới trong quản lý nhân sự.
2. Nhân viên đăng nhập trên App Mobile.
3. Chụp ảnh CCCD và Selfie để đăng ký eKYC.
4. **Admin phê duyệt**: Vào mục "Duyệt eKYC" trên Dashboard Admin để xác nhận (Bắt buộc).

### Bước 3: Chấm công tại Kiosk
1. Mở giao diện Kiosk trên trình duyệt tại máy tính/tablet đặt ở cửa.
2. Nhân viên đưa mã QR trên App Mobile vào vùng quét.
3. Thực hiện thử thách sống thực (Nháy mắt/Quay mặt sang trái hoặc phải) theo yêu cầu tiếng Việt của Kiosk.
4. Hệ thống hiển thị "ACCESS GRANTED" (hoặc thông báo thành công) và lưu log.

---

## 📱 3. Yêu cầu Phần cứng Khuyến nghị

| Thiết bị | Cấu hình tối thiểu | Ghi chú |
| :--- | :--- | :--- |
| **Server AI** | CPU 4 Cores, 8GB RAM, GPU (tùy chọn) | Càng mạnh thì tốc độ nhận diện càng nhanh (< 1s). |
| **Trạm Kiosk** | Tablet hoặc Laptop có Camera HD (720p) | Cần kết nối Internet ổn định. |
| **App Mobile** | Android 8.0+ hoặc iOS 12+ | Camera đủ rõ để chụp CCCD. |

---

## 📂 4. Danh mục Bàn giao (Deliverables)

1. **Mã nguồn**: Toàn bộ folder `SourceCode/`.
2. **Tài liệu**:
   - `Documents/API/`: Đặc tả API chi tiết.
   - `Documents/DB/`: Sơ đồ cơ sở dữ liệu.
   - `Deployment_and_Handover_Guide.md`: Hướng dẫn này.
3. **Báo cáo**: Kết quả kiểm thử tích hợp tuần 5.

---

## 📞 5. Hỗ trợ Kỹ thuật
- **Người liên hệ**: [Tên của bạn/Trưởng nhóm]
- **Email**: [Email liên hệ]
- **Bảo trì**: Hệ thống có cơ chế Log tại `Backend/core_api/logs/` để kiểm tra lỗi khi vận hành.
