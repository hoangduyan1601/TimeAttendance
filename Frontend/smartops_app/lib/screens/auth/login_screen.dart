import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartops_app/core/routes.dart';
import 'package:smartops_app/core/theme.dart';
import 'package:smartops_app/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleLogin() async {
    String user = _usernameController.text.trim();
    String pass = _passwordController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      _showError('Vui lòng nhập đầy đủ thông tin!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(user, pass);
      if (mounted) {
        final role = response['data']['user']['role'];
        if (role == 'ADMIN') {
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.employeeHome);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Đăng nhập thất bại. Vui lòng kiểm tra lại tài khoản.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: _buildCircle(300, AppTheme.primaryNavy.withOpacity(0.05)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildCircle(200, AppTheme.info.withOpacity(0.05)),
          ),
          
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand Logo Area
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            shape: BoxShape.circle,
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: const Icon(
                            Icons.fingerprint_rounded,
                            size: 64,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'SMARTOPS',
                              style: GoogleFonts.montserrat(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryNavy,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'NEXT-GEN ATTENDANCE SYSTEM',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.secondarySlate,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 56),
                      
                      // Welcome Text
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please sign in to continue',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      
                      // Login Form
                      _buildLabel('Username'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your username',
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.secondarySlate),
                          filled: true,
                          fillColor: AppTheme.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildLabel('Password'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.secondarySlate),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: AppTheme.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.montserrat(
                              color: AppTheme.primaryNavy,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Login Button
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNavy))
                          : Container(
                              decoration: BoxDecoration(
                                boxShadow: AppTheme.buttonShadow,
                              ),
                              child: ElevatedButton(
                                onPressed: _handleLogin,
                                child: const Text('SIGN IN'),
                              ),
                            ),
                      
                      const SizedBox(height: 48),
                      
                      // Kiosk Access
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 1,
                              width: 50,
                              color: AppTheme.dividerColor,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR ACCESS VIA',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondarySlate,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Container(
                              height: 1,
                              width: 50,
                              color: AppTheme.dividerColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.kiosk),
                          icon: const Icon(Icons.desktop_windows_outlined, size: 20),
                          label: const Text('KIOSK TERMINAL'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(200, 50),
                            side: const BorderSide(color: AppTheme.dividerColor),
                            foregroundColor: AppTheme.primaryNavy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                            textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
