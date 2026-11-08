import 'access_scan_models.dart'
    show AccessDecision, ControllerOutcome, GateDirection;

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

  const RecentGateEvent._({
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

  factory RecentGateEvent.fromJson(Map<String, dynamic> json) {
    String? readOptionalText(String field) {
      final value = json[field];
      if (value == null) return null;
      if (value is String && value.trim().isNotEmpty) return value;
      throw FormatException('Invalid recent event field: $field');
    }

    String readRequiredText(String field) =>
        readOptionalText(field) ??
        (throw FormatException('Missing recent event field: $field'));

    final decision = switch (readRequiredText('accessDecision')) {
      'APPROVED' => AccessDecision.approved,
      'DENIED' => AccessDecision.denied,
      _ => throw const FormatException('Unknown recent event accessDecision'),
    };
    final controllerOutcome = switch (readRequiredText('controllerOutcome')) {
      'CONTROLLER_CONFIRMED' => ControllerOutcome.controllerConfirmed,
      'CONTROLLER_FAILED' => ControllerOutcome.controllerFailed,
      'CONTROLLER_PENDING' => ControllerOutcome.controllerPending,
      'NOT_APPLICABLE' => ControllerOutcome.notApplicable,
      _ => ControllerOutcome.controllerUnknown,
    };
    final direction = switch (readOptionalText('direction')) {
      'ENTRY' => GateDirection.entry,
      'EXIT' => GateDirection.exit,
      null => null,
      _ => throw const FormatException('Unknown recent event direction'),
    };
    final deviceTimestamp = readOptionalText('deviceTimestamp');

    return RecentGateEvent._(
      eventId: readRequiredText('eventId'),
      stationId: readRequiredText('stationId'),
      serverTimestamp: _readTimestamp(
        readRequiredText('serverTimestamp'),
        'serverTimestamp',
      ),
      accessDecision: decision,
      controllerOutcome: controllerOutcome,
      employeeId: readOptionalText('employeeId'),
      employeeName: readOptionalText('employeeName'),
      factoryId: readOptionalText('factoryId'),
      direction: direction,
      denialReason: readOptionalText('denialReason'),
      requestId: readOptionalText('requestId'),
      deviceTimestamp: deviceTimestamp == null
          ? null
          : _readTimestamp(deviceTimestamp, 'deviceTimestamp'),
      correlationId: readOptionalText('correlationId'),
      policyVersion: readOptionalText('policyVersion'),
    );
  }

  static final _timestampFormat = RegExp(
    r'^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})(?:\.\d+)?'
    r'(?:Z|[+-](?:[01]\d|2[0-3]):[0-5]\d)$',
  );

  static DateTime _readTimestamp(String value, String field) {
    final match = _timestampFormat.firstMatch(value);
    if (match != null) {
      // Reject calendar values that DateTime would silently normalize.
      final localTime = match[1]!;
      final calendarTime = DateTime.tryParse('${localTime}Z');
      final timestamp = DateTime.tryParse(value);
      if (timestamp != null &&
          calendarTime != null &&
          calendarTime.toIso8601String().startsWith(localTime)) {
        return timestamp;
      }
    }
    throw FormatException(
      'Expected a recent event timestamp with timezone: $field',
    );
  }
}
