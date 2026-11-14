import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tmc_gate_app/core/config/api_config.dart';
import 'package:tmc_gate_app/core/config/api_endpoint.dart';
import 'package:tmc_gate_app/core/config/scoped_access_token.dart';

final dioProvider = Provider<Dio>((ref) {
  final endpoint = ref.watch(initialApiEndpointProvider);
  final dio = DioClient.create(baseUrl: endpoint.value);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers.removeWhere(
          (name, _) => name.toLowerCase() == 'authorization',
        );
        // Authenticate only requests built relative to the configured API.
        if (!options.path.startsWith('/') ||
            options.path.startsWith('//') ||
            options.path.contains('\\')) {
          return handler.next(options);
        }

        try {
          final requestEndpoint = ApiEndpoint.parse(options.baseUrl);
          final requestUri = options.uri;
          final base = requestEndpoint.uri;
          if (requestUri.origin != base.origin ||
              !requestUri.path.startsWith('${base.path}/') ||
              requestUri.pathSegments.any(
                (segment) =>
                    segment.contains('/') ||
                    segment.contains('\\') ||
                    segment == '.' ||
                    segment == '..',
              )) {
            return handler.next(options);
          }
          final route = requestUri.path.substring(base.path.length);
          if (route == '/auth/login' || route == '/auth/refresh') {
            return handler.next(options);
          }

          const storage = FlutterSecureStorage();
          final session = await readScopedAccessToken(storage);
          if (session != null &&
              session.endpoint == requestEndpoint &&
              requestEndpoint == ApiEndpoint.parse(dio.options.baseUrl)) {
            options.headers['Authorization'] = 'Bearer ${session.token}';
            options.followRedirects = false;
          }
        } on Exception {
          // A missing or invalid session leaves the request unauthenticated.
        }
        return handler.next(options);
      },
    ),
  );

  ref.onDispose(dio.close);
  return dio;
});

class DioClient {
  static Dio create({String? baseUrl}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConfig.defaultBaseUrl,
        connectTimeout: const Duration(seconds: 100),
        sendTimeout: const Duration(seconds: 100),
        receiveTimeout: const Duration(seconds: 100),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}
