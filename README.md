# 🏢 SmartOps - Hệ thống Quản lý Chấm công Thông minh Doanh nghiệp
**Tên đề tài:** Nghiên cứu và xây dựng hệ thống Kiosk chấm công tự động phân tán ứng dụng Thị giác máy tính và đa nền tảng Web.

## 🌟 Giới thiệu tổng quan
SmartOps là giải pháp số hóa quy trình quản trị nhân sự, thay thế hoàn toàn máy chấm công vân tay truyền thống. Hệ thống cho phép nhận diện khuôn mặt và quét mã QR động theo thời gian thực tại các trạm Kiosk (Web-based), kết hợp với quy trình định danh điện tử (eKYC) dành cho nhân viên.

## 🛠 Công nghệ sử dụng (Tech Stack)
Hệ thống được thiết kế theo kiến trúc Microservices để đảm bảo hiệu năng và khả năng mở rộng:
* **Frontend (App & Kiosk):** Flutter Web & Dart (Responsive cho Mobile, Tablet, PC).
* **Core Backend (Business Logic):** Java (Spring Boot).
* **AI Microservice (Face Recognition):** Python (FastAPI), OpenCV, FaceNet/Dlib.
* **Database:** PostgreSQL (Quản lý dữ liệu quan hệ).
* **Cloud Storage:** Firebase Storage (Lưu trữ ảnh eKYC).

## 📂 Cấu trúc dự án (Repository Structure)
* `Documents/` : Chứa toàn bộ tài liệu dự án phân theo danh mục.
  * `API/` : Tài liệu đặc tả API (Tuần 3).
  * `DB/` : Sơ đồ cơ sở dữ liệu và script SQL.
  * `GUI design/` : Chứa các file ảnh thiết kế giao diện (Mockups).
  * `Requirement/` : Tài liệu đặc tả yêu cầu và báo cáo các tuần.
  * `UC/` : Use Case Diagram.
* `SourceCode/` : Nơi chứa mã nguồn chính.
  * `Frontend/` : Chứa source code Flutter.
  * `Backend/` : Chứa source code Java và Python.

## 👥 Danh sách thành viên và Đóng góp
| STT | Họ và Tên | Mã SV | Vai trò/Nhiệm vụ |
|:---:|:---|:---|:---|
| 1 | [Tên Trưởng nhóm] | [Mã SV 1] | Nhóm trưởng, Thiết kế DB & Code Core Backend Java |
| 2 | [Tên Thành viên 2] | [Mã SV 2] | Code Frontend Flutter & Thiết kế UI |
| 3 | [Tên Thành viên 3] | [Mã SV 3] | Code AI Python & Viết tài liệu kiểm thử |

## 📅 Tiến độ thực hiện (Weekly Progress)
*(Click vào các link bên dưới để xem chi tiết báo cáo từng giai đoạn)*
* [x] **Tuần 1:** [Mô tả chức năng & Phác thảo giao diện UI](./Documents/Requirement/Tuan1.md)
* [ ] **Tuần 2:** Xây dựng Frontend Flutter.
* [ ] **Tuần 3:** Thiết kế Backend (API/Function & Database).
* [ ] **Tuần 4:** Xây dựng Backend & Tích hợp AI.
* [ ] **Tuần 5:** Tích hợp hệ thống & Kiểm thử.