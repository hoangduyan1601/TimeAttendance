class ApiConstants {
  // Dùng '127.0.0.1' để tránh lỗi IPv6 trên trình duyệt Chrome (Windows)
  static const String baseUrl = 'http://127.0.0.1:9090/api/v1'; 
  
  static const String login = '$baseUrl/auth/login';
  static const String ekyc = '$baseUrl/auth/ekyc';
  static const String qrCode = '$baseUrl/auth/qr-code';
  static const String attendance = '$baseUrl/employee/attendance';
  static const String leave = '$baseUrl/employee/leaves';
  static const String kioskVerify = '$baseUrl/kiosk/verify';
  static const String liveLogs = '$baseUrl/kiosk/live-logs';
  static const String adminDashboard = '$baseUrl/admin/dashboard/stats';
  static const String adminPendingEkyc = '$baseUrl/admin/ekyc/pending';
  static String adminReviewEkyc(int userId) => '$baseUrl/admin/ekyc/$userId/review';
  static const String adminLeaves = '$baseUrl/admin/leaves';
  static String adminReviewLeave(int leaveId) => '$baseUrl/admin/leaves/$leaveId/review';
  static const String adminAttendance = '$baseUrl/admin/attendance';
  static const String adminExportReport = '$baseUrl/admin/reports/export';
  static const String adminUsers = '$baseUrl/admin/users';
  static const String resolveQr = '$baseUrl/kiosk/resolve-qr';
}
