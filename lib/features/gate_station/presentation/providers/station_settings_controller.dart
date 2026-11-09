import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_endpoint_settings.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/dio_station_configuration_reader.dart';
import '../../domain/station_configuration.dart';
import '../../domain/station_configuration_source.dart';
import 'gate_station_provider.dart';

final stationConfigurationReaderProvider = Provider<ReadStationConfiguration>(
  (ref) => DioStationConfigurationReader(ref.watch(dioProvider)).read,
);

final stationConfigurationProvider =
    FutureProvider.autoDispose<StationConfiguration>((ref) {
      final stationId = ref.watch(
        gateStationNotifierProvider.select(
          (state) => state.activeStation.stationId,
        ),
      );
      ref.watch(apiEndpointSettingsProvider);
      return ref.watch(stationConfigurationReaderProvider)(stationId);
    }, retry: (_, _) => null);

// Enable only when an authenticated, authorized server adapter is available.
final stationAdministrationProvider = Provider<StationAdministration?>(
  (_) => null,
);
