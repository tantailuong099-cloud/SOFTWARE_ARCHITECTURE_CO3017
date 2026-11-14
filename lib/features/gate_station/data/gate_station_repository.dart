import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tmc_gate_app/core/config/api_endpoint.dart';
import 'package:tmc_gate_app/core/network/dio_client.dart';
import '../domain/dynamic_qr_source.dart';
import 'models/access_scan_models.dart';
import 'models/dynamic_qr_model.dart';

import '../domain/recent_gate_event.dart';
import '../domain/recent_gate_events_source.dart';
import 'models/recent_gate_event_parser.dart';

final gateStationRepositoryProvider = Provider<GateStationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return GateStationRepository(dio);
});

final dynamicQRSourceProvider = Provider<DynamicQRSource>((ref) {
  return ref.watch(gateStationRepositoryProvider);
});

class GateStationRepository implements DynamicQRSource {
  final Dio _dio;

  GateStationRepository(this._dio);

  ApiEndpoint get endpoint => ApiEndpoint.parse(_dio.options.baseUrl);

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

  Future<List<RecentGateEvent>> fetchRecentEvents(String stationId) async {
    try {
      final id = Uri.encodeComponent(stationId);
      final response = await _dio.get('/access/recent-events/$id');
      final data = response.data;
      if (data is! List) throw RecentEventsFailure.invalidResponse;

      final events = <RecentGateEvent>[];
      for (final row in data) {
        if (row is! Map<String, dynamic>) {
          throw RecentEventsFailure.invalidResponse;
        }
        final event = parseRecentGateEvent(row);
        if (event.stationId != stationId) {
          throw RecentEventsFailure.invalidResponse;
        }
        events.add(event);
      }
      return List.unmodifiable(events);
    } on DioException catch (error) {
      if (error.response?.statusCode case 401 || 403) {
        throw RecentEventsFailure.unauthorized;
      }
      throw error.error is FormatException
          ? RecentEventsFailure.invalidResponse
          : RecentEventsFailure.unavailable;
    } on FormatException {
      throw RecentEventsFailure.invalidResponse;
    }
  }

  Future<List<RecentGateEvent>> fetchEmployeeEvents(String employeeId, {int limit = 50}) async {
    try {
      final response = await _dio.get(
        '/access/events',
        queryParameters: {
          'employeeId': employeeId,
          'limit': limit,
        },
      );
      final data = response.data;
      final events = <RecentGateEvent>[];
      if (data is Map && data['events'] is List) {
        for (final row in data['events']) {
          if (row is Map<String, dynamic>) {
            try {
              events.add(parseRecentGateEvent(row));
            } catch (_) {}
          }
        }
      }
      return List.unmodifiable(events);
    } catch (_) {
      return const [];
    }
  }

  Future<List<RecentGateEvent>> fetchAllEvents({int limit = 50}) async {
    try {
      final response = await _dio.get(
        '/access/events',
        queryParameters: {'limit': limit},
      );
      final data = response.data;
      final events = <RecentGateEvent>[];
      if (data is Map && data['events'] is List) {
        for (final row in data['events']) {
          if (row is Map<String, dynamic>) {
            try {
              events.add(parseRecentGateEvent(row));
            } catch (_) {}
          }
        }
      }
      return List.unmodifiable(events);
    } catch (_) {
      return const [];
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

  Future<GateStation> createGateStation({
    required String stationCode,
    required String name,
    required String factoryId,
    required String direction,
    required String location,
    String status = 'ACTIVE',
  }) async {
    try {
      final payload = {
        'stationCode': stationCode.trim(),
        'name': name.trim(),
        'factoryId': factoryId,
        'direction': direction,
        'location': location.trim(),
        'status': status,
      };
      final response = await _dio.post('/gate-stations', data: payload);
      return GateStation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Không thể tạo cổng Kiosk';
      throw Exception(msg is List ? msg.join(', ') : msg.toString());
    }
  }

  Future<GateStation> updateGateStation(
    String stationCode, {
    String? name,
    String? factoryId,
    String? direction,
    String? location,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (name != null) 'name': name.trim(),
        if (factoryId != null) 'factoryId': factoryId,
        if (direction != null) 'direction': direction,
        if (location != null) 'location': location.trim(),
      };
      final response = await _dio.patch('/gate-stations/$stationCode', data: payload);
      return GateStation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Không thể cập nhật cổng Kiosk';
      throw Exception(msg is List ? msg.join(', ') : msg.toString());
    }
  }

  Future<GateStation> updateGateStationStatus(String stationCode, String status) async {
    try {
      final response = await _dio.patch(
        '/gate-stations/$stationCode/status',
        data: {'status': status.toUpperCase()},
      );
      return GateStation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Không thể thay đổi trạng thái cổng Kiosk';
      throw Exception(msg is List ? msg.join(', ') : msg.toString());
    }
  }

  Future<bool> deleteGateStation(String stationCode) async {
    try {
      await _dio.delete('/gate-stations/$stationCode');
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Không thể xóa cổng Kiosk';
      throw Exception(msg is List ? msg.join(', ') : msg.toString());
    }
  }

  // Legacy raw-scan reconciliation.
  Future<Map<String, dynamic>?> syncOfflineScans(
    String stationId,
    List<SubmitScanRequest> scans,
  ) async {
    try {
      final payload = {
        'stationId': stationId,
        'syncTimestamp': DateTime.now().toIso8601String(),
        'scans': scans.map((scan) => scan.toJson()..remove('apiKey')).toList(),
      };
      final response = await _dio.post(
        '/access/sync-offline-scans',
        data: payload,
        options: Options(followRedirects: false),
      );
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<DynamicQR> fetchDynamicQR(String employeeId) async {
    try {
      final id = Uri.encodeComponent(employeeId);
      Response response;
      try {
        response = await _dio.get('/user-qr/employees/$id/dynamic-qr');
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          response = await _dio.get('/qr/employees/$id/dynamic-qr');
        } else {
          rethrow;
        }
      }
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw DynamicQRFailure.invalidResponse;
      }

      final credential = parseDynamicQR(data);
      if (credential.employeeId != employeeId) {
        throw DynamicQRFailure.invalidResponse;
      }
      return credential;
    } on DioException catch (error) {
      throw switch (error.response?.statusCode) {
        400 || 403 => DynamicQRFailure.employeeIneligible,
        404 => DynamicQRFailure.employeeNotFound,
        _ when error.error is FormatException =>
          DynamicQRFailure.invalidResponse,
        _ => DynamicQRFailure.unavailable,
      };
    } on FormatException {
      throw DynamicQRFailure.invalidResponse;
    }
  }
}
