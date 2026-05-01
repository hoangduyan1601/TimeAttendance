import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartops_app/core/theme.dart';
import 'package:smartops_app/services/api_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  List<dynamic> _shiftChangeRequests = [];
  List<dynamic> _leaveRequests = [];
  List<dynamic> _allShifts = [];
  bool _isLoading = true;
  String _shiftName = "Đang tải...";
  String _shiftTime = "00:00 - 00:00";
  String _shiftLocation = "Văn phòng";
  String _shiftNotes = "Đúng giờ";
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'WEEK'; // 'WEEK', 'MONTH'
  
  // Stats
  int _totalShifts = 22;
  double _totalHours = 176.0;
  int _totalLeaves = 2;

  // Form states
  final TextEditingController _reasonController = TextEditingController();
  String _requestType = 'LEAVE'; 
  String _selectedLeaveType = 'ANNUAL_LEAVE';
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  dynamic _selectedShiftId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getMyShiftChanges(),
        _apiService.getAllShifts(),
        _apiService.getMyLeaves(),
        _apiService.getMyProfile(),
      ]);
      
      if (mounted) {
        setState(() {
          _shiftChangeRequests = results[0]['data'] ?? [];
          _allShifts = results[1]['data'] ?? [];
          _leaveRequests = results[2]['data'] ?? [];
          
          final profileData = results[3]['data'];
          _shiftName = profileData['assignedShiftName'] ?? "Chưa phân ca";
          
          if (profileData['assignedShiftStartTime'] != null && profileData['assignedShiftEndTime'] != null) {
            final start = profileData['assignedShiftStartTime'].toString().substring(0, 5);
            final end = profileData['assignedShiftEndTime'].toString().substring(0, 5);
            _shiftTime = "$start - $end";
          } else {
            _shiftTime = "--:-- - --:--";
          }
          
          _shiftLocation = profileData['assignedShiftLocation'] ?? "Văn phòng";
          _shiftNotes = profileData['assignedShiftNotes'] ?? "Đúng giờ";
          
          if (_allShifts.isNotEmpty) _selectedShiftId = _allShifts.first['id'];
          _totalLeaves = _leaveRequests.where((l) => l['status'] == 'APPROVED').length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('QUẢN LÝ LỊCH LÀM VIỆC', 
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1)),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryNavy,
          unselectedLabelColor: AppTheme.secondarySlate,
          indicatorColor: AppTheme.primaryNavy,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'LỊCH BIỂU'),
            Tab(text: 'YÊU CẦU & ĐƠN TỪ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScheduleTab(),
          _buildRequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRequestDialog(),
        backgroundColor: AppTheme.primaryNavy,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('TẠO ĐƠN MỚI', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
      ),
    );
  }

  // --- TAB 1: SCHEDULE ---
  Widget _buildScheduleTab() {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewSection(),
                const SizedBox(height: 24),
                _buildViewToggle(),
                const SizedBox(height: 24),
                if (_viewMode == 'WEEK') ...[
                  _buildWeeklyTimetable(),
                ] else ...[
                  _buildMonthlyCalendarGrid(),
                ],
                const SizedBox(height: 80), 
              ],
            ),
          ),
        );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 45,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            _buildToggleButton('WEEK', 'Tuần', Icons.view_week_rounded),
            _buildToggleButton('MONTH', 'Tháng', Icons.calendar_view_month_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String mode, String label, IconData icon) {
    final bool isActive = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isActive ? Colors.white : AppTheme.secondarySlate),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.montserrat(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: isActive ? Colors.white : AppTheme.secondarySlate
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyTimetable() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final List<String> weekDays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('THỜI KHÓA BIỂU TUẦN NÀY', 
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final bool isToday = DateUtils.isSameDay(date, now);
              final bool isWeekend = index >= 5;

              return GestureDetector(
                onTap: () => _showShiftDetailSheet(date),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isToday ? AppTheme.primaryNavy.withOpacity(0.05) : AppTheme.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: isToday ? AppTheme.primaryNavy : AppTheme.dividerColor, width: isToday ? 2 : 1),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(weekDays[index], style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: isToday ? AppTheme.primaryNavy : AppTheme.secondarySlate)),
                      const SizedBox(height: 4),
                      Text('${date.day}/${date.month}', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                      const SizedBox(height: 20),
                      if (isWeekend)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.secondarySlate.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text('NGÀY NGHỈ', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.secondarySlate)),
                        )
                      else ...[
                        Text(_shiftName, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 10, color: AppTheme.secondarySlate),
                            const SizedBox(width: 4),
                            Text(_shiftTime, style: GoogleFonts.montserrat(fontSize: 10, color: AppTheme.secondarySlate)),
                          ],
                        ),
                      ],
                      if (isToday)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.info, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('HÔM NAY', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: AppTheme.info)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text('* Nhấn vào ô để xem chi tiết và đăng ký nghỉ/đổi ca', 
            style: GoogleFonts.montserrat(fontSize: 10, color: AppTheme.secondarySlate, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  void _showShiftDetailSheet(DateTime date) {
    final String formattedDate = DateFormat('EEEE, dd/MM/yyyy').format(date);
    final bool isWeekend = date.weekday >= 6;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: AppTheme.dividerColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.primaryNavy.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.event_available_rounded, color: AppTheme.primaryNavy, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CHI TIẾT CA LÀM VIỆC', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryNavy)),
                      Text(formattedDate, style: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.secondarySlate, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (isWeekend)
              _buildDetailInfoRow(Icons.weekend_rounded, 'Trạng thái', 'Ngày nghỉ cuối tuần', AppTheme.secondarySlate)
            else ...[
              _buildDetailInfoRow(Icons.work_rounded, 'Tên ca', _shiftName, AppTheme.textPrimary),
              const SizedBox(height: 20),
              _buildDetailInfoRow(Icons.access_time_filled_rounded, 'Thời gian', _shiftTime, AppTheme.textPrimary),
              const SizedBox(height: 20),
              _buildDetailInfoRow(Icons.location_on_rounded, 'Địa điểm', _shiftLocation, AppTheme.textPrimary),
              const SizedBox(height: 20),
              _buildDetailInfoRow(Icons.info_rounded, 'Ghi chú', _shiftNotes, AppTheme.secondarySlate),
            ],
            const SizedBox(height: 40),
            Text('HÀNH ĐỘNG NHANH', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.secondarySlate, letterSpacing: 1)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'ĐĂNG KÝ NGHỈ', 
                    Icons.beach_access_rounded, 
                    AppTheme.success, 
                    () {
                      Navigator.pop(context);
                      _showAddRequestDialog(initialType: 'LEAVE', date: date);
                    }
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    'YÊU CẦU ĐỔI CA', 
                    Icons.swap_horiz_rounded, 
                    AppTheme.primaryNavy, 
                    () {
                      Navigator.pop(context);
                      _showAddRequestDialog(initialType: 'SHIFT_CHANGE', date: date);
                    }
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailInfoRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.secondarySlate.withOpacity(0.5)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.montserrat(fontSize: 11, color: AppTheme.secondarySlate, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.montserrat(fontSize: 14, color: valueColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }

  Widget _buildMonthlyCalendarGrid() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final prefixDays = firstDayOfMonth.weekday - 1;
    
    final List<String> weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LỊCH TRỰC THÁNG ${now.month}', 
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
              Text('${now.year}', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekDays.map((d) => Expanded(
                    child: Center(child: Text(d, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.secondarySlate)))
                  )).toList(),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: 35, 
                  itemBuilder: (context, index) {
                    final int dayOffset = index - prefixDays;
                    if (dayOffset < 0 || dayOffset >= lastDayOfMonth.day) {
                      return const SizedBox();
                    }
                    
                    final date = DateTime(now.year, now.month, dayOffset + 1);
                    final bool isToday = DateUtils.isSameDay(date, now);
                    final bool isWeekend = date.weekday >= 6;

                    return GestureDetector(
                      onTap: () => _showShiftDetailSheet(date),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isToday ? AppTheme.primaryNavy : (isWeekend ? AppTheme.background : AppTheme.white),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isToday ? AppTheme.primaryNavy : AppTheme.dividerColor),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${date.day}', style: GoogleFonts.montserrat(
                              fontSize: 12, 
                              fontWeight: FontWeight.w800, 
                              color: isToday ? Colors.white : AppTheme.textPrimary
                            )),
                            if (!isWeekend)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 4, height: 4,
                                decoration: BoxDecoration(color: isToday ? Colors.white : AppTheme.info, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildLegendItem(AppTheme.info, 'Ngày làm việc'),
          const SizedBox(height: 4),
          _buildLegendItem(AppTheme.background, 'Ngày nghỉ / Cuối tuần', isBorder: true),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool isBorder = false}) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: color, 
            borderRadius: BorderRadius.circular(3),
            border: isBorder ? Border.all(color: AppTheme.dividerColor) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.montserrat(fontSize: 10, color: AppTheme.secondarySlate, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildOverviewSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TỔNG QUAN THÁNG NÀY', 
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.secondarySlate, letterSpacing: 1)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('Số ca', '$_totalShifts', Icons.event_note_rounded, AppTheme.info),
              const SizedBox(width: 12),
              _buildStatItem('Số giờ', '${_totalHours.toInt()}h', Icons.timer_rounded, AppTheme.warning),
              const SizedBox(width: 12),
              _buildStatItem('Nghỉ', '$_totalLeaves', Icons.beach_access_rounded, AppTheme.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            Text(label, style: GoogleFonts.montserrat(fontSize: 10, color: AppTheme.secondarySlate, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: REQUESTS ---
  Widget _buildRequestsTab() {
    List<dynamic> combinedRequests = [
      ..._shiftChangeRequests.map((e) => {...e, 'type': 'SHIFT_CHANGE'}),
      ..._leaveRequests.map((e) => {...e, 'type': 'LEAVE'}),
    ];
    
    combinedRequests.sort((a, b) {
      if (a['createdAt'] != null && b['createdAt'] != null) {
        return DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt']));
      }
      return (b['id'] as int).compareTo(a['id'] as int);
    });

    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: _fetchData,
          child: combinedRequests.isEmpty
            ? _buildEmptyRequestsView()
            : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: combinedRequests.length,
                itemBuilder: (context, index) => _buildRequestCard(combinedRequests[index]),
              ),
        );
  }

  Widget _buildEmptyRequestsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: AppTheme.secondarySlate.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text("Chưa có yêu cầu hoặc đơn từ nào", style: GoogleFonts.montserrat(color: AppTheme.secondarySlate)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(dynamic item) {
    final bool isShiftChange = item['type'] == 'SHIFT_CHANGE';
    final String status = item['status'] ?? 'PENDING';
    final Color color = status == 'APPROVED' ? AppTheme.success : (status == 'PENDING' ? AppTheme.warning : AppTheme.error);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white, 
        borderRadius: BorderRadius.circular(AppTheme.radiusLg), 
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (isShiftChange ? AppTheme.primaryNavy : AppTheme.success).withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                child: Icon(isShiftChange ? Icons.swap_horiz_rounded : Icons.calendar_today_rounded, color: isShiftChange ? AppTheme.primaryNavy : AppTheme.success, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isShiftChange ? 'Yêu cầu đổi ca' : 'Đơn nghỉ phép', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      isShiftChange 
                        ? '${item['oldShiftName']} ➔ ${item['newShiftName']}'
                        : '${item['fromDate']} ➔ ${item['toDate']}', 
                      style: GoogleFonts.montserrat(fontSize: 11, color: AppTheme.secondarySlate)
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status, color),
            ],
          ),
          const SizedBox(height: 12),
          if (!isShiftChange) 
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text("Loại: ${item['leaveType']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondarySlate)),
            ),
          Text("Lý do: ${item['reason']}", style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (item['createdAt'] != null)
                Text('Gửi ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['createdAt']))}', 
                  style: const TextStyle(fontSize: 10, color: AppTheme.secondarySlate, fontStyle: FontStyle.italic)),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.dividerColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    String text = "ĐANG CHỜ";
    if (status == 'APPROVED') text = "ĐÃ DUYỆT";
    if (status == 'REJECTED') text = "TỪ CHỐI";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: GoogleFonts.montserrat(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }

  // --- DIALOGS & FORMS ---
  void _showAddRequestDialog({String? initialType, DateTime? date}) {
    if (initialType != null) _requestType = initialType;
    if (date != null) {
      _fromDate = date;
      _toDate = date;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddRequestSheet(),
    );
  }

  Widget _buildAddRequestSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TẠO YÊU CẦU MỚI', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryNavy)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 24),
              _buildLabel('Loại yêu cầu'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _requestType,
                decoration: InputDecoration(
                  prefixIcon: Icon(_requestType == 'LEAVE' ? Icons.calendar_today_rounded : Icons.swap_horiz_rounded, color: AppTheme.primaryNavy),
                ),
                items: const [
                  DropdownMenuItem(value: 'LEAVE', child: Text('Đơn xin nghỉ phép')),
                  DropdownMenuItem(value: 'SHIFT_CHANGE', child: Text('Yêu cầu đổi ca làm')),
                ],
                onChanged: (v) => setModalState(() => _requestType = v!),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              
              if (_requestType == 'LEAVE') 
                _buildLeaveFormSection(setModalState)
              else 
                _buildShiftChangeFormSection(setModalState),

              const SizedBox(height: 32),
              _isSubmitting 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () => _handleSubmit(setModalState),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppTheme.primaryNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    ),
                    child: Text('GỬI YÊU CẦU NGAY', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit(StateSetter setModalState) {
    if (_requestType == 'LEAVE') {
      _submitLeave(setModalState);
    } else {
      _submitShiftChange(setModalState);
    }
  }

  Widget _buildLeaveFormSection(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Loại nghỉ phép'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedLeaveType,
          items: const [
            DropdownMenuItem(value: 'ANNUAL_LEAVE', child: Text('Nghỉ phép năm')),
            DropdownMenuItem(value: 'SICK_LEAVE', child: Text('Nghỉ ốm')),
            DropdownMenuItem(value: 'PERSONAL', child: Text('Việc riêng')),
          ],
          onChanged: (v) => setModalState(() => _selectedLeaveType = v!),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDatePickerField('Từ ngày', _fromDate, (d) => setModalState(() => _fromDate = d))),
            const SizedBox(width: 16),
            Expanded(child: _buildDatePickerField('Đến ngày', _toDate, (d) => setModalState(() => _toDate = d))),
          ],
        ),
        const SizedBox(height: 16),
        _buildLabel('Lý do'),
        const SizedBox(height: 8),
        TextField(controller: _reasonController, maxLines: 2, decoration: const InputDecoration(hintText: 'Nhập lý do...')),
      ],
    );
  }

  Widget _buildShiftChangeFormSection(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Chọn ca muốn đổi sang'),
        const SizedBox(height: 8),
        _allShifts.isEmpty 
          ? const Text("Đang tải danh sách ca...")
          : DropdownButtonFormField<dynamic>(
              value: _selectedShiftId,
              items: _allShifts.map((s) => DropdownMenuItem(value: s['id'], child: Text("${s['shiftName']} (${s['startTime']} - ${s['endTime']})"))).toList(),
              onChanged: (v) => setModalState(() => _selectedShiftId = v),
            ),
        const SizedBox(height: 16),
        _buildLabel('Lý do đổi ca'),
        const SizedBox(height: 8),
        TextField(controller: _reasonController, maxLines: 3, decoration: const InputDecoration(hintText: 'Nhập lý do chi tiết...')),
      ],
    );
  }

  Widget _buildDatePickerField(String label, DateTime date, Function(DateTime) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (picked != null) onPicked(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.dividerColor), borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(fontSize: 12)),
                const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.secondarySlate),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary));
  }

  void _submitLeave(StateSetter setModalState) async {
    if (_reasonController.text.trim().isEmpty) return;
    setModalState(() => _isSubmitting = true);
    try {
      await _apiService.submitLeave({
        'fromDate': DateFormat('yyyy-MM-dd').format(_fromDate),
        'toDate': DateFormat('yyyy-MM-dd').format(_toDate),
        'leaveType': _selectedLeaveType,
        'reason': _reasonController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gửi yêu cầu thành công!"), backgroundColor: AppTheme.success));
        _reasonController.clear();
        _fetchData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: AppTheme.error));
    } finally {
      setModalState(() => _isSubmitting = false);
    }
  }

  void _submitShiftChange(StateSetter setModalState) async {
    if (_reasonController.text.trim().isEmpty) return;
    setModalState(() => _isSubmitting = true);
    try {
      await _apiService.submitShiftChange({
        'newShiftId': _selectedShiftId,
        'reason': _reasonController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gửi yêu cầu đổi ca thành công!"), backgroundColor: AppTheme.success));
        _reasonController.clear();
        _fetchData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: AppTheme.error));
    } finally {
      setModalState(() => _isSubmitting = false);
    }
  }
}

