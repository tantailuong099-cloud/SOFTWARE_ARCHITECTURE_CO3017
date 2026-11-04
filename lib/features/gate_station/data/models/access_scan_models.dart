enum AccessDecision { approved, denied }

enum ControllerOutcome {
  controllerConfirmed,
  controllerFailed,
  controllerUnknown,
  controllerPending,
  notApplicable,
}

enum GateDirection { entry, exit }

class SubmitScanRequest {
  final String requestId;
  final String stationId;
  final String qrPayload;
  final String? deviceTimestamp;
  final String? apiKey;

  SubmitScanRequest({
    required this.requestId,
    required this.stationId,
    required this.qrPayload,
    this.deviceTimestamp,
    this.apiKey,
  });

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'stationId': stationId,
        'qrPayload': qrPayload,
        if (deviceTimestamp != null) 'deviceTimestamp': deviceTimestamp,
        if (apiKey != null) 'apiKey': apiKey,
      };
}

class AccessScanResponse {
  final String requestId;
  final AccessDecision accessDecision;
  final String? eventId;
  final String? reasonCode;
  final String controllerOutcome;
  final DateTime serverTimestamp;
  final String? employeeId;
  final String? employeeName;
  final String? factoryId;
  final String? direction;
  final int processingLatencyMs;
  final bool isCachedDuplicate;

  AccessScanResponse({
    required this.requestId,
    required this.accessDecision,
    this.eventId,
    this.reasonCode,
    required this.controllerOutcome,
    required this.serverTimestamp,
    this.employeeId,
    this.employeeName,
    this.factoryId,
    this.direction,
    required this.processingLatencyMs,
    this.isCachedDuplicate = false,
  });

  factory AccessScanResponse.fromJson(Map<String, dynamic> json) {
    return AccessScanResponse(
      requestId: json['requestId'] as String? ?? '',
      accessDecision: (json['accessDecision'] == 'APPROVED')
          ? AccessDecision.approved
          : AccessDecision.denied,
      eventId: json['eventId'] as String?,
      reasonCode: json['reasonCode'] as String?,
      controllerOutcome: json['controllerOutcome'] as String? ?? 'NOT_APPLICABLE',
      serverTimestamp: json['serverTimestamp'] != null
          ? DateTime.tryParse(json['serverTimestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      employeeId: json['employeeId'] as String?,
      employeeName: json['employeeName'] as String?,
      factoryId: json['factoryId'] as String?,
      direction: json['direction'] as String?,
      processingLatencyMs: (json['processingLatencyMs'] as num?)?.toInt() ?? 0,
      isCachedDuplicate: json['isCachedDuplicate'] as bool? ?? false,
    );
  }
}

class GateStation {
  final String stationId;
  final String factoryId;
  final String gateIdentifier;
  final String direction;
  final String status;
  final String? stationApiKey;
  final String? controllerEndpoint;

  GateStation({
    required this.stationId,
    required this.factoryId,
    required this.gateIdentifier,
    required this.direction,
    required this.status,
    this.stationApiKey,
    this.controllerEndpoint,
  });

  factory GateStation.fromJson(Map<String, dynamic> json) {
    return GateStation(
      stationId: json['stationId'] as String? ?? '',
      factoryId: json['factoryId'] as String? ?? '',
      gateIdentifier: json['gateIdentifier'] as String? ?? '',
      direction: json['direction'] as String? ?? 'ENTRY',
      status: json['status'] as String? ?? 'ACTIVE',
      stationApiKey: json['stationApiKey'] as String?,
      controllerEndpoint: json['controllerEndpoint'] as String?,
    );
  }
}

class EmployeeQRInfo {
  final String employeeId;
  final String fullName;
  final String factoryId;
  final String department;
  final String status;
  final String qrPayload;
  final String credentialStatus;
  final String description;

  EmployeeQRInfo({
    required this.employeeId,
    required this.fullName,
    required this.factoryId,
    required this.department,
    required this.status,
    required this.qrPayload,
    required this.credentialStatus,
    required this.description,
  });
}
