# SmartOps - Hệ thống Quản lý Chấm công Thông minh (Backend)

Dự án này là phân hệ Backend của hệ thống SmartOps, được xây dựng theo kiến trúc Microservices để đảm bảo tính mở rộng và hiệu năng xử lý sinh trắc học.

---

## 🏗 Kiến trúc Hệ thống

Hệ thống bao gồm 2 dịch vụ chính:
1.  **Core API (Java Spring Boot):** Xử lý nghiệp vụ chính, quản lý nhân sự, ca làm việc, chấm công và xuất báo cáo. Chạy tại cổng `8081`.
2.  **AI Microservice (Python FastAPI):** Xử lý nhận diện khuôn mặt, trích xuất vector 128D (Facenet) và so sánh độ tương đồng. Chạy tại cổng `8000`.

---

## 🛠 Yêu cầu Hệ thống

-   **Java:** JDK 17+
-   **Python:** 3.12+ (hỗ trợ Windows/Linux)
-   **Database:** PostgreSQL 14+
-   **Build Tool:** Maven (sử dụng `./mvnw`)

---

## 🚀 Hướng dẫn Cài đặt & Chạy

### 1. Phân hệ AI Microservice (Python)
```powershell
cd ai_service
# Tạo môi trường ảo (nếu chưa có)
python -m venv venv
# Kích hoạt môi trường ảo
.\venv\Scripts\activate
# Cài đặt thư viện
pip install -r requirements.txt
# Chạy Server
python main.py
```
*Lưu ý: Lần đầu chạy sẽ tự tải model Facenet (~90MB).*

### 2. Phân hệ Core API (Java)
1.  **Cấu hình Database:** Cập nhật `src/main/resources/application.yml` với thông tin PostgreSQL của bạn.
2.  **Khởi tạo Database:** Chạy các script SQL cần thiết để tạo bảng và dữ liệu mẫu.
3.  **Chạy Server:**
    ```powershell
    cd core_api
    .\mvnw clean spring-boot:run
    ```

---

## 🧪 Kiểm thử (Testing)

Bạn có thể sử dụng script Python có sẵn để kiểm tra toàn bộ luồng Backend:
```powershell
cd core_api
python test_full_backend.py
```
**Luồng kiểm thử:** Login -> Đăng ký eKYC -> Sinh mã QR -> Chấm công Kiosk -> Thống kê Admin.

---

## 📂 Cấu trúc thư mục chính
-   `core_api/`: Mã nguồn Spring Boot (Java).
-   `ai_service/`: Mã nguồn FastAPI (Python).
-   `core_api/uploads/`: Thư mục lưu trữ ảnh eKYC cục bộ (đã cấu hình Static Resource).

---

## 📝 Danh sách API chính
| Phân hệ | Endpoint | Method | Mô tả |
| :--- | :--- | :--- | :--- |
| Auth | `/api/v1/auth/login` | POST | Đăng nhập & cấp JWT |
| Auth | `/api/v1/auth/ekyc` | POST | Đăng ký sinh trắc học |
| Kiosk | `/api/v1/kiosk/verify` | POST | Xác thực chấm công AI |
| Admin | `/api/v1/admin/dashboard/stats` | GET | Thống kê sĩ số trong ngày |
| Admin | `/api/v1/admin/reports/export` | GET | Xuất báo cáo Excel |

---
**Nhóm thực hiện:** Tuần 4 - Xây dựng Backend.
