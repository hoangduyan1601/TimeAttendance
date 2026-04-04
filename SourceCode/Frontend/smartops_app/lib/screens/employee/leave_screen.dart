import 'package:flutter/material.dart';
import 'package:smartops_app/core/theme.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final List<Map<String, String>> _leaveRequests = [
    {'type': 'Nghỉ phép năm', 'date': '10/04/2026', 'status': 'Đã duyệt', 'color': 'green'},
    {'type': 'Nghỉ ốm', 'date': '05/04/2026', 'status': 'Chờ duyệt', 'color': 'orange'},
  ];

  void _showAddLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo đơn xin nghỉ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Loại đơn'),
              items: const [
                DropdownMenuItem(value: 'Nghỉ phép năm', child: Text('Nghỉ phép năm')),
                DropdownMenuItem(value: 'Nghỉ ốm', child: Text('Nghỉ ốm')),
                DropdownMenuItem(value: 'Công tác', child: Text('Công tác')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Lý do', hintText: 'Nhập lý do nghỉ...'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Gửi đơn'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QUẢN LÝ ĐƠN TỪ')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lịch sử đơn đã gửi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: _showAddLeaveDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo đơn'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(120, 40)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _leaveRequests.length,
              itemBuilder: (context, index) {
                final item = _leaveRequests[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.description, color: AppTheme.corporateBlue),
                    title: Text(item['type']!),
                    subtitle: Text('Ngày: ${item['date']}'),
                    trailing: Text(
                      item['status']!,
                      style: TextStyle(
                        color: item['color'] == 'green' ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLeaveDialog,
        backgroundColor: AppTheme.corporateBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
