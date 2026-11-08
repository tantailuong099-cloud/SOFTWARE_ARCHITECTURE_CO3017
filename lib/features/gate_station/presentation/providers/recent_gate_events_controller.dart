import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gate_station_repository.dart';
import '../../data/models/recent_gate_event_model.dart';
import '../../domain/recent_gate_events_source.dart';
import 'gate_station_provider.dart';

final recentGateEventsSourceProvider = Provider<RecentGateEventsSource>(
  (ref) => ref.watch(gateStationRepositoryProvider).fetchRecentEvents,
);

final recentGateEventsProvider =
    FutureProvider.autoDispose<List<RecentGateEvent>?>((ref) {
      final stationId = ref.watch(
        gateStationNotifierProvider.select(
          (state) => state.activeStation.stationId,
        ),
      );
      if (stationId.isEmpty) return null;

      // Riverpod discards the previous future when the station changes or refresh invalidates it.
      return ref.watch(recentGateEventsSourceProvider)(stationId);
    }, retry: (_, _) => null);
