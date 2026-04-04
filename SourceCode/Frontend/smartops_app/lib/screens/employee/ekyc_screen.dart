import 'package:flutter/material.dart';

class EkycScreen extends StatefulWidget {
  const EkycScreen({super.key});

  @override
  State<EkycScreen> createState() => _EkycScreenState();
}

class _EkycScreenState extends State<EkycScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ĐĂNG KÝ EKYC')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gửi hồ sơ eKYC thành công!'), backgroundColor: Colors.green),
            );
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        steps: [
          Step(
            title: const Text('Chụp mặt trước CCCD'),
            content: _buildCameraPreview('Mặt trước CCCD'),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Chụp mặt sau CCCD'),
            content: _buildCameraPreview('Mặt sau CCCD'),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Xác thực khuôn mặt'),
            content: _buildCameraPreview('Chân dung (Selfie)'),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(String label) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.camera_alt, color: Colors.white, size: 50),
          Positioned(
            bottom: 10,
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
