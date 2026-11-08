import 'dart:async';

import 'package:tmc_gate_app/features/gate_station/data/models/recent_gate_event_model.dart';

Map<String, dynamic> eventJson({
  String eventId = 'event-a',
  String stationId = 'BD-GATE-01',
  String decision = 'APPROVED',
  String outcome = 'CONTROLLER_CONFIRMED',
}) => {
  'eventId': eventId,
  'requestId': 'request-$eventId',
  'stationId': stationId,
  'factoryId': 'BINH_DUONG',
  'direction': 'ENTRY',
  'accessDecision': decision,
  'controllerOutcome': outcome,
  'employeeId': 'EMP-BD-001',
  'employeeName': 'Demo Employee',
  'serverTimestamp': '2026-11-08T01:23:45.678Z',
  'deviceTimestamp': '2026-11-08T08:23:44+07:00',
  'correlationId': 'correlation-$eventId',
  'policyVersion': 'v1.0',
};

class ControlledRecentEventsSource {
  final requests =
      <({String stationId, Completer<List<RecentGateEvent>> result})>[];

  Future<List<RecentGateEvent>> fetch(String stationId) {
    final result = Completer<List<RecentGateEvent>>();
    requests.add((stationId: stationId, result: result));
    return result.future;
  }

  void complete(int index, List<Map<String, dynamic>> rows) {
    requests[index].result.complete(
      rows.map(RecentGateEvent.fromJson).toList(),
    );
  }

  void fail(int index, Exception failure) {
    requests[index].result.completeError(failure);
  }
}
