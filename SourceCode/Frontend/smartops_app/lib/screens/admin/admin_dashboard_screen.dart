import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/enterprise_card.dart';
import '../../widgets/status_badge.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebar(context),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppTheme.dividerColor,
          ),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('SmartOps Admin Portal'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      backgroundColor: AppTheme.white,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: AppTheme.dividerColor, height: 1.0),
      ),
      actions: [
        Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm nhân viên, mã số...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                borderSide: const BorderSide(
                  color: AppTheme.corporateBlue,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppTheme.backgroundLight,
            ),
          ),
        ),
        const SizedBox(width: 16),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.file_download_outlined, size: 20),
          label: const Text('Xuất Báo Cáo (.xlsx)'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.corporateBlue,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.corporateBlue.withValues(alpha: 0.1),
              child: const Icon(
                Icons.admin_panel_settings,
                color: AppTheme.corporateBlue,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản trị viên',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Admin',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      color: AppTheme.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 16, top: 8),
            child: Text(
              'MENU QUẢN TRỊ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppTheme.textHint,
              ),
            ),
          ),
          const _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Giám sát trực tiếp',
            isSelected: true,
          ),
          const _SidebarItem(
            icon: Icons.badge_outlined,
            label: 'Quản lý Hồ sơ & eKYC',
          ),
          const _SidebarItem(
            icon: Icons.calendar_today_outlined,
            label: 'Thiết lập Ca làm việc',
          ),
          const _SidebarItem(
            icon: Icons.fact_check_outlined,
            label: 'Xét duyệt Đơn từ',
          ),
          const _SidebarItem(
            icon: Icons.edit_calendar_outlined,
            label: 'Hiệu chỉnh Chấm công',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Divider(),
          ),
          const _SidebarItem(
            icon: Icons.bar_chart_outlined,
            label: 'Báo cáo & Thống kê',
          ),
          const _SidebarItem(
            icon: Icons.settings_outlined,
            label: 'Cài đặt hệ thống',
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      color: AppTheme.backgroundLight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng quan hôm nay',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildMetricsRow(),
            const SizedBox(height: 32),
            Text(
              'Danh sách cần xử lý',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildDataTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Tổng NV',
            '120',
            Icons.people_alt_outlined,
            AppTheme.corporateBlue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Đã Check-in',
            '115',
            Icons.check_circle_outline,
            AppTheme.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Vắng mặt',
            '3',
            Icons.cancel_outlined,
            AppTheme.error,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Đi muộn',
            '2',
            Icons.access_time_outlined,
            AppTheme.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return EnterpriseCard(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return EnterpriseCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 56,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 64,
            headingRowColor: WidgetStateProperty.all(AppTheme.backgroundLight),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
            dataTextStyle: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            dividerThickness: 1,
            columns: const [
              DataColumn(label: Text('MÃ NV')),
              DataColumn(label: Text('HỌ TÊN')),
              DataColumn(label: Text('LOẠI TÁC VỤ')),
              DataColumn(label: Text('TRẠNG THÁI / CHI TIẾT')),
              DataColumn(label: Text('HÀNH ĐỘNG')),
            ],
            rows: [
              _buildDataRow(
                'NV-012',
                'Phạm Văn D',
                'eKYC mới',
                'Chờ duyệt khuôn mặt gốc',
                BadgeType.primary,
              ),
              _buildDataRow(
                'NV-008',
                'Hoàng Thị E',
                'Đơn nghỉ',
                'Nghỉ ốm (1 ngày)',
                BadgeType.neutral,
              ),
              _buildDataRow(
                'NV-005',
                'Lê Văn F',
                'Chấm công',
                'Đi muộn (Cần sửa giờ)',
                BadgeType.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(
    String id,
    String name,
    String taskType,
    String detail,
    BadgeType badgeType,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(id, style: const TextStyle(fontFamily: 'RobotoMono'))),
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.dividerColor,
                child: Text(
                  name[0],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(name),
            ],
          ),
        ),
        DataCell(Text(taskType)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusBadge(text: taskType, type: badgeType),
              const SizedBox(width: 8),
              Text(
                detail,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  minimumSize: const Size(64, 36),
                  elevation: 0,
                  backgroundColor: AppTheme.corporateBlue,
                  foregroundColor: AppTheme.white,
                ),
                child: const Text('Duyệt'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  minimumSize: const Size(64, 36),
                  side: const BorderSide(color: AppTheme.error),
                  foregroundColor: AppTheme.error,
                ),
                child: const Text('Từ chối'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.corporateBlue : AppTheme.textSecondary;
    final bgColor = isSelected
        ? AppTheme.corporateBlue.withValues(alpha: 0.1)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
