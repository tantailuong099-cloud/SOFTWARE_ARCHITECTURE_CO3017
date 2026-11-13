import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_endpoint.dart';

/// Đại diện cho một cấu hình Endpoint trong file .env
class ApiEndpointPreset {
  final String key;
  final String name;
  final String url;

  const ApiEndpointPreset({
    required this.key,
    required this.name,
    required this.url,
  });
}

class ApiConfig {
  static const String fallbackBaseUrl =
      'https://software-architecture-co3017-be.onrender.com/api';

  // Ưu tiên biến môi trường truyền qua --dart-define hoặc --dart-define-from-file=.env
  static const String _envDefine = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _envDefineAlt = String.fromEnvironment(
    'API_ENDPOINT',
    defaultValue: '',
  );

  static String _loadedUrl = '';

  /// Danh sách các endpoint presets được đọc từ file .env
  static List<ApiEndpointPreset> availablePresets = [];

  /// Trả về API Base URL:
  /// 1. Nếu có cấu hình đọc từ file .env hoặc tự động nhận diện -> dùng URL tương ứng
  /// 2. Nếu có cờ --dart-define=API_BASE_URL=... -> dùng giá trị đó
  /// 3. Nếu không có gì -> mặc định http://localhost:3000/api
  static String get defaultBaseUrl {
    if (_loadedUrl.isNotEmpty) {
      return _loadedUrl;
    }
    if (_envDefine.isNotEmpty) {
      return _envDefine;
    }
    if (_envDefineAlt.isNotEmpty) {
      return _envDefineAlt;
    }
    return fallbackBaseUrl;
  }

  /// Đọc và nạp các biến cấu hình từ file .env (hỗ trợ nhiều endpoint & tự động nhận diện thiết bị)
  static Future<void> loadFromEnvFile([String path = '.env']) async {
    availablePresets = [];
    final envVars = <String, String>{};

    try {
      final content = await rootBundle.loadString(path);
      for (final rawLine in content.split('\n')) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final eqIdx = line.indexOf('=');
        if (eqIdx == -1) continue;
        final key = line.substring(0, eqIdx).trim();
        var value = line.substring(eqIdx + 1).trim();

        // Xóa dấu nháy kép hoặc nháy đơn nếu người dùng bọc URL
        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.substring(1, value.length - 1).trim();
        }

        if (key.isNotEmpty && value.isNotEmpty) {
          envVars[key] = value;
        }
      }
    } catch (_) {
      // Nếu không tìm thấy file .env hoặc lỗi đọc asset, tự động fallback về defaultBaseUrl
    }

    // 1. Quét tìm tất cả các endpoint presets
    final presetLabels = {
      'LOCAL': 'Máy tính Local (3000)',
      'TUNNEL': 'VS Code Tunnel',
      'LAN': 'Mạng Wi-Fi LAN',
      'PROD': 'Production Server',
      'DEV': 'Development Server',
    };

    final presets = <ApiEndpointPreset>[];

    envVars.forEach((key, val) {
      if (key.startsWith('API_URL_') || key.startsWith('API_ENDPOINT_')) {
        final envKey = key
            .replaceFirst('API_URL_', '')
            .replaceFirst('API_ENDPOINT_', '')
            .toUpperCase();
        final name = presetLabels[envKey] ?? envKey;
        presets.add(ApiEndpointPreset(key: envKey, name: name, url: val));
      }
    });

    // Nếu có API_BASE_URL đơn lẻ mà chưa nằm trong presets
    if (envVars.containsKey('API_BASE_URL')) {
      final val = envVars['API_BASE_URL']!;
      if (!presets.any((p) => p.url == val)) {
        presets.insert(
          0,
          ApiEndpointPreset(key: 'DEFAULT', name: 'Mặc định (.env)', url: val),
        );
      }
    }

    availablePresets = presets;

    // 2. Xác định endpoint:
    // Kiểm tra biến ACTIVE_ENV (Mặc định là AUTO)
    final activeEnv = (envVars['ACTIVE_ENV'] ?? envVars['ACTIVE_API'] ?? 'AUTO')
        .toUpperCase()
        .trim();

    // CHẾ ĐỘ AUTO (Tự động thích ứng thiết bị: Laptop vs Điện thoại):
    if (activeEnv == 'AUTO' || activeEnv.isEmpty) {
      if (kIsWeb) {
        try {
          final host = Uri.base.host.toLowerCase();

          // Trường hợp 1: Laptop chạy local (localhost hoặc 127.0.0.1)
          if (host == 'localhost' || host == '127.0.0.1' || host.isEmpty) {
            final localPreset = presets
                .where((p) => p.key == 'LOCAL')
                .firstOrNull;
            _loadedUrl =
                localPreset?.url ?? envVars['API_URL_LOCAL'] ?? fallbackBaseUrl;
            return;
          }

          // Trường hợp 2: Điện thoại mở qua VS Code Dev Tunnel (*.devtunnels.ms)
          if (host.contains('devtunnels.ms')) {
            final tunnelPreset = presets
                .where((p) => p.key == 'TUNNEL')
                .firstOrNull;
            if (tunnelPreset != null && tunnelPreset.url.isNotEmpty) {
              _loadedUrl = tunnelPreset.url;
              return;
            }
            // Tự động suy luận endpoint port 3000 từ URL tunnel của client
            final backendHost = host.replaceAll(RegExp(r'-\d+\.'), '-3000.');
            _loadedUrl = 'https://$backendHost/api';
            return;
          }

          // Trường hợp 3: Điện thoại mở qua IP Wi-Fi nội bộ (192.168.x.x, 10.x.x.x)
          final isLanIp = RegExp(
            r'^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)',
          ).hasMatch(host);
          if (isLanIp) {
            final lanPreset = presets.where((p) => p.key == 'LAN').firstOrNull;
            if (lanPreset != null && lanPreset.url.isNotEmpty) {
              _loadedUrl = lanPreset.url;
              return;
            }
            _loadedUrl = 'http://$host:3000/api';
            return;
          }
        } catch (_) {}
      }
    } else {
      // Nếu người dùng chỉ định rõ ràng ACTIVE_ENV=LOCAL | TUNNEL | LAN | PROD
      final matched = presets.where((p) => p.key == activeEnv).firstOrNull;
      if (matched != null) {
        _loadedUrl = matched.url;
        return;
      }
      final directKey = 'API_URL_$activeEnv';
      if (envVars.containsKey(directKey)) {
        _loadedUrl = envVars[directKey]!;
        return;
      }
    }

    // Nếu không khớp chế độ nào ở trên, kiểm tra API_BASE_URL
    if (envVars.containsKey('API_BASE_URL')) {
      _loadedUrl = envVars['API_BASE_URL']!;
      return;
    }

    // Ưu tiên preset LOCAL hoặc preset đầu tiên
    if (presets.isNotEmpty) {
      final localPreset = presets.where((p) => p.key == 'LOCAL').firstOrNull;
      _loadedUrl = localPreset?.url ?? presets.first.url;
      return;
    }

    _loadedUrl = fallbackBaseUrl;
  }
}

final defaultApiEndpointProvider = Provider<ApiEndpoint>(
  (_) => ApiEndpoint.parse(ApiConfig.defaultBaseUrl),
);

/// Bootstrapped before the app creates its network client.
final initialApiEndpointProvider = Provider<ApiEndpoint>(
  (ref) => ref.watch(defaultApiEndpointProvider),
);
