import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tmc_gate_app/core/config/api_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final endpoint = ref.watch(initialApiEndpointProvider);
  final dio = DioClient.create(baseUrl: endpoint.value);
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
