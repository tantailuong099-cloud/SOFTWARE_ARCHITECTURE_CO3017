import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmc_gate_app/core/config/api_config.dart';
import 'package:tmc_gate_app/core/config/api_endpoint.dart';
import 'package:tmc_gate_app/core/config/api_endpoint_settings.dart';
import 'package:tmc_gate_app/core/config/api_endpoint_store.dart';
import 'package:tmc_gate_app/core/config/preferences_api_endpoint_store.dart';
import 'package:tmc_gate_app/core/network/dio_client.dart';
import 'package:tmc_gate_app/features/gate_station/data/gate_station_repository.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/gate_station_provider.dart';

import '../../features/gate_station/support/memory_api_endpoint_store.dart';

final _default = ApiEndpoint.parse('http://localhost:3000/api');
final _changed = ApiEndpoint.parse(
  'https://replacement.example.org:8443/api///',
);

void main() {
  for (final usePreferences in [false, true]) {
    test(
      '${usePreferences ? 'preferences adapter' : 'memory store'} obeys settings contract',
      () async {
        final memory = MemoryApiEndpointStore();
        var rejectPreferenceWrites = false;
        final preferences = _MockPreferences(() => rejectPreferenceWrites);
        final ApiEndpointStore store = usePreferences
            ? PreferencesApiEndpointStore(preferences)
            : memory;
        final applied = <ApiEndpoint>[];
        final container = ProviderContainer.test(
          overrides: [
            defaultApiEndpointProvider.overrideWithValue(_default),
            apiEndpointStoreProvider.overrideWithValue(store),
            applyApiEndpointProvider.overrideWithValue(applied.add),
            dioProvider.overrideWith(
              (_) => throw StateError(
                'Dio is unnecessary for this controller test',
              ),
            ),
          ],
        );
        final settings = container.read(apiEndpointSettingsProvider.notifier);
        expect(await restoreApiEndpoint(store, _default), _default);
        expect(container.read(apiEndpointSettingsProvider), _default);
        await settings.save(_changed);
        expect(await store.read(), _changed.value);
        expect(
          await restoreApiEndpoint(
            usePreferences ? PreferencesApiEndpointStore(preferences) : store,
            _default,
          ),
          _changed,
        );

        memory.rejectWrites = true;
        rejectPreferenceWrites = true;
        await expectLater(
          settings.restoreDefault(),
          throwsA(ApiEndpointUpdateFailure.persistence),
        );
        expect(applied, [_changed]);
        expect(container.read(apiEndpointSettingsProvider), _changed);
        memory.rejectWrites = false;
        rejectPreferenceWrites = false;

        await settings.restoreDefault();
        expect(await store.read(), isNull);
        expect(container.read(apiEndpointSettingsProvider), _default);
        expect(applied, [_changed, _default]);
        if (usePreferences) {
          expect(preferences.keys, {'backend_api_base_url'});
        }
      },
    );
  }

  test('restores default for corrupt configuration', () async {
    final store = MemoryApiEndpointStore()
      ..url = 'https://user:password@example.org/api';
    expect(await restoreApiEndpoint(store, _default), _default);
  });

  test('initial restored endpoint is used on the first Dio request', () async {
    final store = MemoryApiEndpointStore()..url = _changed.value;
    final initial = await restoreApiEndpoint(store, _default);
    final container = ProviderContainer.test(
      overrides: [initialApiEndpointProvider.overrideWithValue(initial)],
    );
    expect(container.read(dioProvider).options.baseUrl, _changed.value);
  });

  test(
    'updates the existing Dio and repository without changing gate state or syncing',
    () async {
      final store = MemoryApiEndpointStore();
      final container = ProviderContainer.test(
        overrides: [
          defaultApiEndpointProvider.overrideWithValue(_default),
          apiEndpointStoreProvider.overrideWithValue(store),
        ],
      );
      final dio = container.read(dioProvider);
      final repository = container.read(gateStationRepositoryProvider);
      final notifier = container.read(gateStationNotifierProvider.notifier);
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
                    : <Object>[],
              ),
            );
          },
        ),
      );
      notifier.switchStation('LA-GATE-01');
      await notifier.submitScan('history-fixture');
      notifier.toggleOfflineSimulation();
      await notifier.submitScan('queued-fixture');
      final before = container.read(gateStationNotifierProvider);
      expect(before.scanHistory, hasLength(1));
      expect(before.offlineQueue, hasLength(1));

      await repository.fetchGateStations();
      final settings = container.read(apiEndpointSettingsProvider.notifier);
      await settings.save(_changed);
      expect(requests, hasLength(2));
      expect(container.read(dioProvider), same(dio));
      expect(container.read(gateStationRepositoryProvider), same(repository));
      expect(
        container.read(gateStationNotifierProvider.notifier),
        same(notifier),
      );
      expect(container.read(gateStationNotifierProvider), same(before));
      expect(before.activeStation.stationId, 'LA-GATE-01');

      await repository.fetchGateStations();
      expect(requests[1], Uri.parse('${_default.value}/gate-stations'));
      expect(requests[2], Uri.parse('${_changed.value}/gate-stations'));
      expect(
        requests.where((uri) => uri.path.contains('sync-offline-scans')),
        isEmpty,
      );
      expect(await store.read(), _changed.value);
    },
  );
}

class _MockPreferences implements SharedPreferencesAsync {
  final _values = <String, String>{};
  final keys = <String>{};
  final bool Function() rejectWrites;

  _MockPreferences(this.rejectWrites);

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    if (rejectWrites()) throw StateError('Platform write rejected');
    keys.add(key);
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    if (rejectWrites()) throw StateError('Platform removal rejected');
    keys.add(key);
    _values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
