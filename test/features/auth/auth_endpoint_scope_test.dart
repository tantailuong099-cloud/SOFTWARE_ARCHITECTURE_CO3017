import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/core/config/api_config.dart';
import 'package:tmc_gate_app/features/auth/data/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'logout never forwards a session token after switching endpoints',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final (dio, requests) = _observeAuthRequests(
        'https://issuer.example.org/api',
      );
      final repository = AuthRepository(dio);
      await repository.login('fixture@example.org', 'fixture-password');
      dio.options.baseUrl = 'https://replacement.example.org/api';
      expect(await repository.getStoredUserData(), isEmpty);

      await repository.logout();

      expect(requests.map((request) => request.path), ['/auth/login']);
      expect(
        await const FlutterSecureStorage().read(key: 'access_token'),
        isNull,
      );
    },
  );

  test(
    'logout sends a session token only to its issuer without following redirects',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final (dio, requests) = _observeAuthRequests(
        'https://issuer.example.org/api',
      );
      final repository = AuthRepository(dio);
      await repository.login('fixture@example.org', 'fixture-password');
      expect(
        (await repository.getStoredUserData())['accessToken'],
        'fixture-token',
      );

      await repository.logout();

      expect(requests.first.followRedirects, isFalse);
      expect(requests.last.path, '/auth/logout');
      expect(requests.last.followRedirects, isFalse);
      expect(requests.last.headers['Authorization'], 'Bearer fixture-token');
    },
  );

  test('rejects and clears a legacy token without an issuer', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'fixture-token',
    });
    final (dio, requests) = _observeAuthRequests(ApiConfig.defaultBaseUrl);
    final repository = AuthRepository(dio);
    expect(await repository.getStoredUserData(), isEmpty);

    await repository.logout();

    expect(requests, isEmpty);
    expect(
      await const FlutterSecureStorage().read(key: 'access_token'),
      isNull,
    );
  });
}

(Dio, List<RequestOptions>) _observeAuthRequests(String endpoint) {
  final dio = Dio(BaseOptions(baseUrl: endpoint));
  addTearDown(dio.close);
  final requests = <RequestOptions>[];
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: options.path == '/auth/login'
                ? {
                    'accessToken': 'fixture-token',
                    'refreshToken': 'fixture-refresh',
                    'user': {'role': 'EMPLOYEE'},
                  }
                : null,
          ),
        );
      },
    ),
  );
  return (dio, requests);
}
