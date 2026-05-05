import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartops_app/core/theme.dart';
import 'package:smartops_app/services/api_service.dart';

enum EkycStep { faceStraight }

class EkycScreen extends StatefulWidget {
  const EkycScreen({super.key});

  @override
  State<EkycScreen> createState() => _EkycScreenState();
}

class _EkycScreenState extends State<EkycScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  EkycStep _currentStep = EkycStep.faceStraight;
  
  final ApiService _apiService = ApiService();
  final List<Uint8List> _facePhotos = [];
  bool _isProcessing = false;
  
  String _currentStatus = "NOT_STARTED";
  String? _savedSelfieUrl;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    setState(() => _isProcessing = true);
    try {
      final profile = await _apiService.getMyProfile();
      if (mounted) {
        setState(() {
          _currentStatus = profile['data']['ekycStatus'] ?? "NOT_STARTED";
          _savedSelfieUrl = profile['data']['selfieUrl'];
          _isProcessing = false;
        });
        
        if (_currentStatus == "NOT_STARTED" || _currentStatus == "REJECTED") {
          _initializeCamera();
        }
      }
    } catch (e) {
      debugPrint("Error checking status: $e");
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      await _setupCamera(cameras, false);
    } catch (e) {
      debugPrint("Error init camera: $e");
    }
  }

  Future<void> _setupCamera(List<CameraDescription> cameras, bool useBack) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    CameraDescription description = cameras.firstWhere(
      (cam) => cam.lensDirection == (useBack ? CameraLensDirection.back : CameraLensDirection.front),
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) {
      setState(() => _isCameraInitialized = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureStep() async {
    if (!_isCameraInitialized || _isProcessing) return;
    
    setState(() => _isProcessing = true);
    try {
      final XFile photo = await _controller!.takePicture();
      final Uint8List bytes = await photo.readAsBytes();
      
      _facePhotos.clear();
      _facePhotos.add(bytes);
      
      // Gửi ngay lập tức sau khi chụp nhìn thẳng (Chỉ làm 1 bước cho ổn định)
      _submitEkyc();
      
    } catch (e) {
      debugPrint("Error capturing: $e");
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _submitEkyc() async {
    if (_facePhotos.isEmpty) return;
    
    try {
      await _apiService.registerEkyc(_facePhotos[0]);
      
      if (mounted) {
        _showSuccess();
        
        // Quan trọng: Tắt camera và chuyển trạng thái ngay để tránh đơ
        if (_controller != null) {
          await _controller!.dispose();
          _controller = null;
        }

        setState(() {
          _currentStatus = "PENDING";
          _isCameraInitialized = false;
          _facePhotos.clear();
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        String message = 'Đăng ký thất bại';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data['message'] != null) {
            message = data['message'].toString();
          } else {
            message = data.toString();
          }
        } else {
          message = 'Đăng ký thất bại: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message, style: GoogleFonts.montserrat()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đăng ký khuôn mặt thành công!', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getInstructionTranslate() {
    return "NHÌN THẲNG";
  }

  double _getStepProgress() {
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing && _currentStatus == "NOT_STARTED") {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: AppTheme.info)));
    }

    // Show Status Overlay if already PENDING or APPROVED
    if (_currentStatus == "PENDING" || _currentStatus == "APPROVED") {
      return _buildStatusView();
    }

    if (!_isCameraInitialized) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: AppTheme.info)));

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("ĐĂNG KÝ KHUÔN MẶT", style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
      ),
      body: Stack(
        children: [
          // Full Screen Camera
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          
          // Futuristic Overlay
          _buildScanningOverlay(),
          
          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
          
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: AppTheme.info)),
            ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut)),
                Align(
                  alignment: const Alignment(0, -0.2),
                  child: Container(
                    height: 350,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(150),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.2),
            child: Container(
              height: 350,
              width: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.info, width: 2),
                borderRadius: BorderRadius.circular(150),
              ),
              child: Stack(
                children: [
                  _buildScanningLine(350),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusView() {
    bool isApproved = _currentStatus == "APPROVED";
    bool isRejected = _currentStatus == "REJECTED";
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isApproved ? Icons.verified_user_rounded : (isRejected ? Icons.gpp_bad_rounded : Icons.pending_actions_rounded),
                        size: 80,
                        color: isApproved ? AppTheme.success : (isRejected ? AppTheme.error : AppTheme.warning),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isApproved ? "ĐÃ XÁC THỰC THÀNH CÔNG" : (isRejected ? "ĐỊNH DANH BỊ TỪ CHỐI" : "HỒ SƠ ĐANG CHỜ PHÊ DUYỆT"),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isApproved 
                          ? "Khuôn mặt của bạn đã được hệ thống phê duyệt. Bạn có thể chấm công tại Kiosk."
                          : (isRejected 
                              ? "Hồ sơ của bạn không được chấp nhận. Vui lòng thực hiện đăng ký lại với hình ảnh rõ nét hơn."
                              : "Thông tin định danh của bạn đã được gửi lên hệ thống. Vui lòng chờ Admin kiểm tra và phê duyệt."),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: AppTheme.secondarySlate,
                        ),
                      ),
                      if (_savedSelfieUrl != null) ...[
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          child: Image.network(
                            "http://localhost:9090/api/v1" + _savedSelfieUrl!,
                            height: 180,
                            width: 135,

                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 180,
                              width: 135,
                              color: AppTheme.background,
                              child: const Icon(Icons.broken_image, color: AppTheme.secondarySlate),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Ảnh định danh gốc", style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.secondarySlate, fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _checkStatus(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("CẬP NHẬT TRẠNG THÁI"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!isApproved)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentStatus = "NOT_STARTED";
                          _currentStep = EkycStep.faceStraight;
                          _facePhotos.clear();
                        });
                        _initializeCamera();
                      },
                      icon: const Icon(Icons.camera_front_rounded),
                      label: const Text("ĐĂNG KÝ LẠI ĐỊNH DANH"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: AppTheme.primaryNavy),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanningLine(double height) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Positioned(
          top: height * value,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: AppTheme.info.withOpacity(0.5), blurRadius: 10, spreadRadius: 1)],
              gradient: const LinearGradient(colors: [Colors.transparent, AppTheme.info, Colors.transparent]),
            ),
          ),
        );
      },
      onEnd: () {}, 
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.9), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getInstructionTranslate(),
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            "Vui lòng đưa khuôn mặt vào khung hình",
            style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _getStepProgress(),
                  backgroundColor: Colors.white10,
                  color: AppTheme.info,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                "${(_getStepProgress() * 100).toInt()}%",
                style: GoogleFonts.poppins(color: AppTheme.info, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _captureStep,
            child: Container(
              height: 80,
              width: 80,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
