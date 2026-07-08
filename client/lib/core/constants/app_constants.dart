import 'package:flutter/foundation.dart';

class AppConstants {
  // Tự động chọn URL dựa vào chế độ chạy của Flutter
  static String get baseUrl {
    if (kReleaseMode) {
      // Khi build app thật (Release)
      return 'http://apiseachess.anhdo.io.vn/api/';
    } else {
      return 'http://127.0.0.1:5039/api/';
    }
  }
}
