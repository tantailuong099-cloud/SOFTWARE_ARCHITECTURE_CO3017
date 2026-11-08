import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tmc_gate_app/core/network/dio_client.dart';
import 'package:tmc_gate_app/features/gate_station/data/gate_station_repository.dart';
import 'package:tmc_gate_app/features/gate_station/domain/dynamic_qr_source.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/dynamic_qr_controller.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/employee_qr_card_screen.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/widgets/qr_code_widget.dart';

import 'support/controlled_dynamic_qr_source.dart';

const _defaultEmployee = 'EMP-BD-001';
const _otherEmployee = 'EMP-LA-001';
const _staticPayload = 'TMC:QR:EMP-BD-001:V1:SEC_VALID_KEY_001';
const _serverPayload =
    'TMC:DYN:EMP-BD-001:1893456000000:ca128d20:4b73ac0e501dbcf9';
const _otherPayload =
    'TMC:DYN:EMP-LA-001:1893456000000:af820b23:bd504c91eab23003';
const _rotatedPayload =
    'TMC:DYN:EMP-BD-001:1893456030000:83adf210:1c35ad7b0610df30';

void main() {
  testWidgets('M1 displays, copies, and submits the existing static QR', (
    tester,
  ) async {
    final backend = await _openCard(tester);
    expect(find.text('Nguyen Van An'), findsOneWidget);
    expect(find.textContaining('M1 demo'), findsOneWidget);
    _expectQR(tester, _staticPayload);
    expect(backend.source.requests, isEmpty);

    await tester.tap(find.text('Copy QR'));
    await tester.tap(find.text('Test scan'));
    await tester.pump(Duration.zero);
    expect(backend.clipboard, [_staticPayload]);
    expect(backend.scans.single.options.data['qrPayload'], _staticPayload);
    backend.denyScan();
    await tester.pump(Duration.zero);
  });

  testWidgets('M2 displays, copies, and scans the exact server payload', (
    tester,
  ) async {
    final backend = await _openCard(tester);
    await _enableDynamic(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    _expectUnavailable(tester);
    expect(backend.source.requests.single.employeeId, _defaultEmployee);

    backend.issue(0, tester, payload: _serverPayload);
    await tester.pump(Duration.zero);
    _expectQR(tester, _serverPayload);
    expect(find.text('QR expires in 60s'), findsOneWidget);

    await tester.tap(find.text('Test scan'));
    await tester.pump(Duration.zero);
    expect(backend.scans.single.options.data['qrPayload'], _serverPayload);
    expect(find.text('QR scan requested'), findsOneWidget);

    await tester.tap(find.text('Copy QR'));
    expect(backend.clipboard, [_serverPayload]);
    backend.denyScan();
    await tester.pump(Duration.zero);
  });

  testWidgets('refreshes after 30 seconds and fails closed on network error', (
    tester,
  ) async {
    final backend = await _openCard(tester);
    await _enableDynamic(tester);
    backend.issue(0, tester, payload: _serverPayload);
    await tester.pump(Duration.zero);

    await tester.pump(const Duration(seconds: 29));
    expect(backend.source.requests, hasLength(1));
    expect(find.text('QR expires in 31s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(backend.source.requests, hasLength(2));
    _expectUnavailable(tester);

    backend.source.fail(1, DynamicQRFailure.unavailable);
    await tester.pump(Duration.zero);
    expect(find.textContaining('Check your connection'), findsOneWidget);
    _expectUnavailable(tester);
    await tester.tap(find.text('Retry'));
    await tester.pump(Duration.zero);
    backend.issue(2, tester, payload: _rotatedPayload);
    await tester.pump(Duration.zero);
    _expectQR(tester, _rotatedPayload);
    expect(find.text('QR expires in 60s'), findsOneWidget);
  });

  testWidgets('inactive employee response clears the previous employee QR', (
    tester,
  ) async {
    final backend = await _openCard(tester);
    await _enableDynamic(tester);
    backend.issue(0, tester, payload: _serverPayload);
    await tester.pump(Duration.zero);
    _expectQR(tester, _serverPayload);

    await _selectEmployee(tester, 'EMP-BD-003');
    expect(find.text('Le Hoang Nam'), findsOneWidget);
    expect(backend.source.requests[1].employeeId, 'EMP-BD-003');
    _expectUnavailable(tester);

    backend.source.fail(1, DynamicQRFailure.employeeIneligible);
    await tester.pump(Duration.zero);
    expect(find.textContaining('not eligible'), findsOneWidget);
    _expectUnavailable(tester);
  });

  testWidgets('rapid employee changes ignore both previous requests', (
    tester,
  ) async {
    final backend = await _openCard(tester);
    await _enableDynamic(tester);
    await _selectEmployee(tester, _otherEmployee);
    await _selectEmployee(tester, _otherEmployee);
    await _selectEmployee(tester, _defaultEmployee);
    expect(backend.source.requests.map((request) => request.employeeId), [
      _defaultEmployee,
      _otherEmployee,
      _defaultEmployee,
    ]);
    _expectUnavailable(tester);

    backend.issue(2, tester, payload: _rotatedPayload);
    await tester.pump(Duration.zero);
    _expectQR(tester, _rotatedPayload);

    backend.issue(1, tester, payload: _otherPayload);
    backend.issue(0, tester, payload: _serverPayload);
    await tester.pump(Duration.zero);
    _expectQR(tester, _rotatedPayload);
  });

  testWidgets(
    'expiry hides the QR and guards copy and scan even before rebuild',
    (tester) async {
      final backend = await _openCard(tester);
      await _enableDynamic(tester);
      backend.issue(
        0,
        tester,
        payload: _serverPayload,
        remaining: const Duration(milliseconds: 2500),
      );
      await tester.pump(Duration.zero);
      expect(find.text('QR expires in 3s'), findsOneWidget);

      // Capture the callbacks from the last rendered frame.
      final copy = _action(tester, 'Copy QR').onPressed!;
      final scan = _action(tester, 'Test scan').onPressed!;
      await tester.pump(const Duration(milliseconds: 2499));
      _expectQR(tester, _serverPayload);
      backend.clockOffset = const Duration(milliseconds: 1);
      copy();
      scan();
      backend.clockOffset = Duration.zero;
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('The dynamic QR has expired.'), findsOneWidget);
      _expectUnavailable(tester);
      expect(backend.clipboard, isEmpty);
      expect(backend.scans, isEmpty);
    },
  );

  testWidgets('returning to M1 discards an in-flight dynamic request', (
    tester,
  ) async {
    final backend = await _openCard(tester);
    await _enableDynamic(tester);
    await tester.tap(find.text('Static QR (M1)'));
    await tester.pump(Duration.zero);
    backend.issue(0, tester, payload: _serverPayload);
    await tester.pump(const Duration(seconds: 31));
    _expectQR(tester, _staticPayload);
    expect(backend.source.requests, hasLength(1));
  });

  testWidgets('disposal cancels timers and safely ignores pending responses', (
    tester,
  ) async {
    final backend = await _openCard(tester);
    await _enableDynamic(tester);
    await _selectEmployee(tester, _otherEmployee);
    backend.issue(1, tester, payload: _otherPayload);
    await tester.pump(Duration.zero);
    _expectQR(tester, _otherPayload);

    await tester.pumpWidget(const SizedBox.shrink());
    backend.issue(0, tester, payload: _serverPayload);
    await tester.pump(const Duration(seconds: 61));
    expect(backend.source.requests, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('QR widget handles empty and unencodable input', (tester) async {
    for (final input in [' ', List.filled(4000, 'x').join()]) {
      await tester.pumpWidget(MaterialApp(home: QRCodeWidget(data: input)));
      expect(find.text('Unable to display QR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

Future<_CardDependencies> _openCard(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final backend = _CardDependencies();
  addTearDown(backend.dio.close);
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      backend.clipboard.add(call.arguments['text'] as String);
    }
    return null;
  });
  addTearDown(() {
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(backend.dio),
        dynamicQRSourceProvider.overrideWithValue(backend.source),
        dynamicQRClockProvider.overrideWithValue(
          () => tester.binding.clock.now().add(backend.clockOffset),
        ),
      ],
      child: const MaterialApp(home: EmployeeQRCardScreen()),
    ),
  );
  return backend;
}

Future<void> _enableDynamic(WidgetTester tester) async {
  await tester.tap(find.text('Dynamic QR (M2)'));
  await tester.pump(Duration.zero);
}

Future<void> _selectEmployee(WidgetTester tester, String id) async {
  final dropdown = tester.widget<DropdownButton<String>>(
    find.byType(DropdownButton<String>),
  );
  dropdown.onChanged!(id);
  await tester.pump(Duration.zero);
}

void _expectQR(WidgetTester tester, String payload) {
  expect(tester.widget<QRCodeWidget>(find.byType(QRCodeWidget)).data, payload);
  expect(find.byType(QrImageView), findsOneWidget);
}

ButtonStyleButton _action(WidgetTester tester, String label) {
  return tester.widget<ButtonStyleButton>(
    find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
    ),
  );
}

void _expectUnavailable(WidgetTester tester) {
  expect(find.byType(QRCodeWidget), findsNothing);
  expect(_action(tester, 'Copy QR').onPressed, isNull);
  expect(_action(tester, 'Test scan').onPressed, isNull);
}

class _CardDependencies {
  final dio = Dio();
  final source = ControlledDynamicQRSource();
  Duration clockOffset = Duration.zero;
  final scans = <_PendingRequest>[];
  final clipboard = <String>[];

  _CardDependencies() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final request = _PendingRequest(options, handler);
          if (options.method == 'POST' && options.path == '/access/scan') {
            scans.add(request);
          } else {
            throw StateError(
              'Unexpected request: ${options.method} ${options.path}',
            );
          }
        },
      ),
    );
  }

  void issue(
    int index,
    WidgetTester tester, {
    required String payload,
    Duration remaining = const Duration(seconds: 60),
  }) {
    source.issue(
      index,
      payload: payload,
      expiresAt: tester.binding.clock.now().toUtc().add(remaining),
    );
  }

  void denyScan() {
    final scan = scans.single;
    scan.reply({
      'requestId': scan.options.data['requestId'],
      'accessDecision': 'DENIED',
    });
  }
}

class _PendingRequest {
  final RequestOptions options;
  final RequestInterceptorHandler handler;

  _PendingRequest(this.options, this.handler);

  void reply(Map<String, dynamic> data) {
    handler.resolve(
      Response(requestOptions: options, data: data, statusCode: 200),
    );
  }
}
