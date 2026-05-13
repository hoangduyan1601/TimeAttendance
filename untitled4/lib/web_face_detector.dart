import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('FaceDetector')
extension type FaceDetector._(JSObject _) implements JSObject {
  external FaceDetector(FaceDetectorOptions options);
  external JSPromise<JSArray<Face>> detect(web.HTMLVideoElement video);
}

@JS()
@anonymous
extension type FaceDetectorOptions._(JSObject _) implements JSObject {
  external factory FaceDetectorOptions({
    String modelSelection,
    num minDetectionConfidence,
  });
}

@JS()
@anonymous
extension type Face._(JSObject _) implements JSObject {
  external JSArray<JSNumber> get boundingBox; // [x, y, width, height]
}
