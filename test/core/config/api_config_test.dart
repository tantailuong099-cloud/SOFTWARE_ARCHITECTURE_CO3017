import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/core/config/api_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiConfig Environment Loading Tests', () {
    test('uses the configured fallback when no endpoint is loaded', () {
      expect(ApiConfig.defaultBaseUrl, ApiConfig.fallbackBaseUrl);
    });

    test('loads and parses multi-endpoints with ACTIVE_ENV=TUNNEL', () async {
      _mockAsset(
        '.env',
        () => '''
ACTIVE_ENV=TUNNEL
API_URL_LOCAL=http://localhost:3000/api
API_URL_TUNNEL=https://custom-tunnel-3000.devtunnels.ms/api
API_URL_LAN=http://192.168.1.50:3000/api
''',
      );

      await ApiConfig.loadFromEnvFile('.env');
      expect(
        ApiConfig.defaultBaseUrl,
        'https://custom-tunnel-3000.devtunnels.ms/api',
      );
      expect(ApiConfig.availablePresets.length, 3);
    });

    test(
      'auto-detects LOCAL when host is empty/test environment with ACTIVE_ENV=AUTO',
      () async {
        _mockAsset(
          '.env',
          () => '''
ACTIVE_ENV=AUTO
API_URL_LOCAL=http://localhost:3000/api
API_URL_TUNNEL=https://custom-tunnel-3000.devtunnels.ms/api
''',
        );

        await ApiConfig.loadFromEnvFile('.env');
        expect(ApiConfig.defaultBaseUrl, 'http://localhost:3000/api');
      },
    );

    test('handles missing or invalid env gracefully by falling back', () async {
      _mockAsset('non_existent.env', () => null);

      await ApiConfig.loadFromEnvFile('non_existent.env');
      expect(ApiConfig.defaultBaseUrl.isNotEmpty, isTrue);
    });
  });
}

void _mockAsset(String path, String? Function() content) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMessageHandler('flutter/assets', (message) async {
    if (message == null) return null;
    final name = utf8.decode(
      message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
    );
    final value = name == path ? content() : null;
    return value == null ? null : ByteData.sublistView(utf8.encode(value));
  });
  addTearDown(() {
    rootBundle.evict(path);
    messenger.setMockMessageHandler('flutter/assets', null);
  });
}
