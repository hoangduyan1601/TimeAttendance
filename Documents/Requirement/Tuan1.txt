I. BẢN MÔ TẢ CHI TIẾT CÁC CHỨC NĂNG CỦA ỨNG DỤNG (FUNCTIONAL SPECIFICATIONS)
Hệ thống quản lý chấm công SmartOps được thiết kế theo kiến trúc phân tán, bao gồm 4 nhóm chức năng chính phục vụ toàn diện quy trình kiểm soát hiện diện trong doanh nghiệp:

1. Nhóm chức năng dành cho Nhân viên (Employee Web Portal)
Được tối ưu hóa giao diện hiển thị trên trình duyệt của thiết bị di động.

Chức năng 1.1 - Đăng ký định danh điện tử (eKYC): Cho phép người dùng mới truy cập hệ thống lần đầu thực hiện quy trình xác thực danh tính. Người dùng cấp quyền sử dụng camera trên trình duyệt để chụp ảnh mặt trước Căn cước công dân và ảnh chân dung trực tiếp (Selfie). Hệ thống tự động thu thập và lưu trữ hình ảnh làm dữ liệu đối chiếu gốc.

Chức năng 1.2 - Khởi tạo Mã QR Động (Dynamic QR Code): Khi người dùng truy cập vào cổng thông tin, hệ thống tự động sinh ra một mã QR chứa chuỗi mã hóa định danh cá nhân (ID). Mã QR này được tích hợp bộ đếm thời gian và sẽ tự động làm mới chuỗi mã hóa sau mỗi 30 giây nhằm ngăn chặn triệt để hành vi chụp ảnh màn hình để nhờ người khác chấm công hộ.

Chức năng 1.3 - Tra cứu lịch sử chuyên cần cá nhân: Cung cấp giao diện bảng điều khiển cá nhân để người dùng xem lại chi tiết thời gian check-in/check-out của từng ngày làm việc, tổng số ngày công đã đạt, và thống kê các vi phạm như đi muộn hoặc về sớm trong tháng.

Chức năng 1.4 - Quản lý đơn từ và Nghỉ phép: Cho phép nhân viên tạo và gửi các loại đơn từ (nghỉ phép năm, nghỉ ốm, đi công tác) trực tiếp trên hệ thống. Nhân viên có thể theo dõi trạng thái phê duyệt của đơn (Chờ duyệt, Đã duyệt, Từ chối) và theo dõi quỹ ngày phép còn lại trong năm của mình.

2. Nhóm chức năng tại Trạm Kiosk (Kiosk Web Terminal)
Vận hành trên thiết bị màn hình lớn (Laptop/Tablet) đặt cố định tại lối ra vào.

Chức năng 2.1 - Chế độ quét chờ tự động (Continuous Standby): Trạm Kiosk duy trì luồng camera trực tiếp (Live Video Feed) 24/7. Hệ thống tự động nhận diện và quét các đối tượng đi vào khung hình mà không yêu cầu người dùng thao tác chạm hoặc bấm phím.

Chức năng 2.2 - Xác thực sinh trắc học kép 1:1: Quy trình nhận diện diễn ra đồng thời hai lớp. Lớp thứ nhất: Quét mã QR từ điện thoại nhân viên để xác định ID. Lớp thứ hai: Bóc tách khuôn mặt từ khung hình camera hiện tại và gửi yêu cầu xác thực về AI Server để đối chiếu độ trùng khớp với dữ liệu khuôn mặt gốc của ID vừa nhận.

Chức năng 2.3 - Phản hồi trực quan và âm thanh (Real-time Feedback): Ngay khi có kết quả đối chiếu, giao diện Kiosk lập tức hiển thị khung thông báo trạng thái: Xanh lá (Hợp lệ) kèm tên nhân viên, hoặc Đỏ (Cảnh báo gian lận/Không khớp mặt). Đồng thời phát ra âm thanh thông báo tương ứng để luân chuyển luồng người nhanh chóng.

Chức năng 2.4 - Hiển thị nhật ký trực tiếp (Live Log): Tại một phần của màn hình Kiosk, danh sách những cá nhân vừa thực hiện quét mã (bao gồm thời gian và trạng thái) sẽ được cập nhật và cuộn liên tục theo thời gian thực.

3. Nhóm chức năng Quản trị (Admin Dashboard)
Giao diện làm việc toàn cảnh trên máy tính dành cho bộ phận Hành chính/Nhân sự.

Chức năng 3.1 - Quản lý hồ sơ và Cơ cấu tổ chức: Cung cấp các công cụ CRUD (Thêm, Đọc, Sửa, Xóa) để quản lý danh sách phòng ban và thông tin chi tiết của từng nhân sự. Cho phép Quản trị viên phê duyệt hoặc từ chối các hồ sơ đăng ký eKYC mới.

Chức năng 3.2 - Thiết lập quy tắc ca làm việc (Shift Configuration): Giao diện cấu hình linh hoạt thời gian bắt đầu và kết thúc của các ca làm việc (ca sáng, ca chiều, ca hành chính). Hỗ trợ cài đặt thời gian châm chước (Grace Period) cho việc đi muộn.

Chức năng 3.3 - Bảng điều khiển giám sát trực tiếp (Real-time Monitor): Hiển thị các biểu đồ trực quan thống kê tổng quan sĩ số công ty trong ngày: Tổng số nhân sự, số lượng đã check-in, số lượng vắng mặt và đi muộn tính đến thời điểm hiện tại.

Chức năng 3.4 - Kết xuất báo cáo dữ liệu: Hỗ trợ tính năng lọc dữ liệu lịch sử chấm công theo mốc thời gian và phòng ban. Cho phép tải xuống (Export) bảng dữ liệu thô dưới định dạng .xlsx hoặc .csv để phục vụ công tác tính lương.

Chức năng 3.5 - Xét duyệt đơn từ (Leave Approval - MỚI): Cung cấp giao diện để Quản trị viên kiểm tra lý do và tiến hành phê duyệt hoặc từ chối các đơn xin nghỉ phép/công tác từ nhân viên gửi lên.

Chức năng 3.6 - Hiệu chỉnh chấm công thủ công (Manual Adjustment - MỚI): Cho phép Admin có quyền hạn chỉnh sửa tay nhật ký chấm công (thêm giờ in/out) trong các trường hợp ngoại lệ (Kiosk mất điện, nhân viên quên mang điện thoại). Mọi thao tác đều bắt buộc ghi chú lý do và được lưu vết (Audit Trail) để đảm bảo tính minh bạch.

4. Nhóm chức năng xử lý Hệ thống (Backend & AI Logic)
Các quy trình tự động hóa chạy ngầm trên Server.

Chức năng 4.1 - Mã hóa đặc trưng khuôn mặt (Face Embedding): Khi nhận ảnh eKYC, AI Microservice tự động trích xuất các điểm neo trên khuôn mặt và chuyển đổi thành một vector số học (128 chiều) để lưu trữ vào cơ sở dữ liệu thay vì lưu file ảnh tĩnh, đảm bảo tính bảo mật dữ liệu sinh trắc.

Chức năng 4.2 - Tự động phân loại trạng thái chuyên cần: Backend tự động so sánh mốc thời gian (Timestamp) thu thập từ Kiosk với cấu hình ca làm việc để gán nhãn trạng thái logic cho từng bản ghi ("Đúng giờ", "Đi muộn", "Vắng mặt").