import 'package:flutter/foundation.dart';

class AppConstants {
  // Tự động chọn URL dựa vào chế độ chạy của Flutter
  static String get baseUrl {
    if (kReleaseMode) {
      // Production(Release)
      return 'http://apiseachess.anhdo.io.vn/api/';
    } else {
      return 'http://192.168.1.81:5039/api/';
    }
  }
}
