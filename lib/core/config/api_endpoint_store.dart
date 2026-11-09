import 'api_endpoint.dart';

abstract interface class ApiEndpointStore {
  Future<String?> read();

  /// Saves an override or clears it with null. Storage failures throw.
  Future<void> save(String? url);
}

Future<ApiEndpoint> restoreApiEndpoint(
  ApiEndpointStore store,
  ApiEndpoint fallback,
) async {
  try {
    final saved = await store.read();
    return saved == null ? fallback : ApiEndpoint.parse(saved);
  } catch (_) {
    return fallback;
  }
}
