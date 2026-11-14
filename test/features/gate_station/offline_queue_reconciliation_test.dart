import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/features/gate_station/data/gate_station_repository.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/gate_station_provider.dart';

void main() {
  for (final (label, statuses, pending) in [
    ('all approved', ['ACCEPTED', 'APPROVED'], 0),
    ('approved and denied', ['ACCEPTED', 'DENIED'], 0),
    ('approved and error', ['ACCEPTED', 'ERROR'], 1),
    ('partial acknowledgement', ['ACCEPTED'], 1),
    ('empty response', <String>[], 2),
    ('unknown status', ['ACCEPTED', 'UNKNOWN'], 1),
  ]) {
    test(label, () async {
      final fixture = _Fixture();
      await fixture.queueTwo();
      fixture.statuses = statuses;
      await fixture.gate.syncOfflineQueue();
      expect(fixture.gate.state.offlineQueue, hasLength(pending));
    });
  }

  test(
    'preserves network failures and retries only unresolved items',
    () async {
      final fixture = _Fixture();
      await fixture.queueTwo();
      fixture.fail = true;
      await fixture.gate.syncOfflineQueue();
      expect(fixture.gate.state.offlineQueue, hasLength(2));

      fixture.fail = false;
      fixture.statuses = ['DUPLICATE', 'PENDING'];
      fixture.duplicateFirst = true;
      await fixture.gate.syncOfflineQueue();
      final pending = fixture.gate.state.offlineQueue.single.requestId;
      fixture.duplicateFirst = false;
      fixture.statuses = ['DUPLICATE'];
      await fixture.gate.syncOfflineQueue();
      expect(fixture.sent.last, [pending]);
      expect(fixture.gate.state.offlineQueue, isEmpty);
    },
  );

  test(
    'isolates scans by endpoint and station, even on the same host',
    () async {
      final fixture = _Fixture();
      await fixture.queueTwo();
      fixture.dio.options.baseUrl = 'https://backend.example:444/api';
      await fixture.gate.syncOfflineQueue();
      expect(fixture.sent, isEmpty);
      expect(fixture.gate.state.offlineQueue, hasLength(2));

      await fixture.gate.submitScan('backend-b');
      fixture.statuses = ['DUPLICATE'];
      await fixture.gate.syncOfflineQueue();
      expect(fixture.sent.single, hasLength(1));
      expect(fixture.gate.state.offlineQueue, hasLength(2));

      fixture.dio.options.baseUrl = 'https://backend.example/api';
      fixture.gate.switchStation('BD-GATE-02');
      await fixture.gate.syncOfflineQueue();
      expect(fixture.sent, hasLength(1));
      fixture.gate.switchStation('BD-GATE-01');
      fixture.statuses = ['DUPLICATE', 'DUPLICATE'];
      await fixture.gate.syncOfflineQueue();
      expect(fixture.gate.state.offlineQueue, isEmpty);
    },
  );
}

class _Fixture {
  final dio = Dio(BaseOptions(baseUrl: 'https://backend.example/api'));
  late final gate = GateStationNotifier(GateStationRepository(dio));
  final sent = <List<String>>[];
  List<String> statuses = [];
  bool fail = false;
  bool duplicateFirst = false;

  _Fixture() {
    addTearDown(dio.close);
    addTearDown(gate.dispose);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/access/sync-offline-scans');
          expect(options.followRedirects, isFalse);
          final scans = options.data['scans'] as List;
          expect(scans.every((scan) => !scan.containsKey('apiKey')), isTrue);
          final ids = scans.map((scan) => scan['requestId'] as String).toList();
          sent.add(ids);
          if (fail) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
            return;
          }
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 201,
              data: {
                'stationId': options.data['stationId'],
                'status': statuses.every((status) => status == 'DUPLICATE')
                    ? 'COMPLETE'
                    : 'PARTIAL',
                'results': [
                  for (var index = statuses.length - 1; index >= 0; index--)
                    {'requestId': ids[index], 'status': statuses[index]},
                  if (duplicateFirst)
                    {'requestId': ids.first, 'status': statuses.first},
                ],
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> queueTwo() async {
    gate.toggleOfflineSimulation();
    await gate.submitScan('first-fixture');
    await gate.submitScan('second-fixture');
  }
}
