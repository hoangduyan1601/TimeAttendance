import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartops_app/core/theme.dart';
import 'package:smartops_app/services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  int _selectedIndex = 0;
  
  Map<String, dynamic>? _stats;
  List<dynamic> _liveLogs = [];
  List<dynamic> _pendingEkyc = [];
  List<dynamic> _allUsers = [];
  List<dynamic> _allLeaves = [];
  List<dynamic> _allShiftChangeRequests = [];
  List<dynamic> _departments = [];
  List<dynamic> _allShifts = [];
  List<dynamic> _attendanceReports = [];
  String _reportFilter = 'TODAY'; // TODAY, WEEK, MONTH
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      String start = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String end = start;
      if (_reportFilter == 'WEEK') {
        start = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 7)));
      } else if (_reportFilter == 'MONTH') {
        start = DateFormat('yyyy-MM-dd').format(DateTime(DateTime.now().year, DateTime.now().month, 1));
      }

      final results = await Future.wait([
        _apiService.getAdminStats(),
        _apiService.getLiveLogs(),
        _apiService.getPendingEkyc(),
        _apiService.getAllUsers(),
        _apiService.getAllLeaves(),
        _apiService.getDepartments(),
        _apiService.getAttendanceReports(start, end),
        _apiService.getAllShifts(),
        _apiService.getAllShiftChangeRequests(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0]['data'];
          _liveLogs = results[1]['data'] ?? [];
          _pendingEkyc = results[2]['data'] ?? [];
          _allUsers = results[3]['data'] ?? [];
          _allLeaves = results[4]['data'] ?? [];
          _departments = results[5]['data'] ?? [];
          _attendanceReports = results[6]['data'] ?? [];
          _allShifts = results[7]['data'] ?? [];
          _allShiftChangeRequests = results[8]['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshShifts() async {
    try {
      final response = await _apiService.getAllShifts();
      if (mounted) {
        setState(() {
          _allShifts = response['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error refreshing shifts: $e");
    }
  }

  Future<void> _refreshDepartments() async {
    try {
      final deptResponse = await _apiService.getDepartments();
      if (mounted) {
        setState(() {
          _departments = deptResponse['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error refreshing departments: $e");
    }
  }

  void _showAddEmployeeDialog() {
    final _formKey = GlobalKey<FormState>();
    final _userController = TextEditingController();
    final _passController = TextEditingController();
    final _emailController = TextEditingController();
    final _nameController = TextEditingController();
    final _phoneController = TextEditingController();
    String _selectedRole = 'EMPLOYEE';
    dynamic _selectedDept;
    dynamic _selectedShift;

    if (_departments.isNotEmpty) _selectedDept = _departments.first['id'];
    if (_allShifts.isNotEmpty) _selectedShift = _allShifts.first['id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          title: Text('Thêm Nhân viên mới', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _userController,
                    decoration: const InputDecoration(labelText: 'Tên đăng nhập', hintText: 'VD: nv001'),
                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passController,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    obscureText: true,
                    validator: (v) => v!.length < 6 ? 'Tối thiểu 6 ký tự' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => !v!.contains('@') ? 'Email không hợp lệ' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại', hintText: 'VD: 0987654321'),
                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Vai trò'),
                    items: const [
                      DropdownMenuItem(value: 'EMPLOYEE', child: Text('Nhân viên')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên')),
                    ],
                    onChanged: (v) => setModalState(() => _selectedRole = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<dynamic>(
                    value: _selectedDept,
                    decoration: const InputDecoration(labelText: 'Phòng ban'),
                    items: _departments.map((d) => DropdownMenuItem(value: d['id'], child: Text(d['name']))).toList(),
                    onChanged: (v) => setModalState(() => _selectedDept = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<dynamic>(
                    value: _selectedShift,
                    decoration: const InputDecoration(labelText: 'Ca làm việc cố định'),
                    items: _allShifts.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['shiftName']))).toList(),
                    onChanged: (v) => setModalState(() => _selectedShift = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    await _apiService.createUser({
                      'username': _userController.text.trim(),
                      'password': _passController.text.trim(),
                      'fullName': _nameController.text.trim(),
                      'email': _emailController.text.trim(),
                      'phoneNumber': _phoneController.text.trim(),
                      'role': _selectedRole,
                      'departmentId': _selectedDept,
                      'assignedShiftId': _selectedShift,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo nhân viên thành công'), backgroundColor: AppTheme.success));
                    _fetchData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error));
                  }
                }
              },
              child: const Text('TẠO TÀI KHOẢN'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEmployeeDialog(dynamic user) {
    final _formKey = GlobalKey<FormState>();
    final _passController = TextEditingController();
    final _emailController = TextEditingController(text: user['email']);
    final _nameController = TextEditingController(text: user['fullName']);
    final _phoneController = TextEditingController(text: user['phoneNumber']);
    String _selectedRole = user['role'] ?? 'EMPLOYEE';
    dynamic _selectedDept = user['departmentId'];
    dynamic _selectedShift = user['assignedShiftId'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          title: Text('Cập nhật thông tin', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Nhân viên: ${user['fullName']} (${user['username']})", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passController,
                    decoration: const InputDecoration(labelText: 'Mật khẩu mới', hintText: 'Để trống nếu không đổi'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => !v!.contains('@') ? 'Email không hợp lệ' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại'),
                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Vai trò'),
                    items: const [
                      DropdownMenuItem(value: 'EMPLOYEE', child: Text('Nhân viên')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên')),
                    ],
                    onChanged: (v) => setModalState(() => _selectedRole = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<dynamic>(
                    value: _selectedDept,
                    decoration: const InputDecoration(labelText: 'Phòng ban'),
                    items: _departments.map((d) => DropdownMenuItem(value: d['id'], child: Text(d['name']))).toList(),
                    onChanged: (v) => setModalState(() => _selectedDept = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<dynamic>(
                    value: _selectedShift,
                    decoration: const InputDecoration(labelText: 'Ca làm việc cố định'),
                    items: _allShifts.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['shiftName']))).toList(),
                    onChanged: (v) => setModalState(() => _selectedShift = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    await _apiService.updateUser(user['id'], {
                      'username': user['username'],
                      'fullName': _nameController.text.trim(),
                      'email': _emailController.text.trim(),
                      'phoneNumber': _phoneController.text.trim(),
                      'role': _selectedRole,
                      'departmentId': _selectedDept,
                      'assignedShiftId': _selectedShift,
                      'password': _passController.text.isNotEmpty ? _passController.text.trim() : null,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công'), backgroundColor: AppTheme.success));
                    _fetchData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error));
                  }
                }
              },
              child: const Text('CẬP NHẬT'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteEmployee(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc chắn muốn xóa nhân viên '${user['fullName']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.deleteUser(user['id']);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa nhân viên'), backgroundColor: AppTheme.success));
                _fetchData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text("XÓA"),
          ),
        ],
      ),
    );
  }

  void _handleEkycReview(int userId, String status) async {
    try {
      await _apiService.reviewEkyc(userId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'APPROVED' ? 'Đã duyệt định danh' : 'Đã từ chối định danh'), backgroundColor: AppTheme.success),
        );
        _fetchData(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _handleLeaveReview(int leaveId, String status) async {
    try {
      await _apiService.reviewLeave(leaveId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'APPROVED' ? 'Đã duyệt đơn nghỉ' : 'Đã từ chối đơn nghỉ'), backgroundColor: AppTheme.success),
        );
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _handleShiftChangeReview(int requestId, String status) async {
    try {
      await _apiService.reviewShiftChange(requestId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'APPROVED' ? 'Đã duyệt đổi ca' : 'Đã từ chối đổi ca'), backgroundColor: AppTheme.success),
        );
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showImagePreview(String? idCardUrl, String? selfieUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chi tiết định danh"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (idCardUrl != null) ...[
              const Text("Ảnh CCCD:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Image.network("http://127.0.0.1:8081$idCardUrl", height: 200, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50)),
              const SizedBox(height: 16),
            ],
            if (selfieUrl != null) ...[
              const Text("Ảnh Selfie:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Image.network("http://127.0.0.1:8081$selfieUrl", height: 200, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50)),
            ],
            if (idCardUrl == null && selfieUrl == null) const Text("Không có ảnh đính kèm"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Sidebar Navigation
          _buildSidebar(),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNavy))
                    : _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(2, 0)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.fingerprint_rounded, color: AppTheme.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('SMARTOPS', 
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.white, letterSpacing: 2)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('CỔNG QUẢN TRỊ', style: GoogleFonts.montserrat(fontSize: 10, color: AppTheme.info, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: Colors.white24, height: 1),
          ),
          const SizedBox(height: 24),
          
          // Menu Items
          _buildNavItem(0, 'Tổng quan Hệ thống', Icons.dashboard_rounded),
          _buildNavItem(1, 'Danh sách Nhân sự', Icons.people_alt_rounded),
          _buildNavItem(2, 'Quản lý Đơn từ', Icons.assignment_rounded),
          _buildNavItem(3, 'Phê duyệt eKYC', Icons.face_retouching_natural_rounded),
          _buildNavItem(6, 'Quản lý Phòng ban', Icons.business_rounded),
          _buildNavItem(4, 'Cấu hình Ca làm', Icons.schedule_rounded),
          _buildNavItem(5, 'Báo cáo & Theo dõi', Icons.analytics_rounded),
          
          const Spacer(),
          
          // Logout
          Padding(
            padding: const EdgeInsets.all(24),
            child: InkWell(
              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Text('Đăng xuất', style: GoogleFonts.montserrat(color: Colors.white70, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: isSelected ? Border.all(color: AppTheme.info.withOpacity(0.5)) : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.white : Colors.white70, size: 20),
            const SizedBox(width: 16),
            Text(title, style: GoogleFonts.montserrat(
              color: isSelected ? AppTheme.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: const Border(bottom: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getPageTitle(),
            style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          Row(
            children: [
              Container(
                width: 250,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    hintStyle: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.secondarySlate),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.secondarySlate),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 8),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.secondarySlate),
                    onPressed: () => _showNotifications(context),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: AppTheme.primaryNavy, shape: BoxShape.circle),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text('Thông báo mới', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationItem('Có 3 đơn xin nghỉ mới cần phê duyệt', '10 phút trước'),
            const Divider(),
            _buildNotificationItem('Yêu cầu định danh eKYC từ NV005', '1 giờ trước'),
            const Divider(),
            _buildNotificationItem('Hệ thống AI vừa nhận diện 1 trường hợp đi muộn', '2 giờ trước'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String time) {
    return ListTile(
      leading: const Icon(Icons.info_outline_rounded, color: AppTheme.info),
      title: Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(time, style: GoogleFonts.montserrat(fontSize: 11)),
      contentPadding: EdgeInsets.zero,
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0: return "Tổng quan Dashboard";
      case 1: return "Danh bạ Nhân sự";
      case 2: return "Phê duyệt Đơn từ";
      case 3: return "Xác minh Biometric";
      case 4: return "Cấu hình Ca làm";
      case 5: return "Báo cáo & Theo dõi";
      case 6: return "Quản lý Phòng ban";
      default: return "Cổng Quản trị";
    }
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0: return _buildDashboardTab();
      case 1: return _buildPersonnelTab();
      case 2: return _buildRequestsTab();
      case 3: return _buildEkycTab();
      case 4: return _buildShiftsTab();
      case 5: return _buildReportsTab();
      case 6: return _buildDepartmentsTab();
      default: return _buildDashboardTab();
    }
  }

  // ==========================================
  // TAB 6: DEPARTMENT MANAGEMENT
  // ==========================================
  Widget _buildDepartmentsTab() {
    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Danh sách Phòng ban", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDepartmentDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("Thêm Phòng ban"),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(140, 40)),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _departments.isEmpty
              ? const Center(child: Text("Chưa có dữ liệu phòng ban"))
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _departments.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final dept = _departments[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.primaryNavy.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.business_rounded, color: AppTheme.primaryNavy),
                      ),
                      title: Text(dept['name'] ?? 'N/A', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                      subtitle: Text(dept['description'] ?? 'Không có mô tả'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.info, size: 20), 
                            onPressed: () => _showAddEditDepartmentDialog(dept: dept)
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20), 
                            onPressed: () => _confirmDeleteDepartment(dept)
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDepartmentDialog({Map<String, dynamic>? dept}) {
    final _nameController = TextEditingController(text: dept?['name']);
    final _descController = TextEditingController(text: dept?['description']);
    final bool isEdit = dept != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text(isEdit ? 'Cập nhật Phòng ban' : 'Thêm Phòng ban mới', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Tên phòng ban', hintText: 'VD: Phòng Nhân sự'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Mô tả', hintText: 'VD: Quản lý nhân sự và tiền lương'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final desc = _descController.text.trim();
              if (name.isNotEmpty) {
                try {
                  if (isEdit) {
                    await _apiService.updateDepartment(dept['id'], {'name': name, 'description': desc});
                  } else {
                    await _apiService.createDepartment({'name': name, 'description': desc});
                  }
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Cập nhật thành công' : 'Thêm phòng ban thành công'), backgroundColor: AppTheme.success),
                    );
                    _refreshDepartments();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
                    );
                  }
                }
              }
            },
            child: Text(isEdit ? 'CẬP NHẬT' : 'THÊM MỚI'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDepartment(Map<String, dynamic> dept) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc chắn muốn xóa phòng ban '${dept['name']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.deleteDepartment(dept['id']);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa phòng ban'), backgroundColor: AppTheme.success),
                  );
                  _refreshDepartments();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text("XÓA"),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 5: ATTENDANCE REPORTS (Horizontal Table with Filters)
  // ==========================================
  Widget _buildReportsTab() {
    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text("Báo cáo & Theo dõi Chấm công", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                _buildFilterChip("Hôm nay", "TODAY"),
                const SizedBox(width: 8),
                _buildFilterChip("7 ngày qua", "WEEK"),
                const SizedBox(width: 8),
                _buildFilterChip("Tháng này", "MONTH"),
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    String start = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    if (_reportFilter == 'WEEK') start = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 7)));
                    if (_reportFilter == 'MONTH') start = DateFormat('yyyy-MM-dd').format(DateTime(DateTime.now().year, DateTime.now().month, 1));
                    _apiService.exportAttendanceReport(start, DateFormat('yyyy-MM-dd').format(DateTime.now()));
                  },
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text("Xuất Excel"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, minimumSize: const Size(120, 40)),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _attendanceReports.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_late_outlined, size: 64, color: AppTheme.dividerColor),
                    const SizedBox(height: 16),
                    Text("Không có dữ liệu trong khoảng thời gian này", style: GoogleFonts.montserrat(color: AppTheme.secondarySlate)),
                  ],
                ))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingTextStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.secondarySlate, fontSize: 12),
                      dataTextStyle: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                      columnSpacing: 40,
                      horizontalMargin: 24,
                      columns: const [
                        DataColumn(label: Text("NHÂN VIÊN")),
                        DataColumn(label: Text("MÃ NV")),
                        DataColumn(label: Text("NGÀY")),
                        DataColumn(label: Text("GIỜ VÀO")),
                        DataColumn(label: Text("GIỜ RA")),
                        DataColumn(label: Text("CA LÀM")),
                        DataColumn(label: Text("TRẠNG THÁI")),
                      ],
                      rows: _attendanceReports.map((report) {
                        final checkIn = report['checkInTime'] != null ? DateTime.parse(report['checkInTime']) : null;
                        final checkOut = report['checkOutTime'] != null ? DateTime.parse(report['checkOutTime']) : null;
                        final status = report['status'] ?? 'N/A';
                        final bool isSuccess = status == 'ON_TIME' || status == 'SUCCESS';

                        return DataRow(cells: [
                          DataCell(Text(report['fullName'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(report['employeeCode'] ?? 'N/A')),
                          DataCell(Text(checkIn != null ? DateFormat('dd/MM/yyyy').format(checkIn) : 'N/A')),
                          DataCell(Text(checkIn != null ? DateFormat('HH:mm:ss').format(checkIn) : '--:--')),
                          DataCell(Text(checkOut != null ? DateFormat('HH:mm:ss').format(checkOut) : '--:--')),
                          DataCell(Text(report['shiftName'] ?? 'N/A')),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSuccess ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(isSuccess ? "ĐÚNG GIỜ" : "ĐI MUỘN", 
                              style: TextStyle(color: isSuccess ? AppTheme.success : AppTheme.error, fontSize: 10, fontWeight: FontWeight.bold)),
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _reportFilter == value;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() => _reportFilter = value);
          _fetchData();
        }
      },
      selectedColor: AppTheme.primaryNavy.withOpacity(0.1),
      labelStyle: TextStyle(color: isSelected ? AppTheme.primaryNavy : AppTheme.secondarySlate),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppTheme.primaryNavy : AppTheme.dividerColor)),
    );
  }

  // ==========================================
  // TAB 0: DASHBOARD OVERVIEW
  // ==========================================
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
          Row(
            children: [
              Expanded(child: _buildKpiCard("TỔNG NHÂN SỰ", "${_stats?['totalEmployees'] ?? 0}", Icons.people_alt_rounded, AppTheme.primaryNavy)),
              const SizedBox(width: 24),
              Expanded(child: _buildKpiCard("CÓ MẶT HÔM NAY", "${_stats?['presentToday'] ?? 0}", Icons.check_circle_rounded, AppTheme.success)),
              const SizedBox(width: 24),
              Expanded(child: _buildKpiCard("SỐ CA ĐI MUỘN", "${_stats?['lateToday'] ?? 0}", Icons.access_time_filled_rounded, AppTheme.warning)),
              const SizedBox(width: 24),
              Expanded(child: _buildKpiCard("SỐ CA VẮNG", "${_stats?['absentToday'] ?? 0}", Icons.cancel_rounded, AppTheme.error)),
            ],
          ),
          const SizedBox(height: 32),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart Area
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Xu hướng Chấm công (7 ngày)", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(7, (index) => _buildChartBar(index)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              
              // Live Logs Area
              Expanded(
                flex: 1,
                child: Container(
                  height: 390,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Hoạt động Trực tiếp", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text("LIVE", style: GoogleFonts.montserrat(color: AppTheme.error, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _liveLogs.isEmpty 
                          ? const Center(child: Text("Không có dữ liệu mới"))
                          : ListView.builder(
                              itemCount: _liveLogs.length,
                              itemBuilder: (context, index) => _buildMiniLogTile(_liveLogs[index]),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondarySlate)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 20, color: color),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildChartBar(int index) {
    final heights = [0.8, 0.9, 0.85, 0.95, 0.7, 0.3, 0.2];
    final days = ['TH2', 'TH3', 'TH4', 'TH5', 'TH6', 'TH7', 'CN'];
    return Column(
      children: [
        Container(
          width: 40,
          height: 250 * heights[index],
          decoration: BoxDecoration(
            color: AppTheme.primaryNavy.withOpacity(heights[index] > 0.5 ? 1 : 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 12),
        Text(days[index], style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondarySlate)),
      ],
    );
  }

  Widget _buildMiniLogTile(Map<String, dynamic> data) {
    final String name = data['fullName'] ?? 'N/A';
    final String time = data['checkInTime'] != null ? DateFormat('HH:mm:ss').format(DateTime.parse(data['checkInTime'])) : '--:--';
    final String status = data['status'] ?? 'UNKNOWN';
    final bool isSuccess = status == 'ON_TIME' || status == 'SUCCESS';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.white,
            child: Text(name.isNotEmpty ? name[0] : "?", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                Text(isSuccess ? 'ĐÚNG GIỜ' : 'ĐI MUỘN', style: GoogleFonts.montserrat(fontSize: 10, color: isSuccess ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text(time, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: PERSONNEL DIRECTORY (Horizontal Table)
  // ==========================================
  Widget _buildPersonnelTab() {
    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Danh sách Nhân viên", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _showAddEmployeeDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("Thêm Nhân viên"),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(140, 40)),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingTextStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.secondarySlate, fontSize: 12),
                  dataTextStyle: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                  columnSpacing: 48,
                  horizontalMargin: 24,
                  columns: const [
                    DataColumn(label: Text("NHÂN VIÊN")),
                    DataColumn(label: Text("MÃ NV")),
                    DataColumn(label: Text("SỐ ĐIỆN THOẠI")),
                    DataColumn(label: Text("PHÒNG BAN")),
                    DataColumn(label: Text("VAI TRÒ")),
                    DataColumn(label: Text("TRẠNG THÁI")),
                    DataColumn(label: Text("THAO TÁC")),
                  ],
                  rows: _allUsers.map((user) => DataRow(cells: [
                    DataCell(Row(
                      children: [
                        CircleAvatar(
                          radius: 16, 
                          backgroundColor: AppTheme.primaryNavy.withOpacity(0.1), 
                          child: Text(user['fullName'] != null ? user['fullName'][0] : "?", style: const TextStyle(fontSize: 10))
                        ),
                        const SizedBox(width: 12),
                        Text(user['fullName'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )),
                    DataCell(Text(user['username'] ?? 'N/A')),
                    DataCell(Text(user['phoneNumber'] ?? 'N/A')),
                    DataCell(Text(user['departmentName'] ?? 'N/A')),
                    DataCell(Text(user['role'] ?? 'EMPLOYEE')),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text("HOẠT ĐỘNG", style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                    )),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.info), 
                          onPressed: () => _showEditEmployeeDialog(user)
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error), 
                          onPressed: () => _confirmDeleteEmployee(user)
                        ),
                      ],
                    )),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text("Hàng đợi Duyệt đơn từ", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 48),
                  Expanded(
                    child: TabBar(
                      isScrollable: true,
                      labelColor: AppTheme.primaryNavy,
                      unselectedLabelColor: AppTheme.secondarySlate,
                      indicatorColor: AppTheme.primaryNavy,
                      tabs: const [
                        Tab(text: "Đơn xin nghỉ phép"),
                        Tab(text: "Yêu cầu đổi ca làm"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _buildLeaveRequestsTable(),
                  _buildShiftChangeRequestsTable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveRequestsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingTextStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.secondarySlate, fontSize: 12),
          dataTextStyle: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
          columnSpacing: 32,
          horizontalMargin: 24,
          columns: const [
            DataColumn(label: Text("MÃ ĐƠN")),
            DataColumn(label: Text("NHÂN VIÊN")),
            DataColumn(label: Text("LOẠI ĐƠN")),
            DataColumn(label: Text("THỜI GIAN")),
            DataColumn(label: Text("LÝ DO")),
            DataColumn(label: Text("TRẠNG THÁI")),
            DataColumn(label: Text("HÀNH ĐỘNG")),
          ],
          rows: _allLeaves.map((leave) {
            bool isPending = leave['status'] == 'PENDING';
            final int leaveId = leave['id'];
            return DataRow(cells: [
              DataCell(Text("LVE-${leave['id']}")),
              DataCell(Text(leave['fullName'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(leave['leaveType'] ?? 'N/A')),
              DataCell(Text("${leave['fromDate']} - ${leave['toDate']}")),
              DataCell(SizedBox(width: 150, child: Text(leave['reason'] ?? '...', overflow: TextOverflow.ellipsis))),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? AppTheme.warning.withOpacity(0.1) : (leave['status'] == 'APPROVED' ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Text(isPending ? "CHỜ DUYỆT" : (leave['status'] == 'APPROVED' ? "ĐÃ DUYỆT" : "TỪ CHỐI"), 
                  style: TextStyle(color: isPending ? AppTheme.warning : (leave['status'] == 'APPROVED' ? AppTheme.success : AppTheme.error), fontSize: 10, fontWeight: FontWeight.bold)),
              )),
              DataCell(isPending ? Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _handleLeaveReview(leaveId, 'REJECTED'), 
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error), minimumSize: const Size(60, 30)),
                    child: const Text("TỪ CHỐI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleLeaveReview(leaveId, 'APPROVED'), 
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, minimumSize: const Size(60, 30)),
                    child: const Text("DUYỆT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ) : const Text("Đã xử lý", style: TextStyle(color: AppTheme.secondarySlate, fontStyle: FontStyle.italic))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildShiftChangeRequestsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingTextStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.secondarySlate, fontSize: 12),
          dataTextStyle: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
          columnSpacing: 32,
          horizontalMargin: 24,
          columns: const [
            DataColumn(label: Text("MÃ YÊU CẦU")),
            DataColumn(label: Text("NHÂN VIÊN")),
            DataColumn(label: Text("CA HIỆN TẠI")),
            DataColumn(label: Text("CA MONG MUỐN")),
            DataColumn(label: Text("LÝ DO")),
            DataColumn(label: Text("TRẠNG THÁI")),
            DataColumn(label: Text("HÀNH ĐỘNG")),
          ],
          rows: _allShiftChangeRequests.map((req) {
            bool isPending = req['status'] == 'PENDING';
            final int reqId = req['id'];
            return DataRow(cells: [
              DataCell(Text("SFT-${req['id']}")),
              DataCell(Text(req['fullName'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(req['oldShiftName'] ?? 'N/A')),
              DataCell(Text(req['newShiftName'] ?? 'N/A', style: const TextStyle(color: AppTheme.info, fontWeight: FontWeight.bold))),
              DataCell(SizedBox(width: 150, child: Text(req['reason'] ?? '...', overflow: TextOverflow.ellipsis))),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? AppTheme.warning.withOpacity(0.1) : (req['status'] == 'APPROVED' ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Text(isPending ? "CHỜ DUYỆT" : (req['status'] == 'APPROVED' ? "ĐÃ DUYỆT" : "TỪ CHỐI"), 
                  style: TextStyle(color: isPending ? AppTheme.warning : (req['status'] == 'APPROVED' ? AppTheme.success : AppTheme.error), fontSize: 10, fontWeight: FontWeight.bold)),
              )),
              DataCell(isPending ? Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _handleShiftChangeReview(reqId, 'REJECTED'), 
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error), minimumSize: const Size(60, 30)),
                    child: const Text("TỪ CHỐI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleShiftChangeReview(reqId, 'APPROVED'), 
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, minimumSize: const Size(60, 30)),
                    child: const Text("DUYỆT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ) : const Text("Đã xử lý", style: TextStyle(color: AppTheme.secondarySlate, fontStyle: FontStyle.italic))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: EKYC APPROVALS (Horizontal Table)
  // ==========================================
  Widget _buildEkycTab() {
    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text("Phê duyệt Định danh Biometric (eKYC)", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingTextStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.secondarySlate, fontSize: 12),
                  dataTextStyle: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                  columnSpacing: 48,
                  horizontalMargin: 24,
                  columns: const [
                    DataColumn(label: Text("MÃ YÊU CẦU")),
                    DataColumn(label: Text("NHÂN VIÊN")),
                    DataColumn(label: Text("THỜI GIAN GỬI")),
                    DataColumn(label: Text("DỮ LIỆU GỐC")),
                    DataColumn(label: Text("TRẠNG THÁI")),
                    DataColumn(label: Text("THAO TÁC")),
                  ],
                  rows: _pendingEkyc.map((item) {
                    final int userId = item['id'];
                    return DataRow(cells: [
                      DataCell(Text("KYC-${item['id']}")),
                      DataCell(Text(item['fullName'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(item['username'] ?? 'N/A')),
                      DataCell(InkWell(
                        onTap: () => _showImagePreview(item['idCardUrl'], item['selfieUrl']),
                        child: Row(
                          children: [
                            const Icon(Icons.credit_card_rounded, size: 16, color: AppTheme.info),
                            const SizedBox(width: 8),
                            const Icon(Icons.face_rounded, size: 16, color: AppTheme.info),
                            const SizedBox(width: 8),
                            Text("Xem ảnh", style: GoogleFonts.montserrat(color: AppTheme.info, fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                          ],
                        ),
                      )),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Text("CHỜ DUYỆT", style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.bold)),
                      )),
                      DataCell(Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _handleEkycReview(userId, 'REJECTED'), 
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error), minimumSize: const Size(60, 30)),
                            child: const Text("BÁO LỖI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _handleEkycReview(userId, 'APPROVED'), 
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, minimumSize: const Size(60, 30)),
                            child: const Text("DUYỆT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: SHIFT CONFIGURATIONS (Horizontal Table)
  // ==========================================
  Widget _buildShiftsTab() {
    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Cấu hình Ca làm việc", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditShiftDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("Tạo Ca mới"),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(140, 40)),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _allShifts.isEmpty
              ? const Center(child: Text("Chưa có dữ liệu ca làm việc"))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingTextStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.secondarySlate, fontSize: 12),
                      dataTextStyle: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                      columnSpacing: 48,
                      horizontalMargin: 24,
                      columns: const [
                        DataColumn(label: Text("TÊN CA")),
                        DataColumn(label: Text("GIỜ VÀO")),
                        DataColumn(label: Text("GIỜ RA")),
                        DataColumn(label: Text("CHÂM CHƯỚC")),
                        DataColumn(label: Text("TRẠNG THÁI")),
                        DataColumn(label: Text("THAO TÁC")),
                      ],
                      rows: _allShifts.map((shift) {
                        final bool isActive = shift['isActive'] ?? true;
                        return DataRow(cells: [
                          DataCell(Text(shift['shiftName'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(shift['startTime'] ?? '--:--')),
                          DataCell(Text(shift['endTime'] ?? '--:--')),
                          DataCell(Text("${shift['gracePeriod']} Phút", style: const TextStyle(color: AppTheme.warning))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.success.withOpacity(0.1) : AppTheme.secondarySlate.withOpacity(0.1), 
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(isActive ? "ĐANG DÙNG" : "NGỪNG DÙNG", 
                              style: TextStyle(color: isActive ? AppTheme.success : AppTheme.secondarySlate, fontSize: 10, fontWeight: FontWeight.bold)),
                          )),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.info), 
                                onPressed: () => _showAddEditShiftDialog(shift: shift)
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error), 
                                onPressed: () => _confirmDeleteShift(shift)
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  void _showAddEditShiftDialog({Map<String, dynamic>? shift}) {
    final bool isEdit = shift != null;
    final _nameController = TextEditingController(text: shift?['shiftName']);
    final _startController = TextEditingController(text: shift?['startTime'] ?? "08:00");
    final _endController = TextEditingController(text: shift?['endTime'] ?? "17:00");
    final _graceController = TextEditingController(text: (shift?['gracePeriod'] ?? 15).toString());
    bool _isActive = shift?['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          title: Text(isEdit ? 'Cập nhật Ca làm' : 'Thêm Ca làm mới', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tên ca làm', hintText: 'VD: Ca Sáng'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startController,
                        decoration: const InputDecoration(labelText: 'Giờ vào (HH:mm)', hintText: '08:00'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _endController,
                        decoration: const InputDecoration(labelText: 'Giờ ra (HH:mm)', hintText: '17:00'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _graceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Châm chước (phút)', hintText: '15'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text("Đang sử dụng"),
                  value: _isActive,
                  onChanged: (val) => setModalState(() => _isActive = val),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'shiftName': _nameController.text.trim(),
                  'startTime': _startController.text.trim(),
                  'endTime': _endController.text.trim(),
                  'gracePeriod': int.tryParse(_graceController.text) ?? 15,
                  'isActive': _isActive,
                };

                try {
                  if (isEdit) {
                    await _apiService.updateShift(shift['id'], data);
                  } else {
                    await _apiService.createShift(data);
                  }
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Cập nhật thành công' : 'Thêm ca làm thành công'), backgroundColor: AppTheme.success),
                    );
                    _refreshShifts();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'CẬP NHẬT' : 'THÊM MỚI'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteShift(Map<String, dynamic> shift) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc chắn muốn xóa ca làm '${shift['shiftName']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.deleteShift(shift['id']);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa ca làm việc'), backgroundColor: AppTheme.success),
                  );
                  _refreshShifts();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text("XÓA"),
          ),
        ],
      ),
    );
  }
}
