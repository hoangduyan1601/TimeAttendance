import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'ocr_service_web.dart';

class OCRView extends StatefulWidget {
  const OCRView({super.key});

  @override
  State<OCRView> createState() => _OCRViewState();
}

class _OCRViewState extends State<OCRView> {
  CameraController? _controller;
  bool _isProcessing = false;
  String _ocrResult = "Đang chờ quét thẻ...";
  Map<String, String> _parsedData = {};

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(cameras.first, ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _scanCard() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _ocrResult = "Đang xử lý OCR (Tesseract.js)...";
    });

    try {
      // 1. Chụp ảnh từ camera
      final XFile image = await _controller!.takePicture();
      final Uint8List bytes = await image.readAsBytes();
      
      // 2. Chuyển sang Base64 để gửi sang JS
      final String base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";

      // 3. Gọi OCR Service
      final result = await OCRServiceWeb.scanCard(base64Image);

      // 4. Parse dữ liệu
      final parsed = OCRServiceWeb.parseCardData(result);

      if (mounted) {
        setState(() {
          _ocrResult = result;
          _parsedData = parsed;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ocrResult = "Lỗi: $e";
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Quét Thẻ (OCR Web)")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Preview Camera
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  CameraPreview(_controller!),
                  // Overlay khung thẻ
                  Center(
                    child: Container(
                      width: 300,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _scanCard,
              icon: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.camera_alt),
              label: Text(_isProcessing ? "Đang nhận diện..." : "Chụp & Quét Thẻ"),
            ),
            const Divider(height: 40),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Thông tin trích xuất:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  _buildInfoRow("Số thẻ/ID:", _parsedData['id_number'] ?? ""),
                  const SizedBox(height: 20),
                  const Text("Dữ liệu thô từ OCR:", style: TextStyle(color: Colors.grey)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    color: Colors.black12,
                    child: Text(_ocrResult),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Text(value, style: const TextStyle(color: Colors.blue, fontSize: 16)),
      ],
    );
  }
}
