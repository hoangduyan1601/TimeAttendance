import 'package:flutter/material.dart';
import 'package:smartops_app/core/routes.dart';
import 'package:smartops_app/core/theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QUẢN TRỊ VIÊN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showShiftConfig(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.corporateBlue,
          indicatorColor: AppTheme.corporateBlue,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Nhân sự'),
            Tab(text: 'Duyệt đơn'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildEmployeeTab(),
          _buildLeaveApprovalTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard('Tổng nhân sự', '150', Icons.people, Colors.blue),
              _buildStatCard('Đã check-in', '142', Icons.check_circle, Colors.green),
            ],
          ),
          Row(
            children: [
              _buildStatCard('Đi muộn', '05', Icons.timer, Colors.orange),
              _buildStatCard('Vắng mặt', '08', Icons.cancel, Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lịch sử quét gần đây', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildMiniLog('Hoàng Duy An', '08:00', 'Đúng giờ'),
                  _buildMiniLog('Lê Văn B', '08:15', 'Đi muộn'),
                  _buildMiniLog('Nguyễn Thị C', '08:20', 'Đi muộn'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniLog(String name, String time, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text(time),
          Text(status, style: TextStyle(color: status == 'Đúng giờ' ? Colors.green : Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildEmployeeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Danh sách nhân viên', style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Thêm mới'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(120, 40)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('Mã NV')),
              DataColumn(label: Text('Họ tên')),
              DataColumn(label: Text('Thao tác')),
            ],
            rows: [
              DataRow(cells: [
                const DataCell(Text('NV-001')),
                const DataCell(Text('Hoàng Duy An')),
                DataCell(IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showManualAdjustment(context))),
              ]),
              const DataRow(cells: [
                DataCell(Text('NV-002')),
                DataCell(Text('Lê Văn B')),
                DataCell(Icon(Icons.edit, size: 20)),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveApprovalTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: const Text('Nghỉ phép năm - Nguyễn Văn X'),
            subtitle: const Text('Ngày: 10/04/2026 - Lý do: Giải quyết việc gia đình'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () {}),
                IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () {}),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShiftConfig(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thiết lập ca làm việc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Giờ bắt đầu', hintText: '08:00')),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(labelText: 'Giờ kết thúc', hintText: '17:00')),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(labelText: 'Thời gian châm chước (phút)', hintText: '15')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Lưu')),
        ],
      ),
    );
  }

  void _showManualAdjustment(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hiệu chỉnh chấm công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhân viên: Hoàng Duy An (NV-001)'),
            const SizedBox(height: 16),
            TextField(decoration: const InputDecoration(labelText: 'Giờ vào mới')),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(labelText: 'Lý do hiệu chỉnh', hintText: 'Nhập lý do...'), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Xác nhận')),
        ],
      ),
    );
  }
}
