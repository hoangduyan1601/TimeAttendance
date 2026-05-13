import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(
    this.faces, 
    this.absoluteImageSize, 
    this.rotation, {
    this.webFaces,
    this.name,
    this.mirror = true, // Mặc định là true cho front camera
  });

  final List<Face> faces;
  final List<Rect>? webFaces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final String? name;
  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 // Giảm độ dày nét vẽ một chút
      ..color = Colors.greenAccent; // Đổi sang màu xanh cho dễ nhìn

    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    // Xử lý Web
    if (webFaces != null) {
      for (final Rect rect in webFaces!) {
        // Nếu mirror = true, đảo ngược tọa độ X
        final double left = mirror ? (1.0 - rect.left - rect.width) : rect.left;

        final drawRect = Rect.fromLTWH(
          left * size.width,
          rect.top * size.height,
          rect.width * size.width,
          rect.height * size.height,
        );
        canvas.drawRect(drawRect, paint);

        if (name != null) {
          _drawName(canvas, drawRect, textPainter);
        }
      }
    }

    // Xử lý Mobile
    for (final Face face in faces) {
      final drawRect = Rect.fromLTRB(
        face.boundingBox.left * size.width / absoluteImageSize.width,
        face.boundingBox.top * size.height / absoluteImageSize.height,
        face.boundingBox.right * size.width / absoluteImageSize.width,
        face.boundingBox.bottom * size.height / absoluteImageSize.height,
      );
      canvas.drawRect(drawRect, paint);

      if (name != null) {
        _drawName(canvas, drawRect, textPainter);
      }
    }
  }

  void _drawName(Canvas canvas, Rect rect, TextPainter textPainter) {
    textPainter.text = TextSpan(
      text: name,
      style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(rect.left, rect.top - 22));
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) => true;
}
