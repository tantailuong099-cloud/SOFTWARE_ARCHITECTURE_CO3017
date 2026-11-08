import '../data/models/recent_gate_event_model.dart';

/// Returns the station's server records in response order. An empty list
/// represents a successful query. Retrieval failures throw [RecentEventsFailure].
typedef RecentGateEventsSource =
    Future<List<RecentGateEvent>> Function(String stationId);

enum RecentEventsFailure implements Exception {
  unauthorized,
  unavailable,
  invalidResponse,
}
