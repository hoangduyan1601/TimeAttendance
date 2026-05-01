import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smartops_app/core/theme.dart';

class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  final List<Map<String, String>> _liveLogs = [
    {'name': 'Hoàng Duy An', 'time': '08:00:21', 'status': 'Hợp lệ'},
    {'name': 'Lê Văn B', 'time': '08:05:12', 'status': 'Hợp lệ'},
  ];

  void _simulateScan(bool isValid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) Navigator.pop(context);
        });
        return AlertDialog(
          backgroundColor: isValid ? Colors.green : Colors.red,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isValid ? Icons.check_circle : Icons.warning, color: Colors.white, size: 80),
              const SizedBox(height: 16),
              Text(
                isValid ? 'XÁC THỰC THÀNH CÔNG' : 'CẢNH BÁO GIAN LẬN',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              if (isValid)
                const Text(
                  'Xin chào, Hoàng Duy An!',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
            ],
          ),
        );
      },
    );

    if (isValid) {
      setState(() {
        _liveLogs.insert(0, {
          'name': 'Hoàng Duy An',
          'time': DateTime.now().toString().split(' ')[1].split('.')[0],
          'status': 'Hợp lệ'
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // Trái: Camera Viewfinder (70%)
          Expanded(
            flex: 7,
            child: Stack(
              children: [
                Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(Icons.videocam, color: Colors.white24, size: 100),
                  ),
                ),
                // Overlay khung quét
                Center(
                  child: Container(
                    width: 300,
                    height: 400,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white54, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const Positioned(
                  top: 40,
                  left: 40,
                  child: Text(
                    'KIOSK TERMINAL - LIVE FEED',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _simulateScan(true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Mô phỏng Quét OK'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () => _simulateScan(false),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Mô phỏng Quét Lỗi'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Phải: Live Log (30%)
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'NHẬT KÝ TRỰC TIẾP',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.corporateBlue),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _liveLogs.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final log = _liveLogs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(log['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(log['time']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log['status']!,
                                style: TextStyle(
                                  color: log['status'] == 'Hợp lệ' ? Colors.green : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
