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
  final store = PreferencesApiEndpointStore();
  final endpoint = await restoreApiEndpoint(
    store,
    ApiEndpoint.parse(ApiConfig.defaultBaseUrl),
  );
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
