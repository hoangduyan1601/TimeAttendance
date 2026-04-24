import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartops_app/core/constants.dart';
// Conditional import for web
import 'dart:html' as html if (dart.library.io) 'package:smartops_app/services/fake_html.dart';

class ApiService {
  final Dio _dio = Dio();
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Options> _getOptions() async {
    final token = await getToken();
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  // Auth
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'username': username, 'password': password},
      );
      if (response.statusCode == 200) {
        final data = response.data['data'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['accessToken']);
        await prefs.setString('user_role', data['user']['role']);
        await prefs.setInt('user_id', data['user']['id']);
        return response.data;
      }
      throw Exception('Login failed');
    } catch (e) {
      rethrow;
    }
  }

  // eKYC
  Future<Map<String, dynamic>> registerEkyc(Uint8List idCardBytes, Uint8List selfieBytes) async {
    try {
      final options = await _getOptions();
      final formData = FormData.fromMap({
        'id_card': MultipartFile.fromBytes(idCardBytes, filename: 'id_card.jpg'),
        'selfie': MultipartFile.fromBytes(selfieBytes, filename: 'selfie.jpg'),
      });
      final response = await _dio.post(
        ApiConstants.ekyc,
        data: formData,
        options: options,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // QR Code
  Future<Map<String, dynamic>> getQrCode() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(ApiConstants.qrCode, options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Kiosk Verify
  Future<Map<String, dynamic>> verifyKiosk(String kioskId, String qrToken, String base64Image) async {
    try {
      final response = await _dio.post(
        ApiConstants.kioskVerify,
        data: {
          'kioskId': kioskId,
          'qrToken': qrToken,
          'liveImageBase64': base64Image,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Get Live Logs
  Future<Map<String, dynamic>> getLiveLogs() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(ApiConstants.liveLogs, options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Admin Stats
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(ApiConstants.adminDashboard, options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Resolve QR
  Future<Map<String, dynamic>> resolveQr(String qrToken) async {
    try {
      final response = await _dio.post(
        ApiConstants.resolveQr,
        data: {'qrToken': qrToken},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Employee Attendance History
  Future<Map<String, dynamic>> getAttendanceHistory({String? startDate, String? endDate}) async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        ApiConstants.attendance,
        queryParameters: {
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
        options: options,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get('${ApiConstants.baseUrl}/employee/me', options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Employee Leave & Shift Change
  Future<Map<String, dynamic>> submitLeave(Map<String, dynamic> data) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post('${ApiConstants.baseUrl}/employee/leave', data: data, options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMyLeaves() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get('${ApiConstants.baseUrl}/employee/leave', options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitShiftChange(Map<String, dynamic> data) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post('${ApiConstants.baseUrl}/employee/shift-change', data: data, options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMyShiftChanges() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get('${ApiConstants.baseUrl}/employee/shift-change', options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Admin Reviews
  Future<Map<String, dynamic>> getPendingEkyc() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(ApiConstants.adminPendingEkyc, options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reviewEkyc(int userId, String status) async {
    try {
      final options = await _getOptions();
      final response = await _dio.put(
        ApiConstants.adminReviewEkyc(userId),
        data: {'status': status},
        options: options,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAllLeaves() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(ApiConstants.adminLeaves, options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reviewLeave(int leaveId, String status) async {
    try {
      final options = await _getOptions();
      final response = await _dio.put(
        ApiConstants.adminReviewLeave(leaveId),
        data: {'status': status},
        options: options,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAllShiftChangeRequests() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get('${ApiConstants.baseUrl}/admin/shifts/change-requests', options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reviewShiftChange(int requestId, String status) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/admin/shifts/change-requests/$requestId/review',
        queryParameters: {'status': status},
        options: options,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(ApiConstants.adminUsers, options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAttendanceReports(String start, String end) async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        ApiConstants.adminAttendance,
        queryParameters: {'startDate': start, 'endDate': end},
        options: options,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> exportAttendanceReport(String start, String end) async {
    try {
      final token = await getToken();
      final url = "${ApiConstants.baseUrl}/admin/reports/export?startDate=$start&endDate=$end&access_token=$token&type=detail";
      
      if (kIsWeb) {
        html.window.open(url, '_blank');
      } else {
        debugPrint("Export URL: $url");
      }
    } catch (e) {
      debugPrint("Export error: $e");
      rethrow;
    }
  }

  Future<void> exportAttendanceSummaryReport(String start, String end) async {
    try {
      final token = await getToken();
      final url = "${ApiConstants.baseUrl}/admin/reports/export?startDate=$start&endDate=$end&access_token=$token&type=summary";
      
      if (kIsWeb) {
        html.window.open(url, '_blank');
      } else {
        debugPrint("Export URL: $url");
      }
    } catch (e) {
      debugPrint("Export error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        ApiConstants.adminUsers,
        data: userData,
        options: options,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      final options = await _getOptions();
      final response = await _dio.put(
        "${ApiConstants.adminUsers}/$id",
        data: userData,
        options: options,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final options = await _getOptions();
      final response = await _dio.delete(
        "${ApiConstants.adminUsers}/$id",
        options: options,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createDepartment(Map<String, dynamic> data) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/admin/departments',
        data: data,
        options: options,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateDepartment(int id, Map<String, dynamic> data) async {
    try {
      final options = await _getOptions();
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/admin/departments/$id',
        data: data,
        options: options,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteDepartment(int id) async {
    try {
      final options = await _getOptions();
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}/admin/departments/$id',
        options: options,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDepartments() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get('${ApiConstants.baseUrl}/admin/departments', options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Shift Management
  Future<Map<String, dynamic>> getAllShifts() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get('${ApiConstants.baseUrl}/admin/shifts', options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createShift(Map<String, dynamic> data) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post('${ApiConstants.baseUrl}/admin/shifts', data: data, options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateShift(int id, Map<String, dynamic> data) async {
    try {
      final options = await _getOptions();
      final response = await _dio.put('${ApiConstants.baseUrl}/admin/shifts/$id', data: data, options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteShift(int id) async {
    try {
      final options = await _getOptions();
      final response = await _dio.delete('${ApiConstants.baseUrl}/admin/shifts/$id', options: options);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
