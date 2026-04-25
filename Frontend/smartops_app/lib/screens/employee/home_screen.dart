import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartops_app/core/routes.dart';
import 'package:smartops_app/core/theme.dart';
import 'package:smartops_app/screens/employee/ekyc_screen.dart';
import 'package:smartops_app/screens/employee/history_screen.dart';
import 'package:smartops_app/screens/employee/overtime_request_screen.dart';
import 'package:smartops_app/screens/employee/schedule_screen.dart';
import 'package:smartops_app/services/api_service.dart';
import 'package:smartops_app/widgets/responsive_layout.dart';
import 'package:intl/intl.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  final ApiService _apiService = ApiService();
  int _selectedIndex = 0;
  String _userName = "Nhân viên";
  String _employeeCode = "";
  String _qrToken = "";
  Timer? _qrTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchQrToken();
    _qrTimer = Timer.periodic(const Duration(minutes: 4), (timer) => _fetchQrToken());
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final profile = await _apiService.getMyProfile();
      if (mounted) {
        setState(() {
          _userName = profile['data']['fullName'] ?? "Nhân viên";
          _employeeCode = profile['data']['employeeCode'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> _fetchQrToken() async {
    try {
      final response = await _apiService.getQrCode();
      if (mounted) {
        setState(() {
          _qrToken = response['data']['qrToken'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching QR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: isMobile
          ? AppBar(
              title: Text(_getPageTitle()),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {},
                ),
              ],
            )
          : null,
      drawer: isMobile ? Drawer(child: _buildSidebarContent()) : null,
      body: ResponsiveLayout(
        mobileBody: _buildMainContent(),
        desktopBody: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(child: _buildMainContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: _buildSidebarContent(),
    );
  }

  Widget _buildSidebarContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: AppTheme.white, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SMARTOPS',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'HỆ THỐNG CHẤM CÔNG',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: AppTheme.info,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Divider(color: Colors.white12, height: 1),
        ),
        const SizedBox(height: 32),
        _buildNavItem(0, 'Trang chủ Dashboard', Icons.grid_view_rounded),
        _buildNavItem(1, 'Lịch sử Chấm công', Icons.history_rounded),
        _buildNavItem(2, 'Lịch làm việc', Icons.calendar_month_rounded),
        _buildNavItem(3, 'Đăng ký OT', Icons.timer_outlined),
        _buildNavItem(4, 'Định danh eKYC', Icons.face_retouching_natural_rounded),
        const Spacer(),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.white : Colors.white60,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  color: isSelected ? AppTheme.white : Colors.white60,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: InkWell(
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
        },
        child: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.white60, size: 20),
            const SizedBox(width: 12),
            Text(
              'Đăng xuất',
              style: GoogleFonts.montserrat(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getPageTitle(),
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.secondarySlate),
                onPressed: () {},
              ),
              const SizedBox(width: 24),
              _buildProfileSummary(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSummary() {
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _userName,
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              _employeeCode,
              style: GoogleFonts.montserrat(fontSize: 11, color: AppTheme.secondarySlate),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(color: AppTheme.primaryNavy, shape: BoxShape.circle),
          child: const CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.background,
            child: Icon(Icons.person_rounded, color: AppTheme.primaryNavy, size: 20),
          ),
        ),
      ],
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0: return "Trang chủ";
      case 1: return "Lịch sử";
      case 2: return "Lịch làm việc";
      case 3: return "Đăng ký OT";
      case 4: return "Định danh";
      default: return "SmartOps";
    }
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0: return _buildHomeTab();
      case 1: return const HistoryScreen();
      case 2: return const ScheduleScreen();
      case 3: return const OvertimeRequestScreen();
      case 4: return const EkycScreen();
      default: return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklySchedule(),
          const SizedBox(height: 32),
          _buildQrSection(),
          const SizedBox(height: 32),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "LỊCH LÀM VIỆC TUẦN NÀY",
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primaryNavy, letterSpacing: 1),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 2),
                child: const Text("XEM CHI TIẾT"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDayCard("T2", "18/03", "Hành chính", true),
                _buildDayCard("T3", "19/03", "Hành chính", false),
                _buildDayCard("T4", "20/03", "Hành chính", false),
                _buildDayCard("T5", "21/03", "Hành chính", false),
                _buildDayCard("T6", "22/03", "Hành chính", false),
                _buildDayCard("T7", "23/03", "Nghỉ", false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(String day, String date, String shift, bool isToday) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isToday ? AppTheme.primaryNavy : AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: isToday ? AppTheme.primaryNavy : AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Text(day, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: isToday ? Colors.white : AppTheme.textPrimary)),
          Text(date, style: GoogleFonts.poppins(fontSize: 12, color: isToday ? Colors.white70 : AppTheme.secondarySlate)),
          const SizedBox(height: 12),
          Text(shift, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: isToday ? AppTheme.info : AppTheme.primaryNavy)),
        ],
      ),
    );
  }

  Widget _buildQrSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                Text("QUÉT MÃ CHẤM CÔNG", style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                Text("Mã QR tự động cập nhật sau mỗi 5 phút", 
                  style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.secondarySlate), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                _qrToken.isEmpty 
                  ? const CircularProgressIndicator()
                  : QrImageView(
                      data: _qrToken,
                      version: QrVersions.auto,
                      size: 200.0,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.primaryNavy),
                    ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sync_rounded, size: 16, color: AppTheme.primaryNavy),
                      const SizedBox(width: 8),
                      Text("Đang hiệu lực", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryNavy)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 1,
          child: _buildInstructions(),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        _buildStepItem(1, "Mở ứng dụng SmartOps trên điện thoại hoặc lấy mã QR từ trình duyệt."),
        const SizedBox(height: 16),
        _buildStepItem(2, "Đưa mã QR này lại gần Camera của Kiosk chấm công tại cửa."),
        const SizedBox(height: 16),
        _buildStepItem(3, "Hệ thống AI sẽ tự động nhận diện khuôn mặt để xác thực."),
        const SizedBox(height: 16),
        _buildStepItem(4, "Sau khi thành công, kết quả chấm công sẽ hiển thị ngay lập tức."),
      ],
    );
  }

  Widget _buildStepItem(int step, String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primaryNavy,
            child: Text("$step", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: GoogleFonts.montserrat(fontSize: 13, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatCard("Số ca đúng giờ", "24/26", Icons.check_circle_outline_rounded, AppTheme.success),
        const SizedBox(width: 24),
        _buildStatCard("Số ca đi muộn", "02", Icons.access_time_rounded, AppTheme.warning),
        const SizedBox(width: 24),
        _buildStatCard("Tổng giờ làm", "184h", Icons.work_history_outlined, AppTheme.info),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.secondarySlate, fontWeight: FontWeight.w600)),
                Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
