import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import 'api_config.dart';
import 'api_endpoint.dart';
import 'api_endpoint_store.dart';
import 'preferences_api_endpoint_store.dart';

typedef ApplyApiEndpoint = void Function(ApiEndpoint endpoint);

final apiEndpointStoreProvider = Provider<ApiEndpointStore>(
  (_) => PreferencesApiEndpointStore(),
);

final applyApiEndpointProvider = Provider<ApplyApiEndpoint>((ref) {
  final dio = ref.watch(dioProvider);
  return (endpoint) => dio.options.baseUrl = endpoint.value;
});

final apiEndpointSettingsProvider =
    NotifierProvider<ApiEndpointSettings, ApiEndpoint>(ApiEndpointSettings.new);

enum ApiEndpointUpdateFailure implements Exception { persistence, busy }

class ApiEndpointSettings extends Notifier<ApiEndpoint> {
  bool _saving = false;

  @override
  ApiEndpoint build() => ref.watch(initialApiEndpointProvider);

  Future<void> save(ApiEndpoint endpoint) async {
    if (_saving) throw ApiEndpointUpdateFailure.busy;
    _saving = true;
    try {
      final store = ref.read(apiEndpointStoreProvider);
      final apply = ref.read(applyApiEndpointProvider);
      final defaultEndpoint = ref.read(defaultApiEndpointProvider);
      try {
        await store.save(endpoint == defaultEndpoint ? null : endpoint.value);
      } catch (_) {
        throw ApiEndpointUpdateFailure.persistence;
      }
      if (!ref.mounted) return;
      apply(endpoint);
      state = endpoint;
    } finally {
      _saving = false;
    }
  }

  Future<void> restoreDefault() => save(ref.read(defaultApiEndpointProvider));
}
