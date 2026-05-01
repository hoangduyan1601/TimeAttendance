# HƯỚNG DẪN KIỂM THỬ API SMARTOPS (POSTMAN TEST CASES)

Tài liệu này cung cấp các kịch bản kiểm thử (Test Cases) và mã Script tự động để kiểm tra tính đúng đắn của các API trong hệ thống SmartOps.

---

## 1. CẤU HÌNH BIẾN MÔI TRƯỜNG (ENVIRONMENT VARIABLES)
Trước khi chạy, hãy tạo một Environment trong Postman và thêm các biến sau:
*   `base_url`: `http://localhost:8081/api/v1`
*   `jwt_token`: 
*   `admin_user`: `admin`
*   `admin_pass`: `123456`

---

## 2. DANH SÁCH CÁC KỊCH BẢN KIỂM THỬ

### 2.1. Xác thực Đăng nhập (Auth Login)
*   **URL:** `{{base_url}}/auth/login`
*   **Method:** `POST`
*   **Body (JSON):**
    ```json
    {
        "username": "{{admin_user}}",
        "password": "{{admin_pass}}"
    }
    ```
*   **Postman Tests (Tab Tests):**
    ```javascript
    pm.test("Status code is 200", function () {
        pm.response.to.have.status(200);
    });

    pm.test("Trả về Access Token", function () {
        var jsonData = pm.response.json();
        pm.expect(jsonData.data.accessToken).to.be.a('string');
        // Tự động lưu Token vào biến môi trường
        pm.environment.set("jwt_token", jsonData.data.accessToken);
    });
    ```

---

### 2.2. Lấy thống kê Dashboard (Admin Stats)
*   **URL:** `{{base_url}}/admin/dashboard/stats`
*   **Method:** `GET`
*   **Headers:** `Authorization: Bearer {{jwt_token}}`
*   **Postman Tests:**
    ```javascript
    pm.test("Xác thực Admin thành công", function () {
        pm.response.to.have.status(200);
    });

    pm.test("Dữ liệu thống kê đầy đủ", function () {
        var jsonData = pm.response.json();
        pm.expect(jsonData.data).to.have.property('totalEmployees');
        pm.expect(jsonData.data).to.have.property('presentToday');
    });
    ```

---

### 2.3. Đăng ký định danh eKYC (Multipart)
*   **URL:** `{{base_url}}/auth/ekyc`
*   **Method:** `POST`
*   **Body (form-data):**
    *   `id_card`: (Chọn file ảnh)
    *   `selfie`: (Chọn file ảnh)
*   **Postman Tests:**
    ```javascript
    pm.test("Gửi hồ sơ eKYC thành công", function () {
        pm.response.to.have.status(201);
        pm.expect(pm.response.json().message).to.contains("chờ Admin phê duyệt");
    });
    ```

---

### 2.4. Xác thực Kiosk (AI Verification)
*   **URL:** `{{base_url}}/kiosk/verify`
*   **Method:** `POST`
*   **Body (JSON):**
    ```json
    {
        "qrToken": "BASE64_QR_CODE_STRING",
        "liveImageBase64": "/9j/4AAQSkZJRg..."
    }
    ```
*   **Postman Tests:**
    ```javascript
    pm.test("Xác thực AI thành công", function () {
        pm.response.to.have.status(200);
        var data = pm.response.json().data;
        pm.expect(data.similarityScore).to.be.above(0.8);
    });
    ```

---

### 2.5. Tạo mới Nhân viên (User Management)
*   **URL:** `{{base_url}}/admin/users`
*   **Method:** `POST`
*   **Body (JSON):**
    ```json
    {
        "username": "test_user_01",
        "password": "password123",
        "fullName": "Nhân Viên Kiểm Thử",
        "email": "test@smartops.com",
        "role": "EMPLOYEE",
        "departmentId": 1
    }
    ```
*   **Postman Tests:**
    ```javascript
    pm.test("Tạo tài khoản thành công", function () {
        pm.response.to.have.status(200);
        pm.expect(pm.response.json().data.username).to.eql("test_user_01");
    });
    ```

---

## 3. KIỂM THỬ CÁC TRƯỜNG HỢP LỖI (NEGATIVE TESTS)

| API | Trường hợp | Kết quả mong đợi (Status Code) |
| :--- | :--- | :---: |
| Login | Sai mật khẩu | `401 Unauthorized` |
| Admin Stats | Không gửi Token | `403 Forbidden` |
| eKYC | Thiếu file ảnh | `400 Bad Request` |
| Create User | Trùng Username | `400 Bad Request` |

---
**Ghi chú:** Đối với các API yêu cầu Quyền Admin, hãy đảm bảo bạn đã Login bằng tài khoản có `role: ADMIN` trước khi thực hiện các bước tiếp theo.
