import 'package:flutter/material.dart';
import 'face_detector_view.dart';
import 'ocr_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Multi-Tool App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Multi-Tool")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMenuButton(
              context,
              "Nhận diện khuôn mặt",
              Icons.face,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => FaceDetectorView()))
            ),
            const SizedBox(height: 20),
            _buildMenuButton(
              context,
              "Quét thẻ (OCR)",
              Icons.credit_card,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OCRView()))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(250, 60),
        textStyle: const TextStyle(fontSize: 18)
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
    );
  }
}
