import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartops_app/core/theme.dart';
import 'package:smartops_app/services/api_service.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = response['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      await _apiService.markNotificationAsRead(id);
      _fetchNotifications();
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('THÔNG BÁO HỆ THỐNG', 
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchNotifications),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _notifications.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final item = _notifications[index];
                return _buildNotificationCard(item);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: AppTheme.dividerColor),
          const SizedBox(height: 16),
          Text("Không có thông báo nào", 
            style: GoogleFonts.montserrat(color: AppTheme.secondarySlate)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(dynamic item) {
    final bool isRead = item['isRead'] ?? false;
    final String type = item['type'] ?? 'INFO';
    final DateTime createdAt = DateTime.parse(item['createdAt']);

    return GestureDetector(
      onTap: () => _markAsRead(item['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? AppTheme.white.withOpacity(0.7) : AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: isRead ? null : AppTheme.softShadow,
          border: isRead ? Border.all(color: AppTheme.dividerColor) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (type == 'ALERT' ? AppTheme.error : AppTheme.info).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                type == 'ALERT' ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                color: type == 'ALERT' ? AppTheme.error : AppTheme.info,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['title'] ?? 'Thông báo', 
                        style: GoogleFonts.montserrat(
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                          fontSize: 14,
                          color: isRead ? AppTheme.secondarySlate : AppTheme.textPrimary,
                        )),
                      if (!isRead)
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item['message'] ?? '', 
                    style: GoogleFonts.montserrat(fontSize: 13, color: isRead ? AppTheme.secondarySlate : AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Text(DateFormat('dd/MM/yyyy HH:mm').format(createdAt), 
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.secondarySlate)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
