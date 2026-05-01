\# BÁO CÁO TUẦN 3: THIẾT KẾ BACKEND (API/FUNCTION)



\*\*Dự án:\*\* Hệ thống quản lý chấm công thông minh SmartOps

\*\*Kiến trúc:\*\* Microservices (Core Backend: Java Spring Boot | AI Service: Python FastAPI)



\---



\## I. DANH SÁCH TỔNG QUAN CÁC API/FUNCTION CHÍNH



Hệ thống được thiết kế theo chuẩn RESTful API, chia làm 2 phân hệ Microservices xử lý độc lập nhằm đảm bảo hiệu năng và tính bảo mật sinh trắc học.



\### 1. Phân hệ Core Backend (Xử lý nghiệp vụ chính - Java Spring Boot)



| STT | Phân hệ (Module) | Tên API | Method | Endpoint (URL) | Mục đích sử dụng | Giao diện tương ứng |

| :--- | :--- | :--- | :---: | :--- | :--- | :--- |

| 1 | \*\*Auth\*\* | Đăng nhập hệ thống | POST | `/api/v1/auth/login` | Xác thực người dùng, cấp phát JWT Token. | Màn hình Đăng nhập (Web/App) |

| 2 | \*\*Auth\*\* | Đăng ký eKYC | POST | `/api/v1/auth/ekyc` | Nhân viên upload ảnh CCCD \& Selfie để AI mã hóa khuôn mặt. | Màn hình Đăng ký eKYC (Employee) |

| 3 | \*\*Auth\*\* | Sinh mã QR Động | GET | `/api/v1/auth/qr-code` | Tạo mã QR chứa ID mã hóa, TTL 30 giây chống gian lận. | Dashboard (Employee) |

| 4 | \*\*Employee\*\* | Xem lịch sử cá nhân | GET | `/api/v1/employee/attendance` | Lấy danh sách lịch sử check-in/out và vi phạm của user đang đăng nhập. | Tra cứu lịch sử (Employee) |

| 5 | \*\*Employee\*\* | Gửi đơn từ | POST | `/api/v1/employee/leaves` | Nộp đơn xin nghỉ phép/công tác. | Quản lý đơn từ (Employee) |

| 6 | \*\*Kiosk\*\* | Xác thực chấm công | POST | `/api/v1/kiosk/verify` | Gửi QR và ảnh Live Frame để đối chiếu khuôn mặt kép 1:1. | Màn hình quét chờ (Kiosk) |

| 7 | \*\*Kiosk\*\* | Nhật ký trực tiếp | GET | `/api/v1/kiosk/live-logs` | Lấy danh sách nhân viên vừa quét thành công (Real-time). | Live Log (Kiosk) |

| 8 | \*\*Admin\*\* | Thống kê Dashboard | GET | `/api/v1/admin/dashboard/stats` | Đếm sĩ số, đi muộn, vắng mặt trong ngày hiện tại. | Dashboard Tổng quan (Admin) |

| 9 | \*\*Admin\*\* | Quản lý Nhân sự | GET/POST/PUT/DELETE | `/api/v1/admin/users` | Các thao tác CRUD (Thêm/Sửa/Xóa/DS) nhân viên. | Quản lý Nhân sự (Admin) |

| 10 | \*\*Admin\*\* | Phê duyệt eKYC | PUT | `/api/v1/admin/ekyc/{id}/review` | Duyệt/từ chối hồ sơ sinh trắc học mới của nhân viên. | Duyệt hồ sơ (Admin) |

| 11 | \*\*Admin\*\* | Cấu hình Ca làm | GET/POST/PUT/DELETE | `/api/v1/admin/shifts` | Thiết lập giờ làm việc và thời gian châm chước. | Thiết lập quy tắc (Admin) |

| 12 | \*\*Admin\*\* | Phê duyệt Đơn từ | PUT | `/api/v1/admin/leaves/{id}/review`| Chấp thuận hoặc từ chối đơn xin phép của nhân viên. | Xét duyệt đơn từ (Admin) |

| 13 | \*\*Admin\*\* | Hiệu chỉnh thủ công| POST | `/api/v1/admin/attendance/adjust`| Sửa giờ công (kèm lý do) khi có sự cố hệ thống. | Hiệu chỉnh dữ liệu (Admin) |

| 14 | \*\*Admin\*\* | Xuất báo cáo | GET | `/api/v1/admin/reports/export` | Kết xuất lịch sử ra file .xlsx hoặc .csv phục vụ tính lương. | Báo cáo \& Thống kê (Admin) |



\### 2. Phân hệ AI Microservice (Xử lý Sinh trắc học - Python FastAPI)

\*(Các API này chỉ chạy nội bộ trong mạng LAN, chỉ cho phép Core Backend gọi tới).\*



| STT | Tên API | Method | Endpoint (URL) | Mục đích sử dụng |

| :--- | :--- | :---: | :--- | :--- |

| 1 | Extract Vector | POST | `/internal/ai/embed` | Nhận ảnh khuôn mặt, trả về mảng Vector số học (128 chiều). |

| 2 | Compare Faces | POST | `/internal/ai/compare` | Nhận ảnh trực tiếp và Vector gốc, trả về tỷ lệ trùng khớp (%). |



\---



\## II. THIẾT KẾ CHI TIẾT TỪNG API/FUNCTION TRỌNG TÂM



\### 1. API Xác thực Đăng nhập (Authentication)

\* \*\*URL:\*\* `/api/v1/auth/login`

\* \*\*Method:\*\* `POST`

\* \*\*Mục đích:\*\* Xác thực thông tin người dùng và cấp phát chuỗi JWT Token.

\* \*\*Input (Request Body):\*\*

&#x20; ```json

&#x20; {

&#x20;   "username": "NV001",

&#x20;   "password": "hashed\_password"

&#x20; }

Output (Response 200 OK):



JSON

{

&#x20; "code": 200,

&#x20; "message": "Đăng nhập thành công",

&#x20; "data": {

&#x20;   "access\_token": "eyJhbGciOiJIUzI1NiIs...",

&#x20;   "token\_type": "Bearer",

&#x20;   "expires\_in": 86400,

&#x20;   "user": { "id": "uuid-123", "full\_name": "Hoàng Duy An", "role": "EMPLOYEE" }

&#x20; }

}

Database tác động: Đọc bảng users kiểm tra mật khẩu.



2\. API Đăng ký định danh sinh trắc (eKYC)

URL: /api/v1/auth/ekyc



Method: POST



Mục đích: Upload ảnh lên Firebase, gọi AI mã hóa khuôn mặt thành Vector và lưu DB.



Input (Multipart/Form-Data): \* file\_id\_card: \[File ảnh CCCD mặt trước]



file\_selfie: \[File ảnh chụp trực tiếp]



Output (Response 201 Created):



JSON

{

&#x20; "code": 201,

&#x20; "message": "Đã gửi hồ sơ eKYC. Vui lòng chờ Admin phê duyệt."

}

Database tác động: Cập nhật bảng users (đổi ekyc\_status = PENDING), ghi vào bảng face\_data.



3\. API Sinh mã QR Động (Dynamic QR Code)

URL: /api/v1/auth/qr-code



Method: GET



Mục đích: Sinh chuỗi mã hóa kết hợp User ID và Timestamp. Hạn sử dụng 30 giây.



Input: JWT Token trong Header.



Output (Response 200 OK):



JSON

{

&#x20; "code": 200,

&#x20; "data": {

&#x20;   "qr\_token": "U2FsdGVkX1+x8/abcxyz...",

&#x20;   "expires\_at": 1698765430

&#x20; }

}

Database tác động: Không truy vấn DB (Xử lý thuật toán AES trên Server).



4\. API Xác thực Kiosk (Trọng tâm hệ thống)

URL: /api/v1/kiosk/verify



Method: POST



Mục đích: Giải mã QR lấy ID, lấy Vector mặt gốc, so sánh với ảnh thực tế do Kiosk gửi lên.



Input (Request Body):



JSON

{

&#x20; "kiosk\_id": "K-GATE-01",

&#x20; "qr\_token": "U2FsdGVkX1+x8/abcxyz...",

&#x20; "live\_image\_base64": "data:image/jpeg;base64,/9j/4AAQSkZJR..."

}

Output (Response 200 OK - Hợp lệ):



JSON

{

&#x20; "code": 200,

&#x20; "message": "Chấm công thành công",

&#x20; "data": {

&#x20;   "employee\_name": "Hoàng Duy An",

&#x20;   "time": "07:45:00",

&#x20;   "attendance\_status": "ON\_TIME", 

&#x20;   "similarity\_score": 0.95

&#x20; }

}

Database tác động: Đọc bảng users, face\_data, shift\_configs. Ghi vào attendance\_logs.



5\. API Hiệu chỉnh chấm công thủ công (Manual Adjustment)

URL: /api/v1/admin/attendance/adjust



Method: POST



Mục đích: Dành cho Admin sửa giờ khi có sự cố. Bắt buộc lưu vết.



Input (Request Body):



JSON

{

&#x20; "user\_id": "uuid-456",

&#x20; "date": "2026-10-25",

&#x20; "new\_check\_in\_time": "08:00:00",

&#x20; "reason": "Mất điện trạm Kiosk số 1",

&#x20; "adjusted\_by": "admin-01"

}

Output (Response 200 OK):



JSON

{

&#x20; "code": 200,

&#x20; "message": "Đã cập nhật giờ chấm công thành công. Sự kiện đã được lưu vết."

}

Database tác động: Cập nhật attendance\_logs. Ghi mới vào audit\_logs.

