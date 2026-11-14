import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/app/app.dart';
import 'package:tmc_gate_app/core/network/dio_client.dart';
import 'package:tmc_gate_app/features/auth/presentation/screens/login_screen.dart';
import 'package:tmc_gate_app/features/home/presentation/screens/user_portal_screen.dart';

void main() {
  testWidgets('TMC Gate App opens sign-in when no session is stored', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: TMCGateApp()));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('a restored employee session opens the user portal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dio = DioClient.create();
    FlutterSecureStorage.setMockInitialValues({
      'access_token': jsonEncode({
        'token': 'session-fixture',
        'endpoint': dio.options.baseUrl,
      }),
      'user_role': 'EMPLOYEE',
      'user_email': 'employee@example.org',
    });
    addTearDown(dio.close);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: <Object>[],
            ),
          );
        },
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: const TMCGateApp(),
      ),
    );
    await tester.pump(Duration.zero);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(UserPortalScreen), findsOneWidget);
  });
}
