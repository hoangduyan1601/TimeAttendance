import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartops_app/core/routes.dart';
import 'package:smartops_app/core/theme.dart';
import 'package:smartops_app/services/api_service.dart';
import 'package:smartops_app/screens/employee/ekyc_screen.dart';
import 'package:smartops_app/screens/employee/history_screen.dart';
import 'package:smartops_app/screens/employee/schedule_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  
  String _qrData = "";
  String _userName = "Đang tải...";
  String _userCode = "NV-000";
  String _shiftName = "Chưa phân ca";
  Timer? _timer;
  int _countdown = 30;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchQrCode();
    _startTimer();
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await _apiService.getMyProfile();
      final userData = response['data'];
      if (mounted) {
        setState(() {
          _userName = userData['fullName'] ?? "Nhân viên";
          _userCode = userData['employeeCode'] ?? "NV-000";
          _shiftName = userData['assignedShiftName'] ?? "Chưa phân ca";
        });
        // Update prefs
        await prefs.setString('full_name', _userName);
        await prefs.setString('shift_name', _shiftName);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = prefs.getString('full_name') ?? "Nhân viên";
          _shiftName = prefs.getString('shift_name') ?? "Chưa phân ca";
        });
      }
    }
  }

  void _fetchQrCode() async {
    try {
      final response = await _apiService.getQrCode();
      if (mounted) {
        setState(() {
          _qrData = response['data']['qrToken'];
          _countdown = 30;
        });
      }
    } catch (e) {
      debugPrint("Error fetching QR: $e");
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        _fetchQrCode();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _buildMainContent(),
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
                Text('CỔNG NHÂN VIÊN', style: GoogleFonts.montserrat(fontSize: 10, color: AppTheme.info, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: Colors.white24, height: 1),
          ),
          const SizedBox(height: 24),
          _buildNavItem(0, 'Trang chủ & QR', Icons.home_rounded),
          _buildNavItem(1, 'Lịch sử Chấm công', Icons.history_rounded),
          _buildNavItem(2, 'Lịch làm việc', Icons.calendar_month_rounded),
          _buildNavItem(3, 'Định danh eKYC', Icons.face_retouching_natural_rounded),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: InkWell(
              onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
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
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_userName, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(_userCode, style: GoogleFonts.montserrat(fontSize: 11, color: AppTheme.secondarySlate)),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: AppTheme.primaryNavy, shape: BoxShape.circle),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.background,
                  child: Icon(Icons.person_rounded, size: 20, color: AppTheme.primaryNavy),
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
        title: Text('Thông báo của bạn', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationItem('Yêu cầu đổi ca ngày 20/04 đã được duyệt', '5 phút trước'),
            const Divider(),
            _buildNotificationItem('Nhắc nhở: Bạn có ca làm lúc 08:00 AM ngày mai', '2 giờ trước'),
            const Divider(),
            _buildNotificationItem('Hệ thống yêu cầu cập nhật lại ảnh eKYC', '1 ngày trước'),
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
      leading: const Icon(Icons.notifications_active_outlined, color: AppTheme.info),
      title: Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(time, style: GoogleFonts.montserrat(fontSize: 11)),
      contentPadding: EdgeInsets.zero,
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0: return "Trang chủ";
      case 1: return "Lịch sử";
      case 2: return "Lịch làm việc";
      case 3: return "Định danh";
      default: return "SmartOps";
    }
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0: return _buildHomeTab();
      case 1: return const HistoryScreen();
      case 2: return const ScheduleScreen();
      case 3: return const EkycScreen();
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
          Text("HOẠT ĐỘNG GẦN ĐÂY", style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
          const SizedBox(height: 16),
          _buildActivityCard("Chấm công vào", "08:05 AM", "Thành công", AppTheme.success),
          _buildActivityCard("Đăng ký nghỉ phép", "Hôm qua", "Đã duyệt", AppTheme.info),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    final List<String> weekDays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // 0 for Monday

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LỊCH LÀM VIỆC TUẦN NÀY', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryNavy, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('Ca làm việc cố định của bạn', style: GoogleFonts.montserrat(fontSize: 11, color: AppTheme.secondarySlate)),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _selectedIndex = 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.primaryNavy.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Text('Đổi ca / Nghỉ', style: GoogleFonts.montserrat(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(weekDays.length, (index) {
                final bool isToday = index == todayIndex;
                final bool isWeekend = index >= 5;
                
                return Container(
                  width: 85,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isToday ? AppTheme.primaryNavy : (isWeekend ? AppTheme.background : AppTheme.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isToday ? AppTheme.primaryNavy : AppTheme.dividerColor),
                  ),
                  child: Column(
                    children: [
                      Text(weekDays[index], style: GoogleFonts.montserrat(
                        color: isToday ? AppTheme.white : AppTheme.secondarySlate,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      )),
                      const SizedBox(height: 12),
                      Icon(
                        isWeekend ? Icons.event_busy_rounded : Icons.wb_sunny_rounded,
                        color: isToday ? AppTheme.white : (isWeekend ? AppTheme.secondarySlate : AppTheme.warning),
                        size: 20,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isWeekend ? 'OFF' : _shiftName.split(' ').last,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          color: isToday ? AppTheme.white : AppTheme.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MÃ TRUY CẬP ĐỘNG', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryNavy, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.primaryNavy, borderRadius: BorderRadius.circular(8)),
                child: Text('Hết hạn sau: $_countdown s', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.white)),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _qrData.isEmpty
              ? const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()))
              : QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 250.0,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: AppTheme.primaryNavy),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: AppTheme.primaryNavy),
                ),
          const SizedBox(height: 40),
          Text('Vui lòng quét mã này tại trạm Kiosk để điểm danh', textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: AppTheme.secondarySlate, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String title, String time, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(AppTheme.radiusMd), border: Border.all(color: AppTheme.dividerColor)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.check_circle_outline, color: color, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)), Text(time, style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.secondarySlate))])),
          Text(status, style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

