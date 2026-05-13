import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;

class OCRServiceWeb {
  /// Thực hiện OCR từ một ảnh (dạng Base64 string)
  static Future<String> scanCard(String base64Image) async {
    try {
      // Gọi hàm performOCR đã định nghĩa trong index.html
      // Sử dụng promiseToFuture để chuyển đổi JS Promise sang Dart Future một cách an toàn
      final jsPromise = js.context.callMethod('performOCR', [base64Image]);
      
      final result = await _handleJsPromise(jsPromise);
      return result?.toString() ?? "Không có kết quả";
    } catch (e) {
      return "Lỗi thực thi OCR: $e";
    }
  }

  /// Hàm hỗ trợ parse thông tin từ text thô (Cải tiến Regex)
  static Map<String, String> parseCardData(String rawText) {
    Map<String, String> data = {
      'raw': rawText,
      'id_number': 'Không tìm thấy',
    };

    // Chuẩn hóa text: xóa khoảng trắng thừa, chuyển về chữ in hoa để dễ tìm
    final cleanText = rawText.replaceAll(' ', '').toUpperCase();

    // Regex tìm số CCCD/CMND (thường là dãy 9 hoặc 12 chữ số)
    // Ưu tiên tìm các dãy số dài 12 chữ số trước (CCCD mới)
    final idRegex = RegExp(r'(\d{12})|(\d{9})');
    final idMatch = idRegex.firstMatch(cleanText);
    
    if (idMatch != null) {
      data['id_number'] = idMatch.group(0)!;
    }

    return data;
  }

  static Future<dynamic> _handleJsPromise(dynamic promise) {
    // Trong Flutter Web, JsObject có thể await trực tiếp nếu nó là Promise
    return promise;
  }
}
