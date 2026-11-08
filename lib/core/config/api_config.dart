import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_endpoint.dart';

class ApiConfig {
  static String get defaultBaseUrl =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:3000/api'
      : 'http://localhost:3000/api';
}

final defaultApiEndpointProvider = Provider<ApiEndpoint>(
  (_) => ApiEndpoint.parse(ApiConfig.defaultBaseUrl),
);

/// Bootstrapped before the app creates its network client.
final initialApiEndpointProvider = Provider<ApiEndpoint>(
  (ref) => ref.watch(defaultApiEndpointProvider),
);
