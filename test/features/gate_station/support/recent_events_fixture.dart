import 'dart:async';

import 'package:tmc_gate_app/features/gate_station/domain/gate_event_types.dart';
import 'package:tmc_gate_app/features/gate_station/domain/recent_gate_event.dart';
import 'package:tmc_gate_app/features/gate_station/domain/recent_gate_events_source.dart';

Map<String, dynamic> eventJson({
  String eventId = 'event-a',
  String stationId = 'BD-GATE-01',
  String outcome = 'CONTROLLER_CONFIRMED',
}) => {
  'eventId': eventId,
  'requestId': 'request-$eventId',
  'stationId': stationId,
  'factoryId': 'BINH_DUONG',
  'direction': 'ENTRY',
  'accessDecision': 'APPROVED',
  'controllerOutcome': outcome,
  'employeeId': 'EMP-BD-001',
  'employeeName': 'Demo Employee',
  'serverTimestamp': '2026-11-08T01:23:45.678Z',
  'deviceTimestamp': '2026-11-08T08:23:44+07:00',
  'correlationId': 'correlation-$eventId',
  'policyVersion': 'v1.0',
};

RecentGateEvent recordedEvent({
  String eventId = 'event-a',
  String stationId = 'BD-GATE-01',
  AccessDecision decision = AccessDecision.approved,
  ControllerOutcome outcome = ControllerOutcome.controllerConfirmed,
  String? employeeName = 'Demo Employee',
  String? denialReason,
}) => RecentGateEvent(
  eventId: eventId,
  stationId: stationId,
  serverTimestamp: DateTime.utc(2026, 11, 8, 1, 23, 45, 678),
  accessDecision: decision,
  controllerOutcome: outcome,
  employeeId: 'EMP-BD-001',
  employeeName: employeeName,
  factoryId: 'BINH_DUONG',
  direction: GateDirection.entry,
  denialReason: denialReason,
);

class ControlledRecentEventsSource {
  final requests =
      <({String stationId, Completer<List<RecentGateEvent>> result})>[];

  Future<List<RecentGateEvent>> fetch(String stationId) {
    final result = Completer<List<RecentGateEvent>>();
    requests.add((stationId: stationId, result: result));
    return result.future;
  }

  void complete(int index, List<RecentGateEvent> events) {
    requests[index].result.complete(events);
  }

  void fail(int index, RecentEventsFailure failure) {
    requests[index].result.completeError(failure);
  }
}
