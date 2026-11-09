import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/core/network/dio_client.dart';
import 'package:tmc_gate_app/features/gate_station/data/gate_station_repository.dart';
import 'package:tmc_gate_app/features/gate_station/domain/dynamic_qr_source.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/dynamic_qr_controller.dart';

import 'support/controlled_dynamic_qr_source.dart';

const _employeeId = 'EMP-BD-001';
const _payload = 'TMC:DYN:EMP-BD-001:1893456000000:ca128d20:4b73ac0e501dbcf9';

void main() {
  for (final useFake in [false, true]) {
    final sourceName = useFake ? 'injected fake' : 'production repository';
    testWidgets('$sourceName obeys the same lifecycle contract', (
      tester,
    ) async {
      final now = tester.binding.clock.now;
      final fake = ControlledDynamicQRSource();
      final dio = Dio();
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final index = requests.length;
            requests.add(options);
            if (index == 1) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                ),
              );
              return;
            }

            final remaining = Duration(seconds: index == 0 ? 60 : -1);
            final expiresAt = now().toUtc().add(remaining);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'employeeId': _employeeId,
                  'employeeName': 'Employee Name',
                  'factoryId': 'FACTORY',
                  'qrPayload': _payload,
                  'generatedAt': expiresAt
                      .subtract(const Duration(seconds: 60))
                      .toIso8601String(),
                  'expiresAt': expiresAt.toIso8601String(),
                  'validDurationSeconds': 60,
                },
              ),
            );
          },
        ),
      );
      final container = ProviderContainer(
        overrides: [
          dynamicQRClockProvider.overrideWithValue(now),
          if (useFake) ...[
            dynamicQRSourceProvider.overrideWithValue(fake),
            dioProvider.overrideWith(
              (_) => throw StateError('Fake acquisition must not read Dio'),
            ),
          ] else
            dioProvider.overrideWithValue(dio),
        ],
      );
      final subscription = container.listen(
        dynamicQRControllerProvider,
        (_, _) {},
      );
      final controller = container.read(dynamicQRControllerProvider.notifier);

      try {
        expect(subscription.read(), isA<DynamicQRInitial>());
        controller.selectEmployee(_employeeId);
        expect(subscription.read(), isA<DynamicQRLoading>());
        if (useFake) {
          fake.issue(
            0,
            payload: _payload,
            expiresAt: now().add(const Duration(seconds: 60)),
          );
        }
        await tester.pump(Duration.zero);
        if (!useFake) {
          expect(requests.single.method, 'GET');
          expect(
            requests.single.path,
            '/user-qr/employees/$_employeeId/dynamic-qr',
          );
        }
        expect(
          subscription.read(),
          isA<DynamicQRReady>().having(
            (ready) => ready.remainingSeconds,
            'seconds',
            60,
          ),
        );
        expect(controller.validPayload, _payload);

        await tester.pump(const Duration(seconds: 30));
        if (useFake) fake.fail(1, DynamicQRFailure.unavailable);
        await tester.pump(Duration.zero);
        expect(
          subscription.read(),
          isA<DynamicQRError>().having(
            (error) => error.failure,
            'failure',
            DynamicQRFailure.unavailable,
          ),
        );
        expect(controller.validPayload, isNull);

        final retry = controller.retry();
        if (useFake) {
          fake.issue(
            2,
            payload: _payload,
            expiresAt: now().subtract(const Duration(seconds: 1)),
          );
        }
        await tester.pump(Duration.zero);
        await retry;
        expect(subscription.read(), isA<DynamicQRExpired>());
        expect(controller.validPayload, isNull);
        expect(useFake ? fake.requests.length : requests.length, 3);
      } finally {
        container.dispose();
        dio.close();
      }
    });
  }
}
