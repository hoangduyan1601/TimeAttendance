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

enum KioskState { idle, scanning, processing, success, failure }

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
  
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    // Dùng camera sau để quét QR ổn định hơn
    facing: CameraFacing.back,
    returnImage: true,
  );

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(_scanAnimationController);
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_currentState != KioskState.idle) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String qrToken = barcodes.first.rawValue!;
      _processIdentification(qrToken);
    }
  }

  Future<void> _processIdentification(String qrToken) async {
    setState(() {
      _currentState = KioskState.scanning;
      _statusMessage = "QR RECOGNIZED";
    });

    try {
      // Step 1: Resolve QR (Identification)
      final resolveResponse = await _apiService.resolveQr(qrToken);
      if (mounted) {
        setState(() {
          _identifiedUser = resolveResponse['data'];
          _currentQrToken = qrToken;
          _challenge = _pickChallenge();
          _statusMessage = _challengeLabel(_challenge!);
          _currentState = KioskState.processing;
        });

        // Stop QR scanner to free camera resources
        await _scannerController.stop();

        // Step 2: Init front camera for face capture
        await _initializeFaceCamera();

        // Step 2: Challenge–response capture (burst frames)
        final frames = await _captureChallengeFrames(durationMs: 1600, targetFps: 6);
        final base64Image = frames.isNotEmpty ? frames.last : "";

        final verifyResponse = await _apiService.verifyKiosk(
          "KIOSK-GATE-01",
          qrToken,
          base64Image,
          framesBase64: frames,
          challengeType: _challengeToApi(_challenge!),
        );
        
        if (mounted) {
          final data = verifyResponse['data'];
          _similarityScore = (data['similarityScore'] ?? 0.0) * 100;
          
          setState(() {
            _currentState = KioskState.success;
            _statusMessage = "ACCESS GRANTED";
            _liveLogs.insert(0, {
              'name': data['employeeName'],
              'time': DateFormat('HH:mm:ss').format(DateTime.now()),
              'status': 'AUTHORIZED',
              'score': _similarityScore,
              'isSuccess': true,
            });
          });
          
          _resetAfterDelay();
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = "ACCESS DENIED";
        bool isFraud = false;
        
        if (e is DioException && e.response?.data != null) {
          errorMessage = e.response?.data['message'] ?? "ACCESS DENIED";
          // Check if error message indicates fraud
          if (errorMessage.contains("gian lận")) {
            isFraud = true;
            errorMessage = "FRAUD DETECTED";
          }
        }
        
        setState(() {
          _currentState = KioskState.failure;
          _statusMessage = errorMessage.toUpperCase();
          _liveLogs.insert(0, {
            'name': _identifiedUser?['fullName'] ?? 'UNKNOWN',
            'time': DateFormat('HH:mm:ss').format(DateTime.now()),
            'status': isFraud ? 'FRAUD ALERT' : 'REJECTED',
            'score': 0.0,
            'isSuccess': false,
          });
        });
        _resetAfterDelay();
      }
    }
  }

  Future<void> _initializeFaceCamera() async {
    try {
      setState(() {
        _isFaceCameraReady = false;
      });

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("Không tìm thấy camera trên thiết bị");
      }

      final CameraDescription description = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      if (_faceCameraController != null) {
        await _faceCameraController!.dispose();
      }

      _faceCameraController = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _faceCameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isFaceCameraReady = true;
      });
    } catch (e) {
      throw Exception("Không thể khởi tạo camera khuôn mặt: $e");
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
        return "TURN LEFT";
      case LivenessChallenge.turnRight:
        return "TURN RIGHT";
      case LivenessChallenge.blink:
        return "BLINK";
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
      for (int i = 0; i < maxFrames; i++) {
        if (!mounted) break;
        final XFile photo = await _faceCameraController!.takePicture();
        final Uint8List bytes = await photo.readAsBytes();
        if (bytes.isNotEmpty) {
          frames.add(base64Encode(bytes));
        }
        await Future.delayed(Duration(milliseconds: intervalMs));
      }

      if (frames.length < 3) {
        throw Exception("Không đủ dữ liệu camera để xác thực liveness");
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
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _currentState = KioskState.idle;
          _identifiedUser = null;
          _currentQrToken = null;
          _statusMessage = "READY TO SCAN";
          _similarityScore = 0.0;
          _isFaceCameraReady = false;
          _isCapturingChallenge = false;
          _challenge = null;
        });

        // Cleanup face camera and restart QR scanner
        _faceCameraController?.dispose();
        _faceCameraController = null;
        _scannerController.start();
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
      body: ResponsiveLayout(
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
    );
  }

  Widget _buildCameraArea() {
    return Stack(
      children: [
        // Camera View (QR scan OR Face capture)
        Positioned.fill(
          child: Opacity(
            opacity: 0.8,
            child: _currentState == KioskState.processing
                ? (_isFaceCameraReady && _faceCameraController != null
                    ? CameraPreview(_faceCameraController!)
                    : const Center(
                        child: CircularProgressIndicator(color: AppTheme.info),
                      ))
                : MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  ),
          ),
        ),
        
        // Futuristic Overlay
        _buildTechOverlay(),
        
        // Status HUD
        _buildStatusHud(),
        
        // Scanning Animation
        if (_currentState == KioskState.scanning || _currentState == KioskState.processing)
          _buildScanningLine(),
          
        // Result Feedback
        if (_currentState == KioskState.success || _currentState == KioskState.failure)
          _buildResultOverlay(),
      ],
    );
  }

  Widget _buildTechOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10, width: 20),
        ),
        child: Stack(
          children: [
            // Corner Accents
            _buildCorner(Alignment.topLeft),
            _buildCorner(Alignment.topRight),
            _buildCorner(Alignment.bottomLeft),
            _buildCorner(Alignment.bottomRight),
            
            // Grid Lines (Subtle)
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SMARTOPS BIOMETRIC TERMINAL', 
            style: GoogleFonts.shareTechMono(color: AppTheme.info, fontSize: 24, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
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
        ],
      ),
    );
  }

  Widget _buildInfoTag(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
          Text(value, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScanningLine() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * _scanAnimation.value,
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
        );
      },
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
              Text(log['name'], style: GoogleFonts.shareTechMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(log['time'], style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: Text(log['status'], style: GoogleFonts.shareTechMono(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
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
