import 'package:tmc_gate_app/core/config/api_endpoint_store.dart';

class MemoryApiEndpointStore implements ApiEndpointStore {
  String? url;
  bool rejectWrites = false;

  @override
  Future<String?> read() async => url;

  @override
  Future<void> save(String? url) async {
    if (rejectWrites) throw StateError('Write rejected by the test store');
    this.url = url;
  }
}
