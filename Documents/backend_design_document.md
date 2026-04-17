# BÁO CÁO TUẦN 3: THIẾT KẾ CHI TIẾT HỆ THỐNG BACKEND (API & FUNCTIONS)

**Dự án:** Hệ thống quản lý chấm công thông minh SmartOps
**Đối tượng báo cáo:** Thiết kế chi tiết phân hệ Core (Java Spring Boot) và AI Service (Python FastAPI)
**Ngày cập nhật:** 08/04/2026

---

## I. KIẾN TRÚC TỔNG QUỂ (ARCHITECTURE OVERVIEW)

Hệ thống được xây dựng theo kiến trúc **Microservices** hiện đại:
*   **SmartOps Core (Java Spring Boot):** Đóng vai trò là API Gateway và điều phối nghiệp vụ. Quản lý dữ liệu tập trung trên PostgreSQL.
*   **AI Service (Python FastAPI):** Chuyên trách xử lý hình ảnh và so khớp khuôn mặt sử dụng thư viện InsightFace/DeepFace. Kết nối với Core thông qua mạng nội bộ để đảm bảo an toàn dữ liệu sinh trắc học.
*   **Security:** Toàn bộ các API (trừ Login) đều được bảo vệ bởi **JWT (JSON Web Token)** với cơ chế phân quyền (Role-based Access Control).

---

## II. DANH SÁCH TỔNG QUAN CÁC API CHÍNH

| STT | Phân hệ | Tên API / Chức năng | Method | Endpoint (URL) | Mục đích sử dụng | Giao diện tương ứng |
| :--- | :--- | :--- | :---: | :--- | :--- | :--- |
| **1** | **Auth** | Đăng nhập hệ thống | POST | `/api/v1/auth/login` | Xác thực, cấp JWT Token. | Đăng nhập |
| **2** | **Auth** | Đăng ký eKYC | POST | `/api/v1/auth/ekyc` | Nhân viên gửi ảnh CCCD & Selfie. | Đăng ký eKYC |
| **3** | **Auth** | Sinh mã QR Động | GET | `/api/v1/auth/qr-code` | Tạo mã định danh tạm thời (30s). | Home (Employee) |
| **4** | **Kiosk** | Giải mã QR Kiosk | POST | `/api/v1/kiosk/resolve-qr` | Nhận diện User từ mã quét được. | Scan QR (Kiosk) |
| **5** | **Kiosk** | Xác thực AI | POST | `/api/v1/kiosk/verify` | So khớp khuôn mặt 1:1. | Chụp mặt (Kiosk) |
| **6** | **Kiosk** | Nhật ký trực tiếp | GET | `/api/v1/kiosk/live-logs` | Theo dõi traffic thời gian thực. | Live Log (Kiosk) |
| **7** | **Emp** | Lịch sử chấm công | GET | `/api/v1/employee/attendance` | Xem danh sách ngày công cá nhân. | Lịch sử (Employee) |
| **8** | **Emp** | Gửi đơn từ | POST | `/api/v1/employee/leaves` | Đăng ký nghỉ phép/công tác. | Đơn từ (Employee) |
| **9** | **Admin** | Dashboard Stats | GET | `/api/v1/admin/dashboard/stats` | Thống kê sĩ số, đi muộn toàn cty. | Dashboard (Admin) |
| **10** | **Admin** | Danh sách Nhân sự | GET | `/api/v1/admin/users` | Quản lý thông tin nhân viên. | Personnel (Admin) |
| **11** | **Admin** | Tạo mới Nhân sự | POST | `/api/v1/admin/users` | Thêm tài khoản nhân viên mới. | Add Employee (Admin) |
| **12** | **Admin** | DS eKYC chờ duyệt | GET | `/api/v1/admin/ekyc/pending` | Lấy các yêu cầu eKYC chưa xử lý. | Review eKYC (Admin) |
| **13** | **Admin** | Phê duyệt eKYC | PUT | `/api/v1/admin/ekyc/{id}/review` | Duyệt/Từ chối ảnh định danh. | Review eKYC (Admin) |
| **14** | **Admin** | Danh sách Đơn từ | GET | `/api/v1/admin/leaves` | Lấy toàn bộ đơn nghỉ của cty. | Requests (Admin) |
| **15** | **Admin** | Phê duyệt Đơn từ | PUT | `/api/v1/admin/leaves/{id}/review` | Chấp thuận/Bác bỏ đơn nghỉ. | Requests (Admin) |
| **16** | **Admin** | Cấu hình Ca làm | GET | `/api/v1/admin/shifts` | Xem danh sách các quy định ca. | Shifts (Admin) |
| **17** | **Admin** | Tạo Ca làm việc | POST | `/api/v1/admin/shifts` | Thiết lập giờ vào/ra, châm chước. | Add Shift (Admin) |
| **18** | **Admin** | Hiệu chỉnh công | POST | `/api/v1/admin/attendance/adjust` | Sửa lỗi giờ chấm công thủ công. | Adjust (Admin) |
| **19** | **Admin** | Xuất báo cáo Excel | GET | `/api/v1/admin/reports/export` | Tải báo cáo chuyên cần (.xlsx). | Reports (Admin) |
| **20** | **System** | Health Check | GET | `/health` | Giám sát trạng thái máy chủ. | Monitor System |

---

## III. THIẾT KẾ CHI TIẾT TỪNG API/FUNCTION (SPECIFICATIONS)

### 1. Nhóm Chức năng Xác thực & Định danh (Auth/eKYC)

#### 1.1. API Đăng ký định danh sinh trắc (eKYC)
*   **Endpoint:** `POST /api/v1/auth/ekyc`
*   **Input (Multipart/Form-data):**
    *   `id_card`: File (Ảnh CCCD mặt trước)
    *   `selfie`: File (Ảnh chân dung rõ mặt)
*   **Output (JSON):**
    ```json
    {
      "code": 201,
      "message": "Đã gửi hồ sơ eKYC thành công",
      "data": null
    }
    ```
*   **Logic xử lý:** 
    1. Lưu ảnh vào thư mục `uploads/ekyc/`.
    2. Gọi AI Service `/internal/ai/embed` để trích xuất Vector (128 chiều) từ ảnh Selfie.
    3. Lưu đường dẫn ảnh và Vector vào bảng `face_data`.
    4. Cập nhật `users.ekyc_status = 'PENDING'`.
*   **Database:** `face_data` (Insert/Update), `users` (Update status).

---

### 2. Nhóm Chức năng Kiosk (Chấm công thực địa)

#### 2.1. API Xác thực Kiosk (AI Verification)
*   **Endpoint:** `POST /api/v1/kiosk/verify`
*   **Input (JSON):**
    ```json
    {
      "qrToken": "string",
      "liveImageBase64": "string"
    }
    ```
*   **Output (JSON):**
    ```json
    {
      "code": 200,
      "data": {
        "employeeName": "Nguyễn Văn A",
        "attendanceStatus": "ON_TIME",
        "similarityScore": 0.98
      }
    }
    ```
*   **Logic xử lý:**
    1. Giải mã `qrToken` lấy `userId`.
    2. Lấy `face_vector` gốc của User từ Database.
    3. Gọi AI Service `/internal/ai/compare` để so khớp ảnh Live với Vector gốc.
    4. Nếu Match > 80%: Tính toán trạng thái (Đúng giờ/Muộn) dựa trên `shift_configs` và ghi Log.
*   **Database:** `attendance_logs` (Ghi mới), `users` & `face_data` (Truy vấn).

---

### 3. Nhóm Chức năng Quản trị (Admin Management)

#### 3.1. API Thống kê Dashboard
*   **Endpoint:** `GET /api/v1/admin/dashboard/stats`
*   **Input:** JWT Token (Admin Role).
*   **Output (JSON):**
    ```json
    {
      "totalEmployees": 150,
      "presentToday": 142,
      "lateToday": 5,
      "absentToday": 3,
      "pendingLeaveRequests": 12
    }
    ```
*   **Database:** Tổng hợp từ `users`, `attendance_logs` và `leave_requests`.

#### 3.2. API Phê duyệt eKYC (Admin Review)
*   **Endpoint:** `PUT /api/v1/admin/ekyc/{userId}/review`
*   **Input (JSON):**
    ```json
    { "status": "APPROVED" | "REJECTED" }
    ```
*   **Logic xử lý:** Cập nhật trạng thái định danh. Nếu `APPROVED`, nhân viên chính thức được phép dùng mặt để chấm công.
*   **Database:** `users.ekyc_status` (Update).

#### 3.3. API Cấu hình Ca làm việc
*   **Endpoint:** `POST /api/v1/admin/shifts`
*   **Input (JSON):**
    ```json
    {
      "shiftName": "Ca Sáng",
      "startTime": "08:00",
      "endTime": "12:00",
      "gracePeriod": 15
    }
    ```
*   **Database:** `shift_configs` (Ghi mới).

---

### 4. Nhóm Chức năng Nhân viên (Employee Features)

#### 4.1. API Tra cứu lịch sử cá nhân
*   **Endpoint:** `GET /api/v1/employee/attendance`
*   **Output:** Danh sách các bản ghi check-in kèm trạng thái và thời gian chi tiết.
*   **Database:** `attendance_logs` (Filter theo `userId`).

#### 4.2. API Gửi đơn từ nghỉ phép
*   **Endpoint:** `POST /api/v1/employee/leaves`
*   **Input:** Ngày bắt đầu, ngày kết thúc, loại nghỉ (Phép năm/Ốm), lý do.
*   **Database:** `leave_requests` (Ghi mới trạng thái `PENDING`).

---

## IV. DANH MỤC CÁC BẢNG DỮ LIỆU TÁC ĐỘNG (DATABASE SCHEMA)

Để hỗ trợ các Function trên, Backend tương tác với các thực thể chính sau:
1.  **users:** Lưu thông tin tài khoản, vai trò, phòng ban và trạng thái định danh (eKYC Status).
2.  **face_data:** Lưu trữ Face Vector (128 chiều) và đường dẫn ảnh (CCCD, Selfie).
3.  **attendance_logs:** Lưu vết toàn bộ sự kiện chấm công (vào/ra, thời gian, thiết bị, độ tin cậy AI).
4.  **leave_requests:** Lưu đơn xin nghỉ phép và vết phê duyệt của Admin.
5.  **shift_configs:** Lưu định nghĩa các ca làm việc (Giờ chuẩn, giờ giới hạn).
6.  **departments:** Quản lý cơ cấu tổ chức phòng ban.


