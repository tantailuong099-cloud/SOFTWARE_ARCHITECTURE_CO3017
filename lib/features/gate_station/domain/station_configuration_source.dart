import 'station_configuration.dart';

typedef ReadStationConfiguration =
    Future<StationConfiguration> Function(String stationId);

enum StationConfigurationFailure implements Exception {
  unauthorized,
  notFound,
  unavailable,
  invalidResponse,
}

/// Only bind an adapter for a backend that enforces authorization. Failed writes throw.
abstract interface class StationAdministration {
  Future<void> register(StationRegistrationDraft draft);
  Future<void> update(String stationId, StationUpdateDraft draft);
}
