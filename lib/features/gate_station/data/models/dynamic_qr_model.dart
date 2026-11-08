class DynamicQR {
  static final _timestampFormat = RegExp(
    r'^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})(?:\.\d+)?'
    r'(?:Z|[+-](?:[01]\d|2[0-3]):[0-5]\d)$',
  );

  final String employeeId;
  final String employeeName;
  final String factoryId;
  final String qrPayload;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final int validDurationSeconds;

  const DynamicQR._({
    required this.employeeId,
    required this.employeeName,
    required this.factoryId,
    required this.qrPayload,
    required this.generatedAt,
    required this.expiresAt,
    required this.validDurationSeconds,
  });

  factory DynamicQR.fromJson(Map<String, dynamic> json) {
    String readString(String field) {
      final value = json[field];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Invalid dynamic QR field: $field');
      }
      return value;
    }

    DateTime readTimestamp(String field) {
      final value = readString(field);
      final match = _timestampFormat.firstMatch(value);
      if (match != null) {
        // Dart normalizes invalid calendar values such as February 30.
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
        'Expected an ISO-8601 timestamp with timezone: $field',
      );
    }

    final qrPayload = readString('qrPayload');
    if (qrPayload != qrPayload.trim()) {
      throw const FormatException(
        'Unexpected whitespace in dynamic QR payload',
      );
    }

    final generatedAt = readTimestamp('generatedAt');
    final expiresAt = readTimestamp('expiresAt');
    if (!expiresAt.isAfter(generatedAt)) {
      throw const FormatException('Dynamic QR expiry must follow issuance');
    }

    final duration = json['validDurationSeconds'];
    if (duration is! int || duration <= 0) {
      throw const FormatException(
        'Invalid dynamic QR field: validDurationSeconds',
      );
    }

    return DynamicQR._(
      employeeId: readString('employeeId'),
      employeeName: readString('employeeName'),
      factoryId: readString('factoryId'),
      qrPayload: qrPayload,
      generatedAt: generatedAt,
      expiresAt: expiresAt,
      validDurationSeconds: duration,
    );
  }
}
