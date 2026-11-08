import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/features/gate_station/data/gate_station_repository.dart';
import 'package:tmc_gate_app/features/gate_station/data/models/dynamic_qr_model.dart';

const _response = <String, dynamic>{
  'employeeId': 'EMP-BD-001',
  'employeeName': 'Nguyen Van An',
  'factoryId': 'BINH_DUONG',
  'qrPayload': 'TMC:DYN:EMP-BD-001:1893456000000:ca128d20:4b73ac0e501dbcf9',
  'generatedAt': '2030-01-01T07:00:00+07:00',
  'expiresAt': '2030-01-01T00:01:00.000Z',
  'validDurationSeconds': 60,
};

void main() {
  test(
    'parses the backend response and normalizes timestamps to UTC',
    () async {
      final repository = _repositoryRespondingWith(_response);
      final credential = await repository.fetchDynamicQR('EMP-BD-001');

      expect(credential.employeeId, _response['employeeId']);
      expect(credential.employeeName, _response['employeeName']);
      expect(credential.factoryId, _response['factoryId']);
      expect(credential.qrPayload, _response['qrPayload']);
      expect(credential.generatedAt, DateTime.utc(2030));
      expect(credential.expiresAt, DateTime.utc(2030, 1, 1, 0, 1));
      expect(credential.validDurationSeconds, 60);
    },
  );

  test('rejects missing, invalid, and inconsistent model fields', () {
    for (final changes in <Map<String, dynamic>>[
      {'employeeId': null},
      {'employeeName': 100},
      {'factoryId': ''},
      {'qrPayload': ' '},
      {'qrPayload': ' credential '},
      {'generatedAt': 'not a date'},
      {'expiresAt': '2030-02-30T00:01:00Z'},
      {'expiresAt': '2030-01-01T00:01:00+00:70'},
      {'expiresAt': '2030-01-01T00:01:00'},
      {'expiresAt': '2029-12-31T23:59:59Z'},
      {'validDurationSeconds': 0},
      {'validDurationSeconds': '60'},
    ]) {
      expect(
        () => DynamicQR.fromJson({..._response, ...changes}),
        throwsFormatException,
        reason: changes.toString(),
      );
    }
  });

  test(
    'repository rejects a non-object or another employee response',
    () async {
      await expectLater(
        _repositoryRespondingWith([]).fetchDynamicQR('EMP-BD-001'),
        throwsFormatException,
      );
      await expectLater(
        _repositoryRespondingWith(_response).fetchDynamicQR('EMP-LA-001'),
        throwsFormatException,
      );
    },
  );
}

GateStationRepository _repositoryRespondingWith(Object data) {
  final dio = Dio();
  addTearDown(dio.close);
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(Response(requestOptions: options, data: data));
      },
    ),
  );
  return GateStationRepository(dio);
}
