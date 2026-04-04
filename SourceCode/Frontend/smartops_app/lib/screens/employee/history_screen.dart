import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/enterprise_card.dart';
import '../../widgets/status_badge.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMonthSelector(),
              const SizedBox(height: 24),
              _buildStatistics(),
              const SizedBox(height: 32),
              _buildHistoryList(),
              const SizedBox(height: 32),
              _buildExportButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Lịch sử Check-in'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: AppTheme.textPrimary,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tháng 10/2026',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textPrimary,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.corporateBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
              ),
              child: Text(
                'Tóm tắt: 20 Công',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.corporateBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Tất cả', true),
              const SizedBox(width: 8),
              _buildFilterChip('Đúng giờ', false),
              const SizedBox(width: 8),
              _buildFilterChip('Muộn/Sớm', false),
              const SizedBox(width: 8),
              _buildFilterChip('Nghỉ phép', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (val) {},
      backgroundColor: AppTheme.white,
      selectedColor: AppTheme.corporateBlue.withValues(alpha: 0.1),
      checkmarkColor: AppTheme.corporateBlue,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.corporateBlue : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.corporateBlue : AppTheme.dividerColor,
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return EnterpriseCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê Vi phạm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.access_time_filled_outlined,
                  color: AppTheme.warning,
                  label: 'Đi muộn',
                  value: '2 lần',
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.dividerColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24.0),
                  child: _buildStatItem(
                    icon: Icons.cancel_outlined,
                    color: AppTheme.error,
                    label: 'Vắng không phép',
                    value: '0 lần',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi tiết theo ngày',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        EnterpriseCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final records = [
                _Record(
                  'T2, 12/10',
                  '07:55',
                  '17:05',
                  'Đúng giờ',
                  BadgeType.success,
                ),
                _Record(
                  'T3, 13/10',
                  '08:15',
                  '17:00',
                  'Đi muộn (15p)',
                  BadgeType.warning,
                ),
                _Record(
                  'T4, 14/10',
                  '07:50',
                  '17:10',
                  'Đúng giờ',
                  BadgeType.success,
                ),
                _Record(
                  'T5, 15/10',
                  '--:--',
                  '--:--',
                  'Nghỉ phép',
                  BadgeType.primary,
                ),
              ];
              final record = records[index];
              return _buildHistoryListItem(record);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryListItem(_Record record) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              record.date,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeText(record.checkIn),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '-',
                    style: TextStyle(color: AppTheme.dividerColor),
                  ),
                ),
                _buildTimeText(record.checkOut),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: StatusBadge(text: record.status, type: record.badgeType),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeText(String time) {
    return Text(
      time,
      style: TextStyle(
        fontFamily: 'RobotoMono',
        fontWeight: FontWeight.w500,
        color: time == '--:--' ? AppTheme.textHint : AppTheme.textSecondary,
        fontSize: 14,
      ),
    );
  }

  Widget _buildExportButton() {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.picture_as_pdf_outlined),
      label: const Text('XUẤT BẢNG CÔNG (.PDF)'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 1,
        backgroundColor: AppTheme.white,
        selectedItemColor: AppTheme.corporateBlue,
        unselectedItemColor: AppTheme.textHint,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_busy_outlined),
            activeIcon: Icon(Icons.event_busy),
            label: 'Xin nghỉ',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context); // Go back to Home
          }
        },
      ),
    );
  }
}

class _Record {
  final String date;
  final String checkIn;
  final String checkOut;
  final String status;
  final BadgeType badgeType;

  _Record(this.date, this.checkIn, this.checkOut, this.status, this.badgeType);
}
