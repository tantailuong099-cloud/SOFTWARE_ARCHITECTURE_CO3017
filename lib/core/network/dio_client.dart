import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tmc_gate_app/core/config/api_config.dart';
import 'package:tmc_gate_app/core/config/api_endpoint_settings.dart';

final dioProvider = Provider<Dio>((ref) {
  final endpoint = ref.watch(initialApiEndpointProvider);
  final dio = DioClient.create(baseUrl: endpoint.value);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Bỏ qua Authorization cho các endpoint login và refresh token
        if (options.path.contains('/auth/login') ||
            options.path.contains('/auth/refresh')) {
          return handler.next(options);
        }

        // Lấy token trực tiếp từ secure storage, phá vỡ vòng lặp phụ thuộc (circular dependency)
        // giữa dioProvider và authNotifierProvider
        try {
          const storage = FlutterSecureStorage();
          final stored = await storage.read(key: 'access_token');
          if (stored != null && stored.isNotEmpty) {
            String? token;
            if (stored.startsWith('{')) {
              final val = jsonDecode(stored);
              token = val['token']?.toString();
            } else {
              token = stored;
            }
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
        } catch (_) {}

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
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}
