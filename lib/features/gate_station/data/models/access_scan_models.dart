import 'package:tmc_gate_app/core/config/api_endpoint.dart';

import '../../domain/gate_event_types.dart' show AccessDecision;

export '../../domain/gate_event_types.dart';

class SubmitScanRequest {
  final String requestId;
  final String stationId;
  final String qrPayload;
  final String? deviceTimestamp;
  final String? apiKey;
  final ApiEndpoint? backend;

  SubmitScanRequest({
    required this.requestId,
    required this.stationId,
    required this.qrPayload,
    this.deviceTimestamp,
    this.apiKey,
    this.backend,
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
  final String? location;
  final String? stationApiKey;
  final String? controllerEndpoint;

  GateStation({
    required this.stationId,
    required this.factoryId,
    required this.gateIdentifier,
    required this.direction,
    required this.status,
    this.location,
    this.stationApiKey,
    this.controllerEndpoint,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory GateStation.fromJson(Map<String, dynamic> json) {
    final code = json['stationCode']?.toString() ?? json['stationId']?.toString() ?? '';
    final name = json['name']?.toString() ?? json['gateIdentifier']?.toString() ?? code;
    return GateStation(
      stationId: code,
      factoryId: json['factoryId']?.toString() ?? 'BINH_DUONG',
      gateIdentifier: name,
      direction: json['direction']?.toString() ?? 'ENTRY',
      status: json['status']?.toString() ?? 'ACTIVE',
      location: json['location']?.toString(),
      stationApiKey: json['stationApiKey']?.toString(),
      controllerEndpoint: json['controllerEndpoint']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationCode': stationId,
      'stationId': stationId,
      'name': gateIdentifier,
      'gateIdentifier': gateIdentifier,
      'factoryId': factoryId,
      'direction': direction,
      'location': location ?? gateIdentifier,
      'status': status,
      if (stationApiKey != null) 'stationApiKey': stationApiKey,
      if (controllerEndpoint != null) 'controllerEndpoint': controllerEndpoint,
    };
  }

  GateStation copyWith({
    String? stationId,
    String? factoryId,
    String? gateIdentifier,
    String? direction,
    String? status,
    String? location,
    String? stationApiKey,
    String? controllerEndpoint,
  }) {
    return GateStation(
      stationId: stationId ?? this.stationId,
      factoryId: factoryId ?? this.factoryId,
      gateIdentifier: gateIdentifier ?? this.gateIdentifier,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      location: location ?? this.location,
      stationApiKey: stationApiKey ?? this.stationApiKey,
      controllerEndpoint: controllerEndpoint ?? this.controllerEndpoint,
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
