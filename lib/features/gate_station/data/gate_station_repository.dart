import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tmc_gate_app/core/network/dio_client.dart';
import 'models/access_scan_models.dart';

final gateStationRepositoryProvider = Provider<GateStationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return GateStationRepository(dio);
});

class GateStationRepository {
  final Dio _dio;

  GateStationRepository(this._dio);

  Future<AccessScanResponse> submitAccessScan(SubmitScanRequest request) async {
    try {
      final response = await _dio.post(
        '/access/scan',
        data: request.toJson(),
      );
      return AccessScanResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        return AccessScanResponse.fromJson(
          e.response!.data as Map<String, dynamic>,
        );
      }
      return AccessScanResponse(
        requestId: request.requestId,
        accessDecision: AccessDecision.denied,
        reasonCode: 'NETWORK_ERROR_${e.type.name}',
        controllerOutcome: 'CONTROLLER_FAILED',
        serverTimestamp: DateTime.now(),
        processingLatencyMs: 0,
      );
    } catch (e) {
      return AccessScanResponse(
        requestId: request.requestId,
        accessDecision: AccessDecision.denied,
        reasonCode: 'CLIENT_EXCEPTION: $e',
        controllerOutcome: 'CONTROLLER_FAILED',
        serverTimestamp: DateTime.now(),
        processingLatencyMs: 0,
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecentEvents(String stationId) async {
    try {
      final response = await _dio.get('/access/recent-events/$stationId');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<GateStation>> fetchGateStations() async {
    try {
      final response = await _dio.get('/gate-stations');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => GateStation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // --- M2 Enhancement: Sync Offline Scans Batch (ADR-008) ---
  Future<Map<String, dynamic>?> syncOfflineScans(
    String stationId,
    List<SubmitScanRequest> scans,
  ) async {
    try {
      final payload = {
        'stationId': stationId,
        'syncTimestamp': DateTime.now().toIso8601String(),
        'scans': scans.map((s) => s.toJson()).toList(),
      };
      final response = await _dio.post(
        '/access/sync-offline-scans',
        data: payload,
      );
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // --- M2 Enhancement: Fetch Dynamic Rotating QR (ADR-007) ---
  Future<Map<String, dynamic>?> fetchDynamicQR(String employeeId) async {
    try {
      final response = await _dio.get('/user-qr/employees/$employeeId/dynamic-qr');
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
