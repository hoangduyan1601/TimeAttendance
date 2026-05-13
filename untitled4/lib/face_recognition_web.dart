import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';

@JS('detectFaces')
external JSPromise<JSAny?> jsDetectFaces(web.HTMLVideoElement video);

class FaceRecognitionService {
  Future<void> loadModel() async {
    // Model được load tự động trong index.html
  }

  String recognize(List<double> embedding) {
    return "Web User";
  }

  Future<List<Rect>> detectWebFaces() async {
    try {
      final videos = web.document.querySelectorAll('video');
      if (videos.length == 0) return [];
      
      web.HTMLVideoElement? video;
      for (int i = 0; i < videos.length; i++) {
        final v = videos.item(i) as web.HTMLVideoElement;
        if (v.videoWidth > 0) {
          video = v;
          break;
        }
      }
      if (video == null) return [];
      
      final resultsJS = await jsDetectFaces(video).toDart;
      if (resultsJS == null) return [];

      final results = resultsJS as JSObject;
      final int length = (results.getProperty('length'.toJS) as JSNumber).toDartInt;
      
      List<Rect> faceRects = [];
      for (var i = 0; i < length; i++) {
        final detection = results.getProperty(i.toJS) as JSObject;
        
        // Tọa độ đã được chuẩn hóa (0.0 -> 1.0) từ JS
        final double x = (detection.getProperty('x'.toJS) as JSNumber).toDartDouble;
        final double y = (detection.getProperty('y'.toJS) as JSNumber).toDartDouble;
        final double w = (detection.getProperty('w'.toJS) as JSNumber).toDartDouble;
        final double h = (detection.getProperty('h'.toJS) as JSNumber).toDartDouble;
        
        faceRects.add(Rect.fromLTWH(x, y, w, h));
      }
      return faceRects;
    } catch (e) {
      return [];
    }
  }
}
