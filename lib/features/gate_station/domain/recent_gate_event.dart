import 'gate_event_types.dart';

final class RecentGateEvent {
  final String eventId;
  final String stationId;
  final DateTime serverTimestamp;
  final AccessDecision accessDecision;
  final ControllerOutcome controllerOutcome;
  final String? employeeId;
  final String? employeeName;
  final String? factoryId;
  final GateDirection? direction;
  final String? denialReason;
  final String? requestId;
  final DateTime? deviceTimestamp;
  final String? correlationId;
  final String? policyVersion;

  const RecentGateEvent({
    required this.eventId,
    required this.stationId,
    required this.serverTimestamp,
    required this.accessDecision,
    required this.controllerOutcome,
    this.employeeId,
    this.employeeName,
    this.factoryId,
    this.direction,
    this.denialReason,
    this.requestId,
    this.deviceTimestamp,
    this.correlationId,
    this.policyVersion,
  });
}
