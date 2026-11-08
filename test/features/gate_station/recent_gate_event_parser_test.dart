import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/features/gate_station/domain/gate_event_types.dart';
import 'package:tmc_gate_app/features/gate_station/data/models/recent_gate_event_parser.dart';

import 'support/recent_events_fixture.dart';

void main() {
  test('parses a recorded approval and confirmed controller outcome', () {
    final event = parseRecentGateEvent(eventJson());

    expect(event.eventId, 'event-a');
    expect(event.requestId, 'request-event-a');
    expect(event.correlationId, 'correlation-event-a');
    expect(event.policyVersion, 'v1.0');
    expect(event.employeeId, 'EMP-BD-001');
    expect(event.employeeName, 'Demo Employee');
    expect(event.stationId, 'BD-GATE-01');
    expect(event.factoryId, 'BINH_DUONG');
    expect(event.direction, GateDirection.entry);
    expect(event.accessDecision, AccessDecision.approved);
    expect(event.controllerOutcome, ControllerOutcome.controllerConfirmed);
    expect(event.serverTimestamp, DateTime.utc(2026, 11, 8, 1, 23, 45, 678));
    expect(event.deviceTimestamp, DateTime.utc(2026, 11, 8, 1, 23, 44));
  });

  test(
    'handles omitted and null optional fields and keeps the denial reason',
    () {
      final event = parseRecentGateEvent({
        'eventId': 'event-denied',
        'stationId': 'LA-GATE-01',
        'serverTimestamp': '2026-11-08T01:23:45.000Z',
        'accessDecision': 'DENIED',
        'controllerOutcome': 'NOT_APPLICABLE',
        'employeeId': null,
        'denialReason': 'CREDENTIAL_SUSPENDED',
      });

      expect(event.accessDecision, AccessDecision.denied);
      expect(event.denialReason, 'CREDENTIAL_SUSPENDED');
      expect(event.controllerOutcome, ControllerOutcome.notApplicable);
      expect(event.employeeId, isNull);
      expect(event.employeeName, isNull);
      expect(event.direction, isNull);
      expect(event.deviceTimestamp, isNull);
    },
  );

  test('treats future controller outcomes as unknown', () {
    final event = parseRecentGateEvent(
      eventJson(outcome: 'CONTROLLER_ACK_DELAYED'),
    );
    expect(event.controllerOutcome, ControllerOutcome.controllerUnknown);
  });

  test('rejects invalid required values and invalid timestamps', () {
    for (final changes in <Map<String, dynamic>>[
      {'eventId': null},
      {'stationId': ' '},
      {'accessDecision': 'PENDING'},
      {'controllerOutcome': 1},
      {'serverTimestamp': null},
      {'serverTimestamp': 'not a timestamp'},
      {'serverTimestamp': '2026-02-30T01:23:45Z'},
      {'serverTimestamp': '2026-11-08T01:23:45'},
      {'deviceTimestamp': '2026-11-08T01:23:45+00:70'},
      {'employeeId': []},
    ]) {
      expect(
        () => parseRecentGateEvent({...eventJson(), ...changes}),
        throwsFormatException,
        reason: changes.toString(),
      );
    }
  });
}
