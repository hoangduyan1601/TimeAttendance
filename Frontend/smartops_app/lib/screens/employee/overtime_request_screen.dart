import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartops_app/core/theme.dart';
import 'package:smartops_app/services/api_service.dart';

class OvertimeRequestScreen extends StatefulWidget {
  const OvertimeRequestScreen({super.key});

  @override
  State<OvertimeRequestScreen> createState() => _OvertimeRequestScreenState();
}

class _OvertimeRequestScreenState extends State<OvertimeRequestScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 17, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 19, minute: 30);
  final TextEditingController _reasonController = TextEditingController();
  
  bool _isLoading = false;
  bool _isFetching = true;
  List<dynamic> _myRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchMyRequests();
  }

  Future<void> _fetchMyRequests() async {
    setState(() => _isFetching = true);
    try {
      final response = await _apiService.getMyOvertimeRequests();
      if (mounted) {
        setState(() {
          _myRequests = response['data'] ?? [];
          _isFetching = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching OT requests: $e");
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryNavy),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final String startStr = "${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00";
      final String endStr = "${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00";

      await _apiService.submitOvertime({
        "date": dateStr,
        "startTime": startStr,
        "endTime": endStr,
        "reason": _reasonController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gửi yêu cầu OT thành công")),
        );
        _reasonController.clear();
        _fetchMyRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('ĐĂNG KÝ LÀM THÊM (OT)', 
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRequestForm(),
            const SizedBox(height: 24),
            Text("LỊCH SỬ YÊU CẦU", 
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy)),
            const SizedBox(height: 12),
            _isFetching 
              ? const Center(child: CircularProgressIndicator())
              : _buildRequestList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tạo yêu cầu mới", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            // Chọn ngày
            InkWell(
              onTap: () => _selectDate(context),
              child: _buildInputDecorator("Ngày làm thêm", DateFormat('dd/MM/yyyy').format(_selectedDate), Icons.calendar_today_rounded),
            ),
            const SizedBox(height: 16),
            
            // Chọn giờ
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, true),
                    child: _buildInputDecorator("Giờ bắt đầu", _startTime.format(context), Icons.access_time_rounded),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, false),
                    child: _buildInputDecorator("Giờ kết thúc", _endTime.format(context), Icons.access_time_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Lý do
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Lý do làm thêm",
                hintText: "Nhập lý do thực hiện OT...",
              ),
              validator: (v) => (v == null || v.isEmpty) ? "Vui lòng nhập lý do" : null,
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("GỬI YÊU CẦU"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputDecorator(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.secondarySlate)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.dividerColor),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryNavy),
              const SizedBox(width: 10),
              Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestList() {
    if (_myRequests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 48, color: AppTheme.dividerColor),
            const SizedBox(height: 12),
            Text("Chưa có yêu cầu nào", style: GoogleFonts.montserrat(color: AppTheme.secondarySlate)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _myRequests.length,
      itemBuilder: (context, index) {
        final item = _myRequests[index];
        final status = item['status'] ?? 'PENDING';
        Color statusColor = AppTheme.warning;
        if (status == 'APPROVED') statusColor = AppTheme.success;
        if (status == 'REJECTED') statusColor = AppTheme.error;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.timer_outlined, color: statusColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${item['date']}", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("${item['startTime']} - ${item['endTime']}", 
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.secondarySlate)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
        );
      },
    );
  }
}
