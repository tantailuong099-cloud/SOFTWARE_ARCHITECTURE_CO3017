import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/gate_station_repository.dart';
import '../../data/models/access_scan_models.dart';
import 'gate_station_provider.dart';

class KioskManagementState {
  final List<GateStation> stations;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String searchQuery;
  final String factoryFilter;
  final String statusFilter;

  const KioskManagementState({
    this.stations = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.searchQuery = '',
    this.factoryFilter = 'ALL',
    this.statusFilter = 'ALL',
  });

  List<GateStation> get filteredStations {
    return stations.where((st) {
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchCode = st.stationId.toLowerCase().contains(query);
        final matchName = st.gateIdentifier.toLowerCase().contains(query);
        final matchLoc = (st.location ?? '').toLowerCase().contains(query);
        if (!matchCode && !matchName && !matchLoc) return false;
      }

      if (factoryFilter != 'ALL' && st.factoryId != factoryFilter) {
        return false;
      }

      if (statusFilter != 'ALL' && st.status.toUpperCase() != statusFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  int get totalCount => stations.length;
  int get activeCount => stations.where((s) => s.isActive).length;
  int get inactiveCount => stations.where((s) => !s.isActive).length;

  KioskManagementState copyWith({
    List<GateStation>? stations,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? searchQuery,
    String? factoryFilter,
    String? statusFilter,
  }) {
    return KioskManagementState(
      stations: stations ?? this.stations,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      factoryFilter: factoryFilter ?? this.factoryFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

final kioskManagementProvider =
    StateNotifierProvider<KioskManagementNotifier, KioskManagementState>((ref) {
  final repository = ref.watch(gateStationRepositoryProvider);
  return KioskManagementNotifier(repository, ref);
});

class KioskManagementNotifier extends StateNotifier<KioskManagementState> {
  final GateStationRepository _repository;
  final Ref _ref;

  KioskManagementNotifier(this._repository, this._ref)
      : super(const KioskManagementState()) {
    loadStations();
  }

  Future<void> loadStations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.fetchGateStations();
      state = state.copyWith(stations: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFactoryFilter(String factoryId) {
    state = state.copyWith(factoryFilter: factoryId);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  Future<bool> createStation({
    required String stationCode,
    required String name,
    required String factoryId,
    required String direction,
    required String location,
    String status = 'ACTIVE',
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final created = await _repository.createGateStation(
        stationCode: stationCode,
        name: name,
        factoryId: factoryId,
        direction: direction,
        location: location,
        status: status,
      );
      state = state.copyWith(
        stations: [created, ...state.stations],
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateStation(
    String stationCode, {
    String? name,
    String? factoryId,
    String? direction,
    String? location,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final updated = await _repository.updateGateStation(
        stationCode,
        name: name,
        factoryId: factoryId,
        direction: direction,
        location: location,
      );
      final updatedList =
          state.stations.map((s) => s.stationId == stationCode ? updated : s).toList();
      state = state.copyWith(stations: updatedList, isSubmitting: false);

      // If updating the currently active kiosk station in gateStationNotifier
      final active = _ref.read(gateStationNotifierProvider).activeStation;
      if (active.stationId == stationCode) {
        _ref.read(gateStationNotifierProvider.notifier).setActiveStation(updated);
      }

      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> toggleStationStatus(String stationCode) async {
    final station = state.stations.where((s) => s.stationId == stationCode).firstOrNull;
    if (station == null) return false;

    final nextStatus = station.isActive ? 'INACTIVE' : 'ACTIVE';
    try {
      final updated = await _repository.updateGateStationStatus(stationCode, nextStatus);
      final updatedList =
          state.stations.map((s) => s.stationId == stationCode ? updated : s).toList();
      state = state.copyWith(stations: updatedList);

      // Update active station if matches
      final active = _ref.read(gateStationNotifierProvider).activeStation;
      if (active.stationId == stationCode) {
        _ref.read(gateStationNotifierProvider.notifier).setActiveStation(updated);
      }

      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteStation(String stationCode) async {
    try {
      final ok = await _repository.deleteGateStation(stationCode);
      if (ok) {
        final updatedList =
            state.stations.where((s) => s.stationId != stationCode).toList();
        state = state.copyWith(stations: updatedList);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}
