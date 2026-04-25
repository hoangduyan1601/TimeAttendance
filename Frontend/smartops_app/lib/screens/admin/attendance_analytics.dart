import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartops_app/core/theme.dart';

class AttendanceAnalytics extends StatelessWidget {
  final List<dynamic> reports;
  final List<dynamic> users;
  final List<dynamic> leaves;
  final int selectedMonth;
  final int selectedYear;

  const AttendanceAnalytics({
    super.key,
    required this.reports,
    required this.users,
    required this.leaves,
    required this.selectedMonth,
    required this.selectedYear,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiGrid(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildAttendanceTrendChart()),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _buildStatusDistribution()),
            ],
          ),
          const SizedBox(height: 24),
          _buildTopPerformers(),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    int totalEmp = users.length;
    int totalLogs = reports.length;
    int totalLates = reports.where((r) => r['status'] == 'LATE').length;
    double avgHours = totalLogs > 0 ? 8.2 : 0.0; // Simulated

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard("Tỷ lệ đi làm", "${((totalLogs/(totalEmp*22))*100).toStringAsFixed(1)}%", Icons.trending_up, AppTheme.success),
        _buildStatCard("Tỉ lệ đi muộn", "${((totalLates/totalLogs)*100).toStringAsFixed(1)}%", Icons.timer_outlined, AppTheme.error),
        _buildStatCard("Nghỉ phép tháng", "${leaves.length} đơn", Icons.event_available, AppTheme.info),
        _buildStatCard("Giờ làm TB", "${avgHours}h/ngày", Icons.bolt, AppTheme.warning),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.secondarySlate)),
              Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAttendanceTrendChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Biểu đồ xu hướng có mặt", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.dividerColor, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) => Text("${v.toInt()}", style: const TextStyle(fontSize: 10)))),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(24, (i) => FlSpot(i + 1, 8.0 + (i % 3))), // Simulated trend
                    isCurved: true,
                    color: AppTheme.primaryNavy,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppTheme.primaryNavy.withOpacity(0.1)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistribution() {
    int onTime = reports.where((r) => r['status'] == 'ON_TIME' || r['status'] == 'SUCCESS').length;
    int late = reports.where((r) => r['status'] == 'LATE').length;
    int leave = leaves.length;

    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Text("Phân bổ trạng thái", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 32),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(color: AppTheme.success, value: onTime.toDouble(), title: '${onTime}', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(color: AppTheme.error, value: late.toDouble(), title: '${late}', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(color: AppTheme.info, value: leave.toDouble(), title: '${leave}', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      children: [
        _legendItem("Đúng giờ", AppTheme.success),
        const SizedBox(height: 8),
        _legendItem("Đi muộn", AppTheme.error),
        const SizedBox(height: 8),
        _legendItem("Nghỉ phép", AppTheme.info),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.secondarySlate)),
      ],
    );
  }

  Widget _buildTopPerformers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Nhân viên xuất sắc nhất tháng", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          const Text("Dựa trên số giờ làm việc thực tế và tính đúng giờ"),
          // Simulated Top 3
          _buildTopRow(1, "Lê Hoàng Nam", "Phòng IT", "176.5h"),
          _buildTopRow(2, "Hoàng Thùy Linh", "Kinh doanh", "168.0h"),
          _buildTopRow(3, "Nguyễn Mai Phương", "Kinh doanh", "162.2h"),
        ],
      ),
    );
  }

  Widget _buildTopRow(int rank, String name, String dept, String hours) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: AppTheme.background, child: Text("$rank", style: const TextStyle(fontWeight: FontWeight.bold))),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(dept),
      trailing: Text(hours, style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
