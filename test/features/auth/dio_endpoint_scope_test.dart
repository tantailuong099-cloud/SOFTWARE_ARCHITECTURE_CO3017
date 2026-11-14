import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/core/config/api_config.dart';
import 'package:tmc_gate_app/core/config/api_endpoint.dart';
import 'package:tmc_gate_app/core/network/dio_client.dart';
import 'package:tmc_gate_app/features/auth/data/auth_repository.dart';

const _issuer = 'https://backend.example/api';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (endpoint, sendsToken) in [
    ('https://backend.example:444/api', false),
    ('http://backend.example/api', false),
    ('https://backend.example/other', false),
    ('https://other.example/api', false),
    ('https://BACKEND.example:443/api/', true),
  ]) {
    test('checks bearer scope for $endpoint', () async {
      _storeIssuer(_issuer);
      final (dio, requests) = _client(endpoint);
      await dio.get('/access/events');
      expect(
        requests.single.headers['Authorization'],
        sendsToken ? 'Bearer fixture-token' : null,
      );
      if (sendsToken) expect(requests.single.followRedirects, isFalse);
    });
  }

  test('rejects unscoped storage and absolute or escaping URLs', () async {
    final (dio, requests) = _client(_issuer);
    _storeIssuer(null);
    await dio.get('/access/events');
    _storeIssuer(_issuer);
    await dio.get('https://other.example/api/events');
    await dio.get('/../private');
    expect(
      requests.every((request) => request.headers['Authorization'] == null),
      isTrue,
    );
  });

  test(
    'does not attach the previous issuer token to an in-flight request',
    () async {
      _storeIssuer(_issuer);
      final (dio, requests) = _client(_issuer);
      final pause = Completer<void>();
      final entered = Completer<void>();
      dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            entered.complete();
            await pause.future;
            handler.next(options);
          },
        ),
      );
      final request = dio.get('/access/events');
      await entered.future;
      dio.options.baseUrl = 'https://backend.example:444/api';
      pause.complete();
      await request;
      expect(requests.single.headers['Authorization'], isNull);
    },
  );

  test('authenticates with a fresh token after switching backend', () async {
    _storeIssuer(_issuer);
    final (dio, requests) = _client(_issuer);
    dio.options.baseUrl = 'https://backend.example:444/api';
    final repository = AuthRepository(dio);
    expect(await repository.getStoredUserData(), isEmpty);
    await repository.login('test@example.org', 'fixture-password');
    await dio.get('/access/events');
    expect(requests.first.headers['Authorization'], isNull);
    expect(requests.last.headers['Authorization'], 'Bearer fresh-token');
  });
}

void _storeIssuer(String? endpoint) {
  FlutterSecureStorage.setMockInitialValues({
    'access_token': jsonEncode({
      'token': 'fixture-token',
      'endpoint': endpoint,
    }),
  });
}

(Dio, List<RequestOptions>) _client(String endpoint) {
  final container = ProviderContainer(
    overrides: [
      initialApiEndpointProvider.overrideWithValue(ApiEndpoint.parse(endpoint)),
    ],
  );
  addTearDown(container.dispose);
  final dio = container.read(dioProvider);
  final requests = <RequestOptions>[];
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'accessToken': 'fresh-token',
              'refreshToken': 'refresh-fixture',
              'user': {'role': 'EMPLOYEE'},
            },
          ),
        );
      },
    ),
  );
  return (dio, requests);
}
