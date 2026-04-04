import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/employee/home_screen.dart';
import '../screens/employee/history_screen.dart';
import '../screens/kiosk/kiosk_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';

class AppRoutes {
  static const String   login = '/login';
  static const String home = '/';
  static const String history = '/history';
  static const String kiosk = '/kiosk';
  static const String admin = '/admin';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      home: (context) => const HomeScreen(),
      history: (context) => const HistoryScreen(),
      kiosk: (context) => const KioskScreen(),
      admin: (context) => const AdminDashboardScreen(),
    };
  }
}
