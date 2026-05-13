import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'painters/face_detector_painter.dart';
import 'face_recognition_service.dart';

class FaceDetectorView extends StatefulWidget {
  const FaceDetectorView({super.key});

  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );
  final FaceRecognitionService _recognitionService = FaceRecognitionService();
  
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  CameraController? _controller;
  int _cameraIndex = -1;
  String _recognizedName = "Đang quét...";

  @override
  void initState() {
    super.initState();
    _recognitionService.loadModel();
    _startLiveFeed();
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    _stopCamera();
    super.dispose();
  }

  Future<void> _stopCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nhận diện AI Đa Nền Tảng')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CameraPreview(_controller!),
              if (_customPaint != null)
                Positioned.fill(child: _customPaint!),
              if (kIsWeb)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black54,
                      child: Text(
                        'AI Web: $_recognizedName',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future _startLiveFeed() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      return;
    }

    final cameras = await availableCameras();
    _cameraIndex = cameras.indexWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    if (_cameraIndex == -1) _cameraIndex = 0;
    final camera = cameras[_cameraIndex];

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller?.initialize().then((_) {
      if (!mounted) return;
      if (kIsWeb) {
        // Web: Dùng vòng lặp để detect
        _webDetectionLoop();
      } else {
        _controller?.startImageStream(_processCameraImage);
      }
      setState(() {});
    });
  }

  Future<void> _webDetectionLoop() async {
    while (_canProcess && kIsWeb) {
      if (_controller != null && _controller!.value.isInitialized && !_isBusy) {
        _isBusy = true;
        try {
          final rects = await _recognitionService.detectWebFaces();
          if (mounted && _canProcess) {
            setState(() {
              _recognizedName = rects.isNotEmpty ? "Đã tìm thấy ${rects.length} mặt" : "Đang quét...";
              if (rects.isNotEmpty) {
                _customPaint = CustomPaint(
                  painter: FaceDetectorPainter(
                    [], 
                    const Size(640, 480),
                    InputImageRotation.rotation0deg,
                    webFaces: rects,
                    name: _recognizedName,
                  ),
                );
              } else {
                _customPaint = null;
              }
            });
          }
        } catch (e) {
          debugPrint("Detection error: $e");
        } finally {
          _isBusy = false;
        }
      }
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    _processImage(inputImage);
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null || kIsWeb) return null;

    final sensorOrientation = _controller!.description.sensorOrientation;
    InputImageRotation? rotation;
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (defaultTargetPlatform == TargetPlatform.android && format != InputImageFormat.yuv420) ||
        (defaultTargetPlatform == TargetPlatform.iOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.length != (defaultTargetPlatform == TargetPlatform.android ? 3 : 1)) {
      return null;
    }
    final plane = image.planes.first;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      return InputImage.fromBytes(
        bytes: allBytes.done().buffer.asUint8List(),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } else {
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    final faces = await _faceDetector.processImage(inputImage);
    
    if (faces.isNotEmpty && inputImage.bytes != null) {
      // Logic nhận diện AI (giả định đã load model)
      // Trong thực tế, bạn sẽ crop ảnh face.boundingBox và gửi vào _recognitionService
      _recognizedName = _recognitionService.recognize([]); // Cần truyền embedding thật
    }

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(
        faces,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        name: faces.isNotEmpty ? _recognizedName : null,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
