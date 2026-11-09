import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import 'api_config.dart';
import 'api_endpoint.dart';
import 'api_endpoint_store.dart';
import 'preferences_api_endpoint_store.dart';

/// Prepares an endpoint change without modifying the live client. The returned
/// synchronous commit must only publish prepared state and must not throw.
typedef PrepareApiEndpoint = void Function() Function(ApiEndpoint endpoint);

final apiEndpointStoreProvider = Provider<ApiEndpointStore>(
  (_) => PreferencesApiEndpointStore(),
);

final prepareApiEndpointProvider = Provider<PrepareApiEndpoint>((ref) {
  final dio = ref.watch(dioProvider);
  return (endpoint) {
    final prepared = dio.options.copyWith(baseUrl: endpoint.value);
    return () => dio.options = prepared;
  };
});

final apiEndpointSettingsProvider =
    NotifierProvider<ApiEndpointSettings, ApiEndpoint>(ApiEndpointSettings.new);

enum ApiEndpointUpdateFailure implements Exception {
  application,
  persistence,
  persistenceUncertain,
  busy,
}

class ApiEndpointSettings extends Notifier<ApiEndpoint> {
  bool _saving = false;

  @override
  ApiEndpoint build() => ref.watch(initialApiEndpointProvider);

  Future<void> save(ApiEndpoint endpoint) async {
    if (_saving) throw ApiEndpointUpdateFailure.busy;
    _saving = true;
    try {
      final store = ref.read(apiEndpointStoreProvider);
      final defaultEndpoint = ref.read(defaultApiEndpointProvider);
      final void Function() commit;
      try {
        commit = ref.read(prepareApiEndpointProvider)(endpoint);
      } catch (_) {
        throw ApiEndpointUpdateFailure.application;
      }
      await _saveOverride(
        store,
        endpoint == defaultEndpoint ? null : endpoint.value,
      );
      if (!ref.mounted) return;
      commit();
      state = endpoint;
    } finally {
      _saving = false;
    }
  }

  Future<void> restoreDefault() => save(ref.read(defaultApiEndpointProvider));

  Future<void> _saveOverride(ApiEndpointStore store, String? value) async {
    final String? previous;
    try {
      previous = await store.read();
    } catch (_) {
      throw ApiEndpointUpdateFailure.persistenceUncertain;
    }

    try {
      await store.save(value);
      if (await store.read() == value) return;
    } catch (_) {
      // A platform write can fail after changing the stored value.
    }

    try {
      if (await store.read() != previous) await store.save(previous);
      if (await store.read() != previous) {
        throw ApiEndpointUpdateFailure.persistenceUncertain;
      }
    } catch (_) {
      throw ApiEndpointUpdateFailure.persistenceUncertain;
    }
    throw ApiEndpointUpdateFailure.persistence;
  }
}
