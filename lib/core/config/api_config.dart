import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String? _customBaseUrl;

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000/api';
      }
    } catch (_) {}
    return 'http://localhost:3000/api';
  }

  static String get baseUrl => _customBaseUrl ?? defaultBaseUrl;

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url.trim();
  }
}
