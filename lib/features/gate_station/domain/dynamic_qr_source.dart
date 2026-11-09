/// Retrieves the issued credential for the requested employee.
abstract interface class DynamicQRSource {
  /// Returns the matching employee's exact payload and issuer timestamps.
  ///
  /// An expired response can arrive in transit. The caller checks [DynamicQR.expiresAt]
  /// before exposing the payload. Throws [DynamicQRFailure] if issuance fails,
  /// the source is unavailable, or the response is invalid.
  Future<DynamicQR> fetchDynamicQR(String employeeId);
}

enum DynamicQRFailure implements Exception {
  employeeIneligible,
  employeeNotFound,
  unavailable,
  invalidResponse,
}

final class DynamicQR {
  final String employeeId;
  final String employeeName;
  final String factoryId;
  final String qrPayload;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final int validDurationSeconds;

  const DynamicQR({
    required this.employeeId,
    required this.employeeName,
    required this.factoryId,
    required this.qrPayload,
    required this.generatedAt,
    required this.expiresAt,
    required this.validDurationSeconds,
  });
}
