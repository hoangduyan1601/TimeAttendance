import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartops_app/core/theme.dart';
import 'package:smartops_app/services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _history = [];
  bool _isLoading = true;
  int _totalDays = 0;
  int _lateDays = 0;
  String _totalHours = "00h 00m";
  String _filterType = 'MONTH'; // TODAY, WEEK, MONTH, CUSTOM

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _updateFilter(String type) {
    setState(() {
      _filterType = type;
      final now = DateTime.now();
      if (type == 'TODAY') {
        _startDate = now;
        _endDate = now;
      } else if (type == 'WEEK') {
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
      } else if (type == 'MONTH') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
      }
    });
    _fetchHistory();
  }

  void _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
      
      final response = await _apiService.getAttendanceHistory(
        startDate: startStr,
        endDate: endStr,
      );
      
      if (mounted) {
        setState(() {
          _history = response['data'] ?? [];
          _totalDays = _history.length;
          _lateDays = _history.where((item) => item['status'] == 'LATE' || item['status'] == 'Đi muộn').length;
          
          // Tính tổng giờ làm giả định hoặc từ backend nếu có
          double totalMins = 0;
          for (var item in _history) {
            if (item['checkInTime'] != null && item['checkOutTime'] != null) {
              final inTime = DateTime.parse(item['checkInTime']);
              final outTime = DateTime.parse(item['checkOutTime']);
              totalMins += outTime.difference(inTime).inMinutes;
            } else if (item['checkInTime'] != null) {
              // Nếu chỉ có check-in, giả định làm đến giờ hiện tại hoặc ca chuẩn
              totalMins += 480; // 8 tiếng
            }
          }
          int h = (totalMins / 60).floor();
          int m = (totalMins % 60).round();
          _totalHours = "${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m";
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'ON_TIME' || status == 'Đúng giờ' || status == 'SUCCESS') return AppTheme.success;
    if (status == 'LATE' || status == 'Đi muộn') return AppTheme.warning;
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
          IconButton(
            icon: const Icon(Icons.date_range_rounded), 
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context, 
                firstDate: DateTime(2020), 
                lastDate: DateTime.now(),
                initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked.start;
                  _endDate = picked.end;
                  _filterType = 'CUSTOM';
                });
                _fetchHistory();
              }
            }
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchHistory),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildStatsBanner(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNavy))
              : _history.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () async => _fetchHistory(),
                      color: AppTheme.primaryNavy,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _history.length,
                        itemBuilder: (context, index) => _buildHistoryCard(_history[index]),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: AppTheme.primaryNavy,
      padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _filterChip('Hôm nay', 'TODAY'),
          _filterChip('Tuần này', 'WEEK'),
          _filterChip('Tháng này', 'MONTH'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String type) {
    bool isSelected = _filterType == type;
    return GestureDetector(
      onTap: () => _updateFilter(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.white : Colors.transparent),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            color: isSelected ? AppTheme.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppTheme.primaryNavy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusXl)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('$_totalDays', 'TỔNG CÔNG', Icons.calendar_today_rounded),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatItem('$_lateDays', 'ĐI MUỘN', Icons.access_time_rounded),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatItem(_totalHours, 'TỔNG GIỜ', Icons.timer_outlined),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: AppTheme.dividerColor),
          const SizedBox(height: 16),
          Text("Chưa có dữ liệu chấm công", style: GoogleFonts.montserrat(color: AppTheme.secondarySlate, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'UNKNOWN';
    final color = _getStatusColor(status);
    final DateTime? checkIn = item['checkInTime'] != null ? DateTime.parse(item['checkInTime']) : null;
    final DateTime? checkOut = item['checkOutTime'] != null ? DateTime.parse(item['checkOutTime']) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checkIn != null ? DateFormat('EEEE, dd/MM').format(checkIn).toUpperCase() : "N/A",
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['shiftName'] ?? 'Ca chuẩn',
                    style: GoogleFonts.montserrat(fontSize: 11, color: AppTheme.secondarySlate, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.5), width: 0.5),
                ),
                child: Text(
                  status == 'ON_TIME' || status == 'SUCCESS' ? 'ĐÚNG GIỜ' : (status == 'LATE' ? 'ĐI MUỘN' : status),
                  style: GoogleFonts.montserrat(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildTimeInfo("VÀO CA", checkIn != null ? DateFormat('HH:mm').format(checkIn) : "--:--", Icons.login_rounded),
              const Spacer(),
              _buildTimeInfo("RA CA", checkOut != null ? DateFormat('HH:mm').format(checkOut) : "--:--", Icons.logout_rounded),
              const Spacer(),
              _buildTimeInfo("TỔNG GIỜ", "08h 00m", Icons.timer_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: AppTheme.secondarySlate),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.montserrat(fontSize: 9, color: AppTheme.secondarySlate, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(time, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }
}
