import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smartops_app/core/theme.dart';
import 'package:smartops_app/services/api_service.dart';
import 'package:smartops_app/widgets/responsive_layout.dart';
import 'package:smartops_app/services/fake_html.dart' if (dart.library.html) 'dart:html' as html;

enum KioskState { idle, scanning, processing, success, failure, transition }

enum LivenessChallenge { turnLeft, turnRight, blink }

class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final List<Map<String, dynamic>> _liveLogs = [];
  KioskState _currentState = KioskState.idle;
  
  Map<String, dynamic>? _identifiedUser;
  String? _currentQrToken;
  String _statusMessage = "READY TO SCAN";
  double _similarityScore = 0.0;

  CameraController? _faceCameraController;
  bool _isFaceCameraReady = false;
  bool _isCapturingChallenge = false;
  LivenessChallenge? _challenge;
  
  // Countdown state
  int _countdownValue = 0;
  bool _isCountingDown = false;
  
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  late MobileScannerController _scannerController;
  Key _scannerKey = UniqueKey();

  void _initScannerController() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.front,
      returnImage: true,
      autoStart: false,
    );
    _scannerKey = UniqueKey();
  }

  void _logSystem(String message, {bool isError = false}) {
    if (mounted) {
      setState(() {
        _liveLogs.insert(0, {
          'name': 'SYSTEM',
          'time': DateFormat('HH:mm:ss').format(DateTime.now()),
          'status': message.toUpperCase(),
          'score': 0.0,
          'isSuccess': !isError,
        });
        if (_liveLogs.length > 50) _liveLogs.removeLast();
      });
      debugPrint("[KIOSK LOG] $message");
    }
  }

  @override
  void initState() {
    super.initState();
    _initScannerController();
    _scanAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(_scanAnimationController);

    _logSystem("INITIALIZING HARDWARE...");

    // Chờ 2 giây để đảm bảo phiên cũ đã giải phóng camera hoàn toàn
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        try {
          await _scannerController.start();
          _logSystem("QR SCANNER READY");
        } catch (e) {
          _logSystem("CAMERA ERROR: $e", isError: true);
        }
      }
    });
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_currentState != KioskState.idle) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String qrToken = barcodes.first.rawValue!;
      _processIdentification(qrToken);
    }
  }

  bool _isWaitingForManualCapture = false;

  Future<void> _processIdentification(String qrToken) async {
    _logSystem("QR DETECTED, TRANSITIONING...");
    setState(() {
      _currentState = KioskState.transition;
      _statusMessage = "IDENTIFYING...";
    });

    try {
      // Step 1: Resolve QR (Identification)
      final resolveResponse = await _apiService.resolveQr(qrToken);
      if (!mounted) return;

      _identifiedUser = resolveResponse['data'];
      _currentQrToken = qrToken;
      
      _logSystem("NGƯỜI DÙNG: ${_identifiedUser?['fullName']}");
      
      setState(() {
        _statusMessage = "ĐANG CHUẨN BỊ CAMERA...";
      });

      // Dừng và giải phóng bộ quét QR
      _logSystem("ĐANG GIẢI PHÓNG BỘ QUÉT QR...");
      try {
        await _scannerController.stop();
        await _scannerController.dispose();
      } catch (e) {
        _logSystem("LỖI GIẢI PHÓNG: $e", isError: true);
      }
      
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      
      // Step 2: Init front camera for face capture
      await _initializeFaceCamera();
      
      if (!_isFaceCameraReady) {
        throw Exception("Camera không thể khởi động. Vui lòng thử lại.");
      }

      setState(() {
        _currentState = KioskState.processing;
        _statusMessage = "HÃY NHÌN THẲNG VÀO CAMERA";
        _isWaitingForManualCapture = true; // Bật cờ đợi nhấn nút
      });

    } catch (e) {
      _handleVerificationError(e);
    }
  }

  Future<void> _performManualCapture() async {
    if (_currentState != KioskState.processing || !_isWaitingForManualCapture) return;

    setState(() {
      _isWaitingForManualCapture = false;
      _statusMessage = "ĐANG CHỤP ẢNH XÁC THỰC...";
    });

    try {
      _logSystem("ĐANG CHỤP ẢNH...");
      final base64Image = await _captureFaceBase64();
      
      _logSystem("ĐANG GỬI ẢNH XÁC THỰC...");
      setState(() => _statusMessage = "ĐANG KIỂM TRA ĐỘ KHỚP...");

      final verifyResponse = await _apiService.verifyKiosk(
        "KIOSK-GATE-01",
        _currentQrToken!,
        base64Image,
      );
      
      if (mounted) {
        final data = verifyResponse['data'];
        _similarityScore = (data['similarityScore'] ?? 0.0) * 100;
        
        setState(() {
          _currentState = KioskState.success;
          _statusMessage = "XÁC THỰC THÀNH CÔNG";
          _liveLogs.insert(0, {
            'name': data['employeeName'],
            'time': DateFormat('HH:mm:ss').format(DateTime.now()),
            'status': 'ĐÃ XÁC THỰC',
            'score': _similarityScore,
            'isSuccess': true,
          });
        });
        
        _resetAfterDelay();
      }
    } catch (e) {
      _handleVerificationError(e);
    }
  }

  void _handleVerificationError(Object e) {
    _logSystem("PROCESS ERROR: $e", isError: true);
    if (mounted) {
      String errorMessage = "ACCESS DENIED";
      bool isFraud = false;
      double extractedScore = 0.0;
      
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data is Map) {
          errorMessage = e.response?.data['message'] ?? "XÁC THỰC THẤT BẠI";
        } else {
          errorMessage = "LỖI KẾT NỐI SERVER";
        }
        
        // Trích xuất độ khớp từ thông báo lỗi của backend nếu có
        final regExp = RegExp(r"Độ khớp: (\d+)%");
        final match = regExp.firstMatch(errorMessage);
        if (match != null) {
          extractedScore = double.tryParse(match.group(1) ?? "0") ?? 0.0;
        }

        if (errorMessage.contains("gian lận") || errorMessage.contains("FRAUD")) {
          isFraud = true;
          errorMessage = "PHÁT HIỆN GIAN LẬN";
        }
      } else {
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      }
      
      setState(() {
        _currentState = KioskState.failure;
        _statusMessage = errorMessage.toUpperCase();
        _similarityScore = extractedScore;
        _isWaitingForManualCapture = false;
        _liveLogs.insert(0, {
          'name': _identifiedUser?['fullName'] ?? 'UNKNOWN',
          'time': DateFormat('HH:mm:ss').format(DateTime.now()),
          'status': isFraud ? 'FRAUD ALERT' : 'REJECTED',
          'score': extractedScore,
          'isSuccess': false,
        });
      });
      _resetAfterDelay();
    }
  }

  bool _isInitializingCamera = false;

  Future<void> _initializeFaceCamera() async {
    if (_isInitializingCamera) return;
    _isInitializingCamera = true;

    try {
      _logSystem("FACE CAMERA INIT START...");
      if (mounted) {
        setState(() {
          _isFaceCameraReady = false;
        });
      }

      if (_faceCameraController != null) {
        _logSystem("DISPOSING OLD FACE CAMERA...");
        try {
          await _faceCameraController!.dispose();
        } catch (_) {}
        _faceCameraController = null;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _logSystem("KHÔNG TÌM THẤY CAMERA", isError: true);
        return;
      }

      CameraDescription? selected;
      try {
        selected = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
        );
      } catch (_) {}
      selected ??= cameras.first;

      _logSystem("SỬ DỤNG CAMERA: ${selected.name}");

      _faceCameraController = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _logSystem("KHỞI TẠO CONTROLLER...");
      int retries = 0;
      while (retries < 3) {
        try {
          await _faceCameraController!.initialize();
          _logSystem("CAMERA KHỞI TẠO THÀNH CÔNG");
          break;
        } catch (e) {
          retries++;
          _logSystem("THỬ LẠI LẦN $retries: $e", isError: true);
          if (retries >= 3) rethrow;
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (!mounted) return;
      setState(() {
        _isFaceCameraReady = true;
      });
    } catch (e) {
      _logSystem("LỖI CAMERA NGHIÊM TRỌNG: $e", isError: true);
    } finally {
      _isInitializingCamera = false;
    }
  }

  void _hardRefresh() {
    _logSystem("ĐANG TẢI LẠI TRANG...");
    html.window.location.reload();
  }

  Future<void> _manualReset() async {
    _logSystem("ĐANG KHỞI TẠO LẠI PHẦN CỨNG...");
    try {
      if (mounted) {
        setState(() {
          _currentState = KioskState.transition;
          _statusMessage = "ĐANG RESET...";
        });
      }

      try { 
        await _scannerController.stop(); 
        await _scannerController.dispose();
      } catch (_) {}

      if (_faceCameraController != null) {
        try { await _faceCameraController!.dispose(); } catch (_) {}
        _faceCameraController = null;
      }

      _logSystem("CHỜ GIẢI PHÓNG TÀI NGUYÊN (3S)...");
      await Future.delayed(const Duration(seconds: 3));

      _initScannerController();

      if (mounted) {
        await _scannerController.start();
        _logSystem("RESET HOÀN TẤT");
        setState(() {
          _currentState = KioskState.idle;
          _statusMessage = "SẴN SÀNG QUÉT";
          _isFaceCameraReady = false;
        });
      }
    } catch (e) {
      _logSystem("LỖI RESET: $e", isError: true);
      if (mounted) {
        setState(() {
          _currentState = KioskState.failure;
          _statusMessage = "LỖI PHẦN CỨNG";
        });
      }
    }
  }

  LivenessChallenge _pickChallenge() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final idx = now % 3;
    if (idx == 0) return LivenessChallenge.turnLeft;
    if (idx == 1) return LivenessChallenge.turnRight;
    return LivenessChallenge.blink;
  }

  String _challengeToApi(LivenessChallenge c) {
    switch (c) {
      case LivenessChallenge.turnLeft:
        return "TURN_LEFT";
      case LivenessChallenge.turnRight:
        return "TURN_RIGHT";
      case LivenessChallenge.blink:
        return "BLINK";
    }
  }

  String _challengeLabel(LivenessChallenge c) {
    switch (c) {
      case LivenessChallenge.turnLeft:
        return "QUAY MẶT SANG TRÁI";
      case LivenessChallenge.turnRight:
        return "QUAY MẶT SANG PHẢI";
      case LivenessChallenge.blink:
        return "HÃY NHÁY MẮT";
    }
  }

  Future<void> _startChallengeSequence() async {
    setState(() {
      _isCountingDown = true;
      _countdownValue = 3;
    });

    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdownValue = i);
      await Future.delayed(const Duration(seconds: 1));
    }

    if (mounted) {
      setState(() {
        _isCountingDown = false;
        _countdownValue = 0;
      });
    }
  }

  Future<List<String>> _captureChallengeFrames({
    required int durationMs,
    required int targetFps,
  }) async {
    if (_faceCameraController == null || !_isFaceCameraReady) {
      throw Exception("Camera khuôn mặt chưa sẵn sàng");
    }
    if (_isCapturingChallenge) return [];

    final List<String> frames = [];
    final int intervalMs = (1000 / targetFps).round();
    final int maxFrames = (durationMs / intervalMs).ceil();

    setState(() {
      _isCapturingChallenge = true;
    });

    try {
      // Small initial delay to ensure UI transition is smooth
      await Future.delayed(const Duration(milliseconds: 500));

      for (int i = 0; i < maxFrames; i++) {
        if (!mounted) break;
        
        try {
          final XFile photo = await _faceCameraController!.takePicture();
          final Uint8List bytes = await photo.readAsBytes();
          if (bytes.isNotEmpty) {
            frames.add(base64Encode(bytes));
          }
        } catch (e) {
          debugPrint("Frame capture error at $i: $e");
        }
        
        await Future.delayed(Duration(milliseconds: intervalMs));
      }

      if (frames.length < 5) {
        throw Exception("Dữ liệu camera không đủ. Vui lòng thử lại.");
      }

      return frames;
    } finally {
      if (mounted) {
        setState(() {
          _isCapturingChallenge = false;
        });
      }
    }
  }

  Future<String> _captureFaceBase64() async {
    if (_faceCameraController == null || !_isFaceCameraReady) {
      throw Exception("Camera khuôn mặt chưa sẵn sàng");
    }
    try {
      final XFile photo = await _faceCameraController!.takePicture();
      final Uint8List bytes = await photo.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception("Không nhận được ảnh từ camera");
      }
      return base64Encode(bytes);
    } catch (e) {
      throw Exception("Chụp ảnh khuôn mặt thất bại: $e");
    }
  }

  void _resetAfterDelay() {
    Future.delayed(const Duration(seconds: 4), () async {
      if (!mounted) return;

      if (_faceCameraController != null) {
        _logSystem("DỌN DẸP CAMERA...");
        try {
          await _faceCameraController!.dispose();
        } catch (_) {}
        _faceCameraController = null;
      }

      await Future.delayed(const Duration(milliseconds: 1000));
      
      _logSystem("KHỞI TẠO LẠI QUÉT QR...");
      _initScannerController();
      
      try {
        await _scannerController.start();
        _logSystem("SẴN SÀNG QUÉT QR");
      } catch (e) {
        _logSystem("LỖI KHỞI ĐỘNG QR: $e", isError: true);
      }

      if (mounted) {
        setState(() {
          _currentState = KioskState.idle;
          _identifiedUser = null;
          _currentQrToken = null;
          _statusMessage = "SẴN SÀNG QUÉT";
          _similarityScore = 0.0;
          _isFaceCameraReady = false;
          _isCapturingChallenge = false;
          _challenge = null;
          _isCountingDown = false;
          _countdownValue = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _scanAnimationController.dispose();
    _faceCameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: isMobile ? AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Text('KIOSK TERMINAL', style: GoogleFonts.shareTechMono(color: AppTheme.info)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ) : null,
      body: SizedBox.expand(
        child: ResponsiveLayout(
          mobileBody: Column(
            children: [
              Expanded(
                flex: 2,
                child: _buildCameraArea(),
              ),
              Expanded(
                flex: 1,
                child: _buildSidePanel(isMobile: true),
              ),
            ],
          ),
          desktopBody: Row(
            children: [
              Expanded(
                flex: 7,
                child: _buildCameraArea(),
              ),
              _buildSidePanel(isMobile: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeOverlay() {
    return Positioned(
      top: 120,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.info.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(color: AppTheme.info.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isCountingDown ? "CHUẨN BỊ" : "ĐANG THỰC HIỆN",
                style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 14, letterSpacing: 4),
              ),
              const SizedBox(height: 16),
              if (_isCountingDown)
                Text(
                  "$_countdownValue",
                  style: GoogleFonts.shareTechMono(color: AppTheme.info, fontSize: 80, fontWeight: FontWeight.bold),
                )
              else
                Text(
                  _challengeLabel(_challenge!).toUpperCase(),
                  style: GoogleFonts.shareTechMono(color: AppTheme.info, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 6),
                ),
              const SizedBox(height: 24),
              if (_isCapturingChallenge)
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      const LinearProgressIndicator(
                        color: AppTheme.info, 
                        backgroundColor: Colors.white10,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 12),
                      Text("VUI LÒNG GIỮ NGUYÊN TƯ THẾ", style: GoogleFonts.shareTechMono(color: AppTheme.info, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else if (!_isCountingDown)
                Text("KHỞI TẠO CAMERA...", style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraArea() {
    return Stack(
      children: [
        Positioned.fill(
          child: _buildMainCameraContent(),
        ),
        
        _buildTechOverlay(),
        _buildStatusHud(),
        
        if (_currentState == KioskState.scanning || _currentState == KioskState.processing)
          _buildScanningLine(),

        if (_currentState == KioskState.processing && _challenge != null)
          _buildChallengeOverlay(),

        if (_currentState == KioskState.processing && _isWaitingForManualCapture)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppTheme.info.withOpacity(0.5)),
                    ),
                    child: Text(
                      "VUI LÒNG NHÌN THẲNG VÀO CAMERA",
                      style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _performManualCapture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(color: AppTheme.info.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: AppTheme.info, size: 32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "NHẤN NÚT ĐỂ XÁC THỰC",
                    style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 12, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ),
          
        if (_currentState == KioskState.success || _currentState == KioskState.failure)
          _buildResultOverlay(),
      ],
    );
  }

  Widget _buildMainCameraContent() {
    switch (_currentState) {
      case KioskState.processing:
        return _isFaceCameraReady && _faceCameraController != null
            ? CameraPreview(_faceCameraController!)
            : const Center(child: CircularProgressIndicator(color: AppTheme.info));
      
      case KioskState.transition:
        return const Center(child: CircularProgressIndicator(color: AppTheme.info));
      
      case KioskState.success:
      case KioskState.failure:
        return Container(color: Colors.black); // Blank background for results

      case KioskState.idle:
      case KioskState.scanning:
      default:
        return MobileScanner(
          key: _scannerKey,
          controller: _scannerController,
          onDetect: _onDetect,
          placeholderBuilder: (context, child) => const Center(child: CircularProgressIndicator(color: AppTheme.info)),
          errorBuilder: (context, error, child) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    "HARDWARE INITIALIZATION ERROR",
                    style: GoogleFonts.shareTechMono(color: AppTheme.error, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      error.errorDetails?.message ?? "THE SYSTEM ENCOUNTERED AN ERROR STARTING THE VIDEO SOURCE.",
                      style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _manualReset,
                        icon: const Icon(Icons.refresh),
                        label: Text("RETRY RESET", style: GoogleFonts.shareTechMono(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.info.withOpacity(0.1),
                          foregroundColor: AppTheme.info,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          side: const BorderSide(color: AppTheme.info, width: 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
    }
  }

  Widget _buildTechOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10, width: 20),
        ),
        child: Stack(
          children: [
            _buildCorner(Alignment.topLeft),
            _buildCorner(Alignment.topRight),
            _buildCorner(Alignment.bottomLeft),
            _buildCorner(Alignment.bottomRight),
            
            Positioned.fill(
              child: CustomPaint(painter: GridPainter()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight ? const BorderSide(color: AppTheme.info, width: 4) : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? const BorderSide(color: AppTheme.info, width: 4) : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? const BorderSide(color: AppTheme.info, width: 4) : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? const BorderSide(color: AppTheme.info, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHud() {
    return Positioned(
      top: 40,
      left: 40,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SMARTOPS BIOMETRIC TERMINAL', 
              style: GoogleFonts.shareTechMono(color: AppTheme.info, fontSize: 24, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Text('SYSTEM STATUS: OPERATIONAL', 
                  style: GoogleFonts.shareTechMono(color: Colors.green, fontSize: 12, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoTag("GATE ID", "GATE-MAIN-01"),
            _buildInfoTag("MODE", "AI-ENHANCED SCAN"),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _manualReset,
              icon: const Icon(Icons.refresh, size: 14),
              label: Text("RESET HARDWARE", style: GoogleFonts.shareTechMono(fontSize: 10)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: AppTheme.info,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                side: const BorderSide(color: AppTheme.info, width: 0.5),
                minimumSize: const Size(0, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
          Text(value, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScanningLine() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: constraints.maxHeight * _scanAnimation.value,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(color: AppTheme.info.withOpacity(0.5), blurRadius: 15, spreadRadius: 2),
                        ],
                        gradient: const LinearGradient(
                          colors: [Colors.transparent, AppTheme.info, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildResultOverlay() {
    final bool isSuccess = _currentState == KioskState.success;
    final Color color = isSuccess ? AppTheme.success : AppTheme.error;
    
    return Positioned.fill(
      child: Container(
        color: color.withOpacity(0.2),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 4),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 40)],
                ),
                child: Icon(isSuccess ? Icons.verified_user_rounded : Icons.gpp_bad_rounded, size: 80, color: color),
              ),
              const SizedBox(height: 40),
              Text(isSuccess ? "ACCESS GRANTED" : "ACCESS DENIED", 
                style: GoogleFonts.shareTechMono(color: color, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8)),
              const SizedBox(height: 16),
              if (isSuccess)
                Text(_identifiedUser?['fullName']?.toUpperCase() ?? "EMPLOYEE", 
                  style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 24, letterSpacing: 4)),
              if (!isSuccess)
                Text("INVALID CREDENTIALS", 
                  style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 18, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text("MATCH CONFIDENCE: ${_similarityScore.toStringAsFixed(1)}%", 
                style: GoogleFonts.shareTechMono(color: color.withOpacity(0.8), fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidePanel({required bool isMobile}) {
    Widget content = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: isMobile ? const Border(top: BorderSide(color: Colors.white10, width: 1)) : const Border(left: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: Colors.black26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TERMINAL LOGS', style: GoogleFonts.shareTechMono(color: AppTheme.info, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('REAL-TIME TRAFFIC MONITORING', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _liveLogs.length,
              itemBuilder: (context, index) => _buildLogEntry(_liveLogs[index]),
            ),
          ),
          _buildCurrentStatusFooter(),
        ],
      ),
    );

    if (isMobile) {
      return content;
    } else {
      return Expanded(
        flex: 3,
        child: content,
      );
    }
  }

  Widget _buildLogEntry(Map<String, dynamic> log) {
    final bool isSuccess = log['isSuccess'] ?? false;
    final Color color = isSuccess ? AppTheme.success : AppTheme.error;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  log['name'], 
                  style: GoogleFonts.shareTechMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(log['time'], style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    log['status'], 
                    style: GoogleFonts.shareTechMono(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text('${log['score'].toStringAsFixed(1)}% MATCH', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.black26,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CURRENT STATE', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
              Text(_statusMessage, 
                style: GoogleFonts.shareTechMono(
                  color: _currentState == KioskState.success ? AppTheme.success : (_currentState == KioskState.failure ? AppTheme.error : AppTheme.info),
                  fontWeight: FontWeight.bold, 
                  fontSize: 12
                )),
            ],
          ),
          if (_currentState == KioskState.processing && _challenge != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CHALLENGE', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
                Text(
                  _challengeLabel(_challenge!),
                  style: GoogleFonts.shareTechMono(color: AppTheme.info, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _currentState == KioskState.processing ? null : 1.0,
            backgroundColor: Colors.white10,
            color: AppTheme.info,
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (var i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), paint);
    }
    for (var i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
