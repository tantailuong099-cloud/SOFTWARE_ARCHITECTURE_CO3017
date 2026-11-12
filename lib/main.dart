import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tmc_gate_app/app/app.dart';
import 'package:tmc_gate_app/core/config/api_config.dart';
import 'package:tmc_gate_app/core/config/api_endpoint.dart';
import 'package:tmc_gate_app/core/config/api_endpoint_settings.dart';
import 'package:tmc_gate_app/core/config/api_endpoint_store.dart';
import 'package:tmc_gate_app/core/config/preferences_api_endpoint_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nạp cấu hình từ file .env nếu có (tự động nhận diện thiết bị Laptop vs Điện thoại)
  await ApiConfig.loadFromEnvFile();

  final store = PreferencesApiEndpointStore();
  final defaultEndpoint = ApiEndpoint.parse(ApiConfig.defaultBaseUrl);
  var endpoint = await restoreApiEndpoint(store, defaultEndpoint);

  // Trên web: nếu đang truy cập từ thiết bị từ xa (điện thoại qua tunnel hoặc mạng LAN)
  // mà bộ nhớ cache lại đang lưu 'localhost', tự động ghi đè bằng defaultEndpoint của thiết bị đó.
  if (kIsWeb) {
    final host = Uri.base.host.toLowerCase();
    final isRemote = host.isNotEmpty && host != 'localhost' && host != '127.0.0.1';
    if (isRemote && endpoint.value.contains('localhost')) {
      endpoint = defaultEndpoint;
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        apiEndpointStoreProvider.overrideWithValue(store),
        initialApiEndpointProvider.overrideWithValue(endpoint),
      ],
      child: const TMCGateApp(),
    ),
  );
}
