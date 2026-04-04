import 'package:flutter/material.dart';
import 'core/routes.dart';
import 'core/theme.dart';

void main() {
  runApp(const SmartOpsApp());
}

class SmartOpsApp extends StatelessWidget {
  const SmartOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartOps Time Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.getRoutes(),
    );
  }
}
