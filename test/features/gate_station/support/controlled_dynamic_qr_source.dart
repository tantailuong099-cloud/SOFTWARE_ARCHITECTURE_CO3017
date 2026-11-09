import 'dart:async';

import 'package:tmc_gate_app/features/gate_station/domain/dynamic_qr_source.dart';

class ControlledDynamicQRSource implements DynamicQRSource {
  final requests = <({String employeeId, Completer<DynamicQR> result})>[];

  @override
  Future<DynamicQR> fetchDynamicQR(String employeeId) {
    final result = Completer<DynamicQR>();
    requests.add((employeeId: employeeId, result: result));
    return result.future;
  }

  void issue(
    int index, {
    required String payload,
    required DateTime expiresAt,
  }) {
    final request = requests[index];
    request.result.complete(
      DynamicQR(
        employeeId: request.employeeId,
        employeeName: 'Employee Name',
        factoryId: 'FACTORY',
        qrPayload: payload,
        generatedAt: expiresAt.subtract(const Duration(seconds: 60)),
        expiresAt: expiresAt,
        validDurationSeconds: 60,
      ),
    );
  }

  void fail(int index, DynamicQRFailure failure) {
    requests[index].result.completeError(failure);
  }
}
