import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartops_app/core/theme.dart';
import 'package:smartops_app/services/api_service.dart';

enum EkycStep { faceStraight, faceLeft, faceRight, faceUp }

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
  List<Uint8List> _facePhotos = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0],
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
      _facePhotos.add(bytes);

      setState(() {
        if (_currentStep == EkycStep.faceStraight) _currentStep = EkycStep.faceLeft;
        else if (_currentStep == EkycStep.faceLeft) _currentStep = EkycStep.faceRight;
        else if (_currentStep == EkycStep.faceRight) _currentStep = EkycStep.faceUp;
        else {
          _submitEkyc();
          return;
        }
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint("Error capturing: $e");
      setState(() => _isProcessing = false);
    }
  }

  void _submitEkyc() async {
    setState(() => _isProcessing = true);
    try {
      await _apiService.registerEkyc(_facePhotos[0], _facePhotos[0]);
      
      if (mounted) {
        _showSuccess();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e', style: GoogleFonts.montserrat()), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Biometric Registration Successful!', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getInstruction() {
    switch (_currentStep) {
      case EkycStep.faceStraight: return "LOOK STRAIGHT";
      case EkycStep.faceLeft: return "TURN FACE LEFT";
      case EkycStep.faceRight: return "TURN FACE RIGHT";
      case EkycStep.faceUp: return "LOOK UPWARDS";
    }
  }

  double _getStepProgress() {
    switch (_currentStep) {
      case EkycStep.faceStraight: return 0.25;
      case EkycStep.faceLeft: return 0.5;
      case EkycStep.faceRight: return 0.75;
      case EkycStep.faceUp: return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: AppTheme.info)));

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("ĐỊNH DANH BIOMETRIC", style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
        automaticallyImplyLeading: false,
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
                  _buildScanningLine(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningLine() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Positioned(
          top: 350 * value,
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
      onEnd: () {}, // Handled by repeating if needed, but here we just need a visual
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

  String _getInstructionTranslate() {
    switch (_currentStep) {
      case EkycStep.faceStraight: return "NHÌN THẲNG";
      case EkycStep.faceLeft: return "QUAY SANG TRÁI";
      case EkycStep.faceRight: return "QUAY SANG PHẢI";
      case EkycStep.faceUp: return "NGƯỚC LÊN TRÊN";
    }
  }
}
