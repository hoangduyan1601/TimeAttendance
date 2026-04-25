import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartops_app/core/theme.dart';
import 'package:smartops_app/services/api_service.dart';

class AdminOvertimeReviewScreen extends StatefulWidget {
  const AdminOvertimeReviewScreen({super.key});

  @override
  State<AdminOvertimeReviewScreen> createState() => _AdminOvertimeReviewScreenState();
}

class _AdminOvertimeReviewScreenState extends State<AdminOvertimeReviewScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAllOvertimeRequests();
      if (mounted) {
        setState(() {
          _requests = response['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching OT requests: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reviewRequest(int id, String status) async {
    try {
      await _apiService.reviewOvertime(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã ${status == 'APPROVED' ? 'phê duyệt' : 'từ chối'} yêu cầu")),
        );
        _fetchRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('DUYỆT LÀM THÊM (OT)', 
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRequests),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _requests.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final item = _requests[index];
                return _buildRequestCard(item);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.dividerColor),
          const SizedBox(height: 16),
          Text("Không có yêu cầu OT nào cần xử lý", 
            style: GoogleFonts.montserrat(color: AppTheme.secondarySlate)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(dynamic item) {
    final status = item['status'] ?? 'PENDING';
    final isPending = status == 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryNavy.withOpacity(0.1),
                child: Text(item['fullName']?[0] ?? 'U', 
                  style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['fullName'] ?? 'N/A', 
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text("Ngày: ${item['date']}", 
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.secondarySlate)),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppTheme.secondarySlate),
              const SizedBox(width: 8),
              Text("Thời gian: ${item['startTime']} - ${item['endTime']}", 
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notes, size: 16, color: AppTheme.secondarySlate),
              const SizedBox(width: 8),
              Expanded(
                child: Text("Lý do: ${item['reason']}", 
                  style: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.textPrimary)),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reviewRequest(item['id'], 'REJECTED'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error)),
                    child: const Text("TỪ CHỐI"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _reviewRequest(item['id'], 'APPROVED'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    child: const Text("PHÊ DUYỆT"),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.warning;
    if (status == 'APPROVED') color = AppTheme.success;
    if (status == 'REJECTED') color = AppTheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, 
        style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
