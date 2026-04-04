import 'package:flutter/material.dart';
import 'package:smartops_app/core/theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu giả lập
    final List<Map<String, dynamic>> history = [
      {'date': '04/04/2026', 'in': '08:00', 'out': '17:05', 'status': 'Đúng giờ', 'color': Colors.green},
      {'date': '03/04/2026', 'in': '08:15', 'out': '17:00', 'status': 'Đi muộn', 'color': Colors.orange},
      {'date': '02/04/2026', 'in': '07:55', 'out': '17:10', 'status': 'Đúng giờ', 'color': Colors.green},
      {'date': '01/04/2026', 'in': '08:02', 'out': '17:00', 'status': 'Đúng giờ', 'color': Colors.green},
      {'date': '31/03/2026', 'in': '08:10', 'out': '17:00', 'status': 'Đi muộn', 'color': Colors.orange},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('LỊCH SỬ CHẤM CÔNG'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.corporateBlue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('22', 'Ngày công'),
                _buildStat('02', 'Đi muộn'),
                _buildStat('00', 'Vắng mặt'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(item['date'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('In: ${item['in']} - Out: ${item['out']}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: item['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: item['color']),
                      ),
                      child: Text(
                        item['status'],
                        style: TextStyle(color: item['color'], fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
