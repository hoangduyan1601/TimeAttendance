import 'dart:math';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceRecognitionService {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  Map<String, List<double>> _registeredFaces = {};

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
      _isModelLoaded = true;
    } catch (e) {
      print('AI Model error: $e');
    }
  }

  String recognize(List<double> embedding) {
    return "AI Mobile Active";
  }
  
  // Các hàm extractEmbedding và calculateDistance giữ nguyên như trước...
}
