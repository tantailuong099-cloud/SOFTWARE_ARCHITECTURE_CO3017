import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/gate_station_repository.dart';
import '../../data/models/access_scan_models.dart';

enum GateDisplayStatus {
  idle,
  processing,
  authorized,
  denied,
  controllerError,
}

class GateStationState {
  final GateStation activeStation;
  final GateDisplayStatus displayStatus;
  final AccessScanResponse? latestResponse;
  final List<AccessScanResponse> scanHistory;
  final List<SubmitScanRequest> offlineQueue;
  final bool isSimulatingOffline;
  final bool isConnected;
  final String? errorMessage;
  final String? syncStatusMessage;

  GateStationState({
    required this.activeStation,
    this.displayStatus = GateDisplayStatus.idle,
    this.latestResponse,
    this.scanHistory = const [],
    this.offlineQueue = const [],
    this.isSimulatingOffline = false,
    this.isConnected = true,
    this.errorMessage,
    this.syncStatusMessage,
  });

  GateStationState copyWith({
    GateStation? activeStation,
    GateDisplayStatus? displayStatus,
    AccessScanResponse? latestResponse,
    List<AccessScanResponse>? scanHistory,
    List<SubmitScanRequest>? offlineQueue,
    bool? isSimulatingOffline,
    bool? isConnected,
    String? errorMessage,
    String? syncStatusMessage,
  }) {
    return GateStationState(
      activeStation: activeStation ?? this.activeStation,
      displayStatus: displayStatus ?? this.displayStatus,
      latestResponse: latestResponse ?? this.latestResponse,
      scanHistory: scanHistory ?? this.scanHistory,
      offlineQueue: offlineQueue ?? this.offlineQueue,
      isSimulatingOffline: isSimulatingOffline ?? this.isSimulatingOffline,
      isConnected: isConnected ?? this.isConnected,
      errorMessage: errorMessage,
      syncStatusMessage: syncStatusMessage,
    );
  }
}

final gateStationNotifierProvider =
    StateNotifierProvider<GateStationNotifier, GateStationState>((ref) {
  final repo = ref.watch(gateStationRepositoryProvider);
  return GateStationNotifier(repo);
});

class GateStationNotifier extends StateNotifier<GateStationState> {
  final GateStationRepository _repository;
  Timer? _resetTimer;
  int _requestCounter = 100;

  GateStationNotifier(this._repository)
      : super(
          GateStationState(
            activeStation: GateStation(
              stationId: 'BD-GATE-01',
              factoryId: 'BINH_DUONG',
              gateIdentifier: 'Gate 01 - Main Entrance',
              direction: 'ENTRY',
              status: 'ACTIVE',
              stationApiKey: 'STATION_KEY_BD01',
            ),
          ),
        );

  void setActiveStation(GateStation station) {
    state = state.copyWith(activeStation: station);
  }

  void switchStation(String stationId) {
    if (stationId == 'BD-GATE-01') {
      setActiveStation(GateStation(
        stationId: 'BD-GATE-01',
        factoryId: 'BINH_DUONG',
        gateIdentifier: 'Gate 01 - Main Entrance',
        direction: 'ENTRY',
        status: 'ACTIVE',
        stationApiKey: 'STATION_KEY_BD01',
      ));
    } else if (stationId == 'BD-GATE-02') {
      setActiveStation(GateStation(
        stationId: 'BD-GATE-02',
        factoryId: 'BINH_DUONG',
        gateIdentifier: 'Gate 01 - Main Exit',
        direction: 'EXIT',
        status: 'ACTIVE',
        stationApiKey: 'STATION_KEY_BD02',
      ));
    } else if (stationId == 'LA-GATE-01') {
      setActiveStation(GateStation(
        stationId: 'LA-GATE-01',
        factoryId: 'LONG_AN',
        gateIdentifier: 'Gate Long An - Turnstile A',
        direction: 'ENTRY',
        status: 'ACTIVE',
        stationApiKey: 'STATION_KEY_LA01',
      ));
    } else if (stationId == 'BD-MAINT-01') {
      setActiveStation(GateStation(
        stationId: 'BD-MAINT-01',
        factoryId: 'BINH_DUONG',
        gateIdentifier: 'Maintenance Gate (Disabled Test)',
        direction: 'ENTRY',
        status: 'DISABLED',
        stationApiKey: 'STATION_KEY_BD_MAINT',
      ));
    }
  }

  void toggleOfflineSimulation() {
    final nextMode = !state.isSimulatingOffline;
    state = state.copyWith(
      isSimulatingOffline: nextMode,
      syncStatusMessage: nextMode
          ? 'Đang bật mô phỏng RỚT MẠNG (Offline Buffer Active)'
          : 'Đã khôi phục mạng Online. Sẵn sàng đồng bộ.',
    );
  }

  Future<void> syncOfflineQueue() async {
    if (state.offlineQueue.isEmpty) {
      state = state.copyWith(syncStatusMessage: 'Hàng đợi ngoại tuyến trống.');
      return;
    }

    state = state.copyWith(syncStatusMessage: 'Đang đồng bộ hàng đợi ngoại tuyến...');
    final result = await _repository.syncOfflineScans(
      state.activeStation.stationId,
      state.offlineQueue,
    );

    if (result != null) {
      final processed = result['processedCount'] ?? 0;
      final dup = result['duplicateCount'] ?? 0;
      state = state.copyWith(
        offlineQueue: [],
        syncStatusMessage:
            'Đồng bộ thành công! ($processed mới, $dup trùng lặp được bỏ qua an toàn)',
      );
    } else {
      state = state.copyWith(
        syncStatusMessage: 'Đồng bộ thất bại. Vui lòng kiểm tra kết nối máy chủ.',
      );
    }
  }

  Future<void> submitScan(String qrPayload) async {
    _resetTimer?.cancel();
    _requestCounter++;
    final requestId = 'REQ-SCAN-${DateTime.now().millisecondsSinceEpoch}-$_requestCounter';

    state = state.copyWith(
      displayStatus: GateDisplayStatus.processing,
      errorMessage: null,
      syncStatusMessage: null,
    );

    final request = SubmitScanRequest(
      requestId: requestId,
      stationId: state.activeStation.stationId,
      qrPayload: qrPayload.trim(),
      deviceTimestamp: DateTime.now().toIso8601String(),
      apiKey: state.activeStation.stationApiKey,
    );

    // --- M2 Enhancement: Edge Offline Store-and-Forward (ADR-008) ---
    if (state.isSimulatingOffline) {
      final updatedQueue = [...state.offlineQueue, request];
      state = state.copyWith(
        displayStatus: GateDisplayStatus.idle,
        offlineQueue: updatedQueue,
        syncStatusMessage:
            '📶 [MẤT MẠNG] Đã lưu vào bộ đệm trạm (Hàng đợi: ${updatedQueue.length} lượt)',
      );
      return;
    }

    final response = await _repository.submitAccessScan(request);

    // If network error occurred unexpectedly, also auto-buffer into offline queue
    if (response.reasonCode?.startsWith('NETWORK_ERROR_') ?? false) {
      final updatedQueue = [...state.offlineQueue, request];
      state = state.copyWith(
        displayStatus: GateDisplayStatus.denied,
        latestResponse: response,
        offlineQueue: updatedQueue,
        errorMessage: 'Mất mạng! Giao dịch được lưu vào Offline Queue chờ đồng bộ.',
      );
      return;
    }

    GateDisplayStatus displayStatus;
    if (response.accessDecision == AccessDecision.approved) {
      if (response.controllerOutcome == 'CONTROLLER_CONFIRMED') {
        displayStatus = GateDisplayStatus.authorized;
      } else {
        displayStatus = GateDisplayStatus.controllerError;
      }
    } else {
      displayStatus = GateDisplayStatus.denied;
    }

    final updatedHistory = [response, ...state.scanHistory];

    state = state.copyWith(
      displayStatus: displayStatus,
      latestResponse: response,
      scanHistory: updatedHistory,
    );

    // Auto reset back to IDLE after 3.5 seconds
    _resetTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        state = state.copyWith(displayStatus: GateDisplayStatus.idle);
      }
    });
  }

  void resetToIdle() {
    _resetTimer?.cancel();
    state = state.copyWith(displayStatus: GateDisplayStatus.idle);
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }
}
