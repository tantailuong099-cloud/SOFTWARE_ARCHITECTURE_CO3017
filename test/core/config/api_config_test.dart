import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/core/config/api_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiConfig Environment Loading Tests', () {
    test('defaults to http://localhost:3000/api when no config or env is loaded', () {
      expect(ApiConfig.fallbackBaseUrl, 'http://localhost:3000/api');
    });

    test('loads and parses multi-endpoints with ACTIVE_ENV=TUNNEL', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStringAssetHandler(
        '.env',
        () async => '''
ACTIVE_ENV=TUNNEL
API_URL_LOCAL=http://localhost:3000/api
API_URL_TUNNEL=https://custom-tunnel-3000.devtunnels.ms/api
API_URL_LAN=http://192.168.1.50:3000/api
''',
      );

      await ApiConfig.loadFromEnvFile('.env');
      expect(ApiConfig.defaultBaseUrl, 'https://custom-tunnel-3000.devtunnels.ms/api');
      expect(ApiConfig.availablePresets.length, 3);
    });

    test('auto-detects LOCAL when host is empty/test environment with ACTIVE_ENV=AUTO', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStringAssetHandler(
        '.env',
        () async => '''
ACTIVE_ENV=AUTO
API_URL_LOCAL=http://localhost:3000/api
API_URL_TUNNEL=https://custom-tunnel-3000.devtunnels.ms/api
''',
      );

      await ApiConfig.loadFromEnvFile('.env');
      expect(ApiConfig.defaultBaseUrl, 'http://localhost:3000/api');
    });

    test('handles missing or invalid env gracefully by falling back', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStringAssetHandler(
        'non_existent.env',
        () async => throw PlatformException(code: '404'),
      );

      await ApiConfig.loadFromEnvFile('non_existent.env');
      expect(ApiConfig.defaultBaseUrl.isNotEmpty, isTrue);
    });
  });
}
