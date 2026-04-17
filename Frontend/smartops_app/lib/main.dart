import 'package:flutter/material.dart';
import 'package:smartops_app/core/routes.dart';
import 'package:smartops_app/core/theme.dart';
import 'package:smartops_app/screens/admin/admin_dashboard_screen.dart';
import 'package:smartops_app/screens/auth/login_screen.dart';
import 'package:smartops_app/screens/employee/ekyc_screen.dart';
import 'package:smartops_app/screens/employee/history_screen.dart';
import 'package:smartops_app/screens/employee/home_screen.dart';
import 'package:smartops_app/screens/employee/schedule_screen.dart';
import 'package:smartops_app/screens/kiosk/kiosk_screen.dart';

void main() {
  runApp(const SmartOpsApp());
}

class SmartOpsApp extends StatelessWidget {
  const SmartOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartOps Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.employeeHome: (context) => const EmployeeHomeScreen(),
        AppRoutes.employeeEkyc: (context) => const EkycScreen(),
        AppRoutes.employeeHistory: (context) => const HistoryScreen(),
        AppRoutes.employeeSchedule: (context) => const ScheduleScreen(),
        AppRoutes.adminDashboard: (context) => const AdminDashboardScreen(),
        AppRoutes.kiosk: (context) => const KioskScreen(),
      },
    );
  }
}
