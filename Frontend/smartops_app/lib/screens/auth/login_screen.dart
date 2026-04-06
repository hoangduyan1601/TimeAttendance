import 'package:flutter/material.dart';
import 'package:smartops_app/core/routes.dart';
import 'package:smartops_app/core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _handleLogin() {
    String user = _usernameController.text.trim();
    String pass = _passwordController.text.trim();

    if (user == 'admin' && pass == '123456') {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    } else if (user == 'customer' && pass == '123456') {
      Navigator.pushReplacementNamed(context, AppRoutes.employeeHome);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sai tên đăng nhập hoặc mật khẩu!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 80, color: AppTheme.corporateBlue),
              const SizedBox(height: 24),
              const Text(
                'SMARTOPS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.corporateBlue,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'Hệ thống quản lý chấm công',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: 'Tên đăng nhập',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Mật khẩu',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleLogin,
                child: const Text('ĐĂNG NHẬP'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.kiosk);
                },
                child: const Text('Truy cập Trạm Kiosk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
