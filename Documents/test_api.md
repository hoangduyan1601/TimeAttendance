# Hướng dẫn Kiểm thử API Hệ thống TimeAttendance (SmartOps)

## 1. Thông tin chung
- **Core API Base URL:** `http://localhost:9090/api/v1`
- **AI Service Base URL:** `http://localhost:8000`
- **Xác thực:** Sử dụng Bearer Token trong Header `Authorization: Bearer {{token}}`.

---

## 2. Danh sách API và Cách Test Postman

### A. Nhóm Authentication (Xác thực & eKYC)
| Chức năng | Method | Endpoint | Body (JSON) / Params |
| :--- | :--- | :--- | :--- |
| **Đăng nhập** | POST | `/auth/login` | `{"username": "admin", "password": "123456"}` |
| **Đăng ký eKYC** | POST | `/auth/ekyc` | Form-data: `id_card` (file), `selfie` (file) |
| **Lấy mã QR cá nhân**| GET | `/auth/qr-code` | (Cần Token) |

**Câu lệnh Test Postman cho Login:**
- **URL:** `{{base_url}}/auth/login`
- **Script (Tests tab):**
```javascript
var jsonData = pm.response.json();
if (jsonData.status === "SUCCESS") {
    pm.environment.set("token", jsonData.data.token);
}
```

---

### B. Nhóm Admin - Quản lý Nhân sự (User Management)
*Lưu ý: Tất cả cần quyền ROLE_ADMIN*

| Chức năng | Method | Endpoint | Body (JSON) |
| :--- | :--- | :--- | :--- |
| **Tạo nhân viên** | POST | `/admin/users` | `{"username": "user1", "fullName": "Nguyễn Văn A", "email": "a@gmail.com", "role": "EMPLOYEE", "departmentId": 1}` |
| **Danh sách NV** | GET | `/admin/users` | |
| **Cập nhật NV** | PUT | `/admin/users/{id}` | `{"fullName": "Tên mới"}` |
| **Xóa NV** | DELETE | `/admin/users/{id}` | |

---

### B1. Nhóm Admin - Quản lý Phòng ban (Department)
| Chức năng | Method | Endpoint | Body (JSON) |
| :--- | :--- | :--- | :--- |
| **Danh sách PB** | GET | `/admin/departments` | |
| **Tạo phòng ban** | POST | `/admin/departments` | `{"name": "Phòng Kỹ thuật", "description": "Mô tả..."}` |
| **Cập nhật PB** | PUT | `/admin/departments/{id}` | `{"name": "Tên mới"}` |
| **Xóa phòng ban** | DELETE | `/admin/departments/{id}` | |

---

### C. Nhóm Admin - Quản lý Ca làm việc & Phê duyệt
| Chức năng | Method | Endpoint | Body / Params |
| :--- | :--- | :--- | :--- |
| **Tạo ca làm việc** | POST | `/admin/shifts` | `{"name": "Ca Sáng", "startTime": "08:00", "endTime": "12:00"}` |
| **Phân ca cho NV** | PUT | `/admin/users/{userId}/assign-shift` | Query param: `?shiftId=1` |
| **Duyệt eKYC** | PUT | `/admin/ekyc/{userId}/review` | `{"status": "APPROVED", "note": "OK"}` |
| **Duyệt đơn nghỉ** | PUT | `/admin/leaves/{id}/review` | `{"status": "APPROVED", "reason": "Duyệt"}` |
| **Báo cáo chấm công**| GET | `/admin/attendance` | Query: `?startDate=2024-01-01&endDate=2024-01-31` |
| **Xuất Excel** | GET | `/admin/reports/export` | Query: `?startDate=2024-01-01&endDate=2024-01-31` |

---

### D. Nhóm Employee (Dành cho Nhân viên)
| Chức năng | Method | Endpoint | Body (JSON) |
| :--- | :--- | :--- | :--- |
| **Thông tin cá nhân**| GET | `/employee/me` | |
| **Lịch sử chấm công**| GET | `/employee/attendance` | `?startDate=...&endDate=...` |
| **Gửi đơn nghỉ phép**| POST | `/employee/leave` | `{"leaveType": "ANNUAL", "fromDate": "2024-05-01", "toDate": "2024-05-02", "reason": "Nghỉ ốm"}` |
| **Gửi yêu cầu đổi ca**| POST | `/employee/shift-change`| `{"targetDate": "2024-05-05", "newShiftId": 2, "reason": "Việc riêng"}` |

---

### E. Nhóm Kiosk (Máy chấm công)
| Chức năng | Method | Endpoint | Body (JSON) |
| :--- | :--- | :--- | :--- |
| **Giải mã QR NV** | POST | `/kiosk/resolve-qr` | `{"qrToken": "xyz..."}` |
| **Chấm công (Verify)**| POST | `/kiosk/verify` | `{"userId": 1, "imageBase64": "data:image/jpeg;base64,...", "location": "Cổng chính"}` |
| **Nhật ký trực tiếp**| GET | `/kiosk/live-logs` | |

---

### F. AI Service (Nội bộ)
- **Base URL:** `http://localhost:8000`

| Chức năng | Method | Endpoint | Body |
| :--- | :--- | :--- | :--- |
| **Trích xuất Vector**| POST | `/internal/ai/embed` | Form-data: `file` (image) |
| **So sánh khuôn mặt**| POST | `/internal/ai/compare` | `{"storedVector": [...], "liveImageBase64": "..."}` |

---

## 3. Các bước test luồng chính (Workflow Test)
1. **Admin Login:** Lấy token admin.
2. **Tạo NV:** Sử dụng API `POST /admin/users`.
3. **NV Login:** Lấy token nhân viên.
4. **Đăng ký eKYC:** NV gửi ảnh chân dung qua `POST /auth/ekyc`.
5. **Admin Duyệt eKYC:** Admin gọi `PUT /admin/ekyc/{id}/review` với trạng thái `APPROVED`.
6. **NV lấy QR:** NV gọi `GET /auth/qr-code`.
7. **Kiosk Chấm công:** Gửi `qrToken` lên `POST /kiosk/resolve-qr` để lấy ID, sau đó gửi ảnh live lên `POST /kiosk/verify`.
