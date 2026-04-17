import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartops_app/core/theme.dart';
import 'package:smartops_app/services/api_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Thống kê
  int _totalOnTime = 0;
  int _totalLate = 0;
  int _totalAbsent = 0;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchHistory();
  }

  void _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      // Lấy dữ liệu của 3 tháng gần nhất để hiển thị lịch
      final startStr = DateFormat('yyyy-MM-dd').format(DateTime(_focusedDay.year, _focusedDay.month - 2, 1));
      final endStr = DateFormat('yyyy-MM-dd').format(DateTime(_focusedDay.year, _focusedDay.month + 1, 0));
      
      final response = await _apiService.getAttendanceHistory(
        startDate: startStr,
        endDate: endStr,
      );
      
      if (mounted) {
        final List<dynamic> historyData = response['data'] ?? [];
        Map<DateTime, List<dynamic>> newEvents = {};
        
        int onTime = 0;
        int late = 0;

        for (var item in historyData) {
          if (item['checkInTime'] != null) {
            final date = DateTime.parse(item['checkInTime']);
            final dayKey = DateTime(date.year, date.month, date.day);
            
            if (newEvents[dayKey] == null) newEvents[dayKey] = [];
            newEvents[dayKey]!.add(item);

            final status = item['status']?.toString().toUpperCase() ?? '';
            if (status.contains('ON_TIME') || status.contains('SUCCESS') || status.contains('ĐÚNG GIỜ')) {
              onTime++;
            } else if (status.contains('LATE') || status.contains('ĐI MUỘN')) {
              late++;
            }
          }
        }

        setState(() {
          _events = newEvents;
          _totalOnTime = onTime;
          _totalLate = late;
          // Giả định số ngày công chuẩn trong tháng trừ đi số ngày đã chấm
          _totalAbsent = 22 - (onTime + late); 
          if (_totalAbsent < 0) _totalAbsent = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Color _getStatusColor(String status) {
    status = status.toUpperCase();
    if (status.contains('ON_TIME') || status.contains('SUCCESS') || status.contains('ĐÚNG GIỜ')) return AppTheme.success;
    if (status.contains('LATE') || status.contains('ĐI MUỘN')) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('LỊCH SỬ CHẤM CÔNG', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchHistory),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNavy))
        : SingleChildScrollView(
            child: Column(
              children: [
                _buildStatsSection(),
                _buildCalendarSection(),
                _buildDayDetailSection(),
                const SizedBox(height: 30),
              ],
            ),
          ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("THỐNG KÊ THÁNG ${_focusedDay.month}", 
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy)),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: [
                      PieChartSectionData(value: _totalOnTime.toDouble(), color: AppTheme.success, radius: 10, showTitle: false),
                      PieChartSectionData(value: _totalLate.toDouble(), color: AppTheme.warning, radius: 10, showTitle: false),
                      PieChartSectionData(value: _totalAbsent.toDouble(), color: AppTheme.error.withOpacity(0.2), radius: 10, showTitle: false),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Column(
                  children: [
                    _buildStatRow("Đúng giờ", _totalOnTime, AppTheme.success),
                    _buildStatRow("Đi muộn", _totalLate, AppTheme.warning),
                    _buildStatRow("Vắng mặt", _totalAbsent, AppTheme.error),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.secondarySlate)),
          const Spacer(),
          Text("$value", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        eventLoader: _getEventsForDay,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(color: AppTheme.primaryNavy.withOpacity(0.3), shape: BoxShape.circle),
          selectedDecoration: const BoxDecoration(color: AppTheme.primaryNavy, shape: BoxShape.circle),
          markerDecoration: const BoxDecoration(color: AppTheme.info, shape: BoxShape.circle),
          markersMaxCount: 1,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            final event = events.first as Map<String, dynamic>;
            final status = event['status']?.toString() ?? '';
            return Container(
              margin: const EdgeInsets.only(top: 25),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayDetailSection() {
    final events = _getEventsForDay(_selectedDay ?? _focusedDay);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              "CHI TIẾT NGÀY ${DateFormat('dd/MM/yyyy').format(_selectedDay ?? _focusedDay)}",
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy),
            ),
          ),
          if (events.isEmpty)
            _buildEmptyDayState()
          else
            ...events.map((event) => _buildShiftCard(event)).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyDayState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, color: AppTheme.dividerColor, size: 48),
          const SizedBox(height: 12),
          Text("Không có dữ liệu chấm công", style: GoogleFonts.montserrat(color: AppTheme.secondarySlate, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildShiftCard(dynamic event) {
    final status = event['status']?.toString() ?? 'N/A';
    final color = _getStatusColor(status);
    final DateTime? checkIn = event['checkInTime'] != null ? DateTime.parse(event['checkInTime']) : null;
    final DateTime? checkOut = event['checkOutTime'] != null ? DateTime.parse(event['checkOutTime']) : null;

    return GestureDetector(
      onTap: () => _showShiftDetail(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['shiftName'] ?? 'Ca làm việc', 
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    checkIn != null ? "${DateFormat('HH:mm').format(checkIn)} - ${checkOut != null ? DateFormat('HH:mm').format(checkOut) : '--:--'}" : "Chưa vào ca",
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.secondarySlate),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status.contains('ON_TIME') || status.contains('SUCCESS') ? "ĐÚNG GIỜ" : (status.contains('LATE') ? "ĐI MUỘN" : status),
                style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.secondarySlate),
          ],
        ),
      ),
    );
  }

  void _showShiftDetail(dynamic event) {
    final DateTime? checkIn = event['checkInTime'] != null ? DateTime.parse(event['checkInTime']) : null;
    final DateTime? checkOut = event['checkOutTime'] != null ? DateTime.parse(event['checkOutTime']) : null;
    final color = _getStatusColor(event['status']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.dividerColor, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Chi tiết ca làm", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailItem(Icons.work_outline_rounded, "Tên ca", event['shiftName'] ?? 'Ca chuẩn'),
            _buildDetailItem(Icons.login_rounded, "Giờ vào", checkIn != null ? DateFormat('HH:mm:ss').format(checkIn) : "N/A", color: AppTheme.success),
            _buildDetailItem(Icons.logout_rounded, "Giờ ra", checkOut != null ? DateFormat('HH:mm:ss').format(checkOut) : "Chưa chấm ra", color: AppTheme.error),
            _buildDetailItem(Icons.location_on_outlined, "Vị trí", event['location'] ?? 'Văn phòng chính'),
            _buildDetailItem(Icons.info_outline_rounded, "Trạng thái", event['status'] ?? 'N/A', color: color),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ĐÓNG"),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.secondarySlate),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.montserrat(color: AppTheme.secondarySlate, fontSize: 13)),
          const Spacer(),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: color ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
