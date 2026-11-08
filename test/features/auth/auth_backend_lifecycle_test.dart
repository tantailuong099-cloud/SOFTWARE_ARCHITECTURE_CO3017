import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/core/config/api_config.dart';
import 'package:tmc_gate_app/core/config/api_endpoint.dart';
import 'package:tmc_gate_app/core/config/api_endpoint_settings.dart';
import 'package:tmc_gate_app/core/config/api_endpoint_store.dart';
import 'package:tmc_gate_app/core/network/dio_client.dart';
import 'package:tmc_gate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/gate_station_provider.dart';

import '../gate_station/support/memory_api_endpoint_store.dart';

final _first = ApiEndpoint.parse('https://first.example.org/api');
final _second = ApiEndpoint.parse('https://second.example.org/api');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'live switching signs out without replacing the gate state or sending queued scans',
    () async {
      final container = _container(MemoryApiEndpointStore());
      final dio = container.read(dioProvider);
      final requests = <Uri>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options.uri);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: options.path == '/access/scan'
                    ? {
                        'accessDecision': 'APPROVED',
                        'controllerOutcome': 'CONTROLLER_CONFIRMED',
                      }
                    : _loginResponse(options.uri.host),
              ),
            );
          },
        ),
      );
      final auth = container.read(authNotifierProvider.notifier);
      final gate = container.read(gateStationNotifierProvider.notifier);
      gate.switchStation('LA-GATE-01');
      await gate.submitScan('history-fixture');
      gate.toggleOfflineSimulation();
      await gate.submitScan('queued-fixture');
      final stationState = container.read(gateStationNotifierProvider);
      expect(stationState.scanHistory, hasLength(1));
      expect(stationState.offlineQueue, hasLength(1));

      expect(
        await auth.login('fixture@example.org', 'fixture-password'),
        isTrue,
      );
      final settings = container.read(apiEndpointSettingsProvider.notifier);
      await settings.save(ApiEndpoint.parse('${_first.value}///'));
      expect(container.read(authNotifierProvider).isAuthenticated, isTrue);

      await settings.save(_second);
      final signedOut = container.read(authNotifierProvider);
      expect(signedOut.isAuthenticated, isFalse);
      expect(signedOut.accessToken, isNull);
      expect(signedOut.role, isNull);
      expect(signedOut.email, isNull);
      expect(container.read(authNotifierProvider.notifier), same(auth));
      expect(container.read(dioProvider), same(dio));
      expect(container.read(gateStationNotifierProvider.notifier), same(gate));
      expect(container.read(gateStationNotifierProvider), same(stationState));
      expect(stationState.activeStation.stationId, 'LA-GATE-01');
      expect(requests.map((uri) => uri.path), [
        '/api/access/scan',
        '/api/auth/login',
      ]);

      await auth.logout();
      expect(requests, hasLength(2));
      expect(
        await const FlutterSecureStorage().read(key: 'access_token'),
        isNull,
      );
      expect(
        await auth.login('fixture@example.org', 'fixture-password'),
        isTrue,
      );
      expect(requests.last, Uri.parse('${_second.value}/auth/login'));
      expect(
        container.read(authNotifierProvider).accessToken,
        'token-second.example.org',
      );
    },
  );

  for (final endpoint in [_first, _second]) {
    test(
      'restart restores a saved session only on ${endpoint.uri.host}',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'access_token': jsonEncode({
            'token': 'first-token',
            'endpoint': _first.value,
          }),
          'user_role': 'SECURITY_GUARD',
          'user_email': 'fixture@example.org',
        });
        final store = MemoryApiEndpointStore()..url = endpoint.value;
        final initial = await restoreApiEndpoint(store, _first);
        final container = _container(store, initial: initial);
        final auth = await _settledAuth(container);
        final sameIssuer = endpoint == _first;
        expect(auth.isAuthenticated, sameIssuer);
        expect(auth.accessToken, sameIssuer ? 'first-token' : isNull);
        expect(auth.role, sameIssuer ? 'SECURITY_GUARD' : isNull);
        expect(auth.email, sameIssuer ? 'fixture@example.org' : isNull);
      },
    );
  }

  test(
    'a late login response from the old backend cannot authenticate the new backend',
    () async {
      final container = _container(MemoryApiEndpointStore());
      final dio = container.read(dioProvider);
      final oldRequest =
          Completer<(RequestOptions, RequestInterceptorHandler)>();
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            if (options.uri.host == _first.uri.host) {
              oldRequest.complete((options, handler));
            } else {
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: _loginResponse(options.uri.host),
                  statusCode: 200,
                ),
              );
            }
          },
        ),
      );

      final auth = container.read(authNotifierProvider.notifier);
      final oldLogin = auth.login('fixture@example.org', 'fixture-password');
      final (options, handler) = await oldRequest.future;
      await container.read(apiEndpointSettingsProvider.notifier).save(_second);
      expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
      final newLogin = auth.login('fixture@example.org', 'fixture-password');
      handler.resolve(
        Response(
          requestOptions: options,
          data: _loginResponse(options.uri.host),
          statusCode: 200,
        ),
      );

      expect(await oldLogin, isFalse);
      expect(await newLogin, isTrue);
      expect(
        container.read(authNotifierProvider).accessToken,
        'token-second.example.org',
      );
      expect(requests.map((request) => request.uri.host), [
        _first.uri.host,
        _second.uri.host,
      ]);
      expect(
        requests.every(
          (request) => !request.headers.containsKey('Authorization'),
        ),
        isTrue,
      );
    },
  );
}

ProviderContainer _container(
  MemoryApiEndpointStore store, {
  ApiEndpoint? initial,
}) => ProviderContainer.test(
  overrides: [
    defaultApiEndpointProvider.overrideWithValue(_first),
    initialApiEndpointProvider.overrideWithValue(initial ?? _first),
    apiEndpointStoreProvider.overrideWithValue(store),
  ],
);

Future<AuthState> _settledAuth(ProviderContainer container) async {
  final settled = Completer<AuthState>();
  final subscription = container.listen(authNotifierProvider, (_, next) {
    if (!next.isLoading && !settled.isCompleted) settled.complete(next);
  }, fireImmediately: true);
  try {
    return await settled.future;
  } finally {
    subscription.close();
  }
}

Map<String, dynamic> _loginResponse(String issuer) => {
  'accessToken': 'token-$issuer',
  'refreshToken': 'refresh-fixture',
  'user': {'role': 'SECURITY_GUARD', 'email': 'fixture@example.org'},
};
