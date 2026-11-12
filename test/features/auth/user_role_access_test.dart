import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/core/widgets/access_denied_widget.dart';
import 'package:tmc_gate_app/features/auth/domain/user_role.dart';
import 'package:tmc_gate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:tmc_gate_app/features/auth/presentation/screens/welcome_role_screen.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/employee_qr_card_screen.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/gate_station_kiosk_screen.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/recent_gate_events_screen.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/station_settings_screen.dart';
import 'package:tmc_gate_app/features/home/presentation/screens/main_shell_screen.dart';

void main() {
  group('AppUserRole Access Matrix Tests', () {
    test('AppUserRole parses strings accurately matching database roles', () {
      expect(AppUserRole.fromString('ADMIN'), AppUserRole.admin);
      expect(
        AppUserRole.fromString('SECURITY_GUARD'),
        AppUserRole.securityGuard,
      );
      expect(AppUserRole.fromString('SUPERVISOR'), AppUserRole.supervisor);
      expect(AppUserRole.fromString('HR_STAFF'), AppUserRole.hrStaff);
      expect(AppUserRole.fromString('EMPLOYEE'), AppUserRole.employee);
      expect(AppUserRole.fromString(null), AppUserRole.admin);
      expect(AppUserRole.fromString('UNKNOWN_ROLE'), AppUserRole.employee);
    });

    test('ADMIN role has access to all 4 UI modules', () {
      const role = AppUserRole.admin;
      expect(role.canAccessKiosk, isTrue);
      expect(role.canAccessRecentEvents, isTrue);
      expect(role.canAccessQrCard, isTrue);
      expect(role.canAccessSettings, isTrue);
    });

    test('SECURITY_GUARD can access Kiosk, Events, QR, but NOT Settings', () {
      const role = AppUserRole.securityGuard;
      expect(role.canAccessKiosk, isTrue);
      expect(role.canAccessRecentEvents, isTrue);
      expect(role.canAccessQrCard, isTrue);
      expect(role.canAccessSettings, isFalse);
    });

    test('SUPERVISOR can access Events and QR, but NOT Kiosk or Settings', () {
      const role = AppUserRole.supervisor;
      expect(role.canAccessKiosk, isFalse);
      expect(role.canAccessRecentEvents, isTrue);
      expect(role.canAccessQrCard, isTrue);
      expect(role.canAccessSettings, isFalse);
    });

    test('HR_STAFF can access Events and QR, but NOT Kiosk or Settings', () {
      const role = AppUserRole.hrStaff;
      expect(role.canAccessKiosk, isFalse);
      expect(role.canAccessRecentEvents, isTrue);
      expect(role.canAccessQrCard, isTrue);
      expect(role.canAccessSettings, isFalse);
    });

    test(
      'EMPLOYEE can ONLY access QR Card (blocked from Kiosk, Events, Settings)',
      () {
        const role = AppUserRole.employee;
        expect(role.canAccessKiosk, isFalse);
        expect(role.canAccessRecentEvents, isFalse);
        expect(role.canAccessQrCard, isTrue);
        expect(role.canAccessSettings, isFalse);
      },
    );
  });

  group('UI Access Control Widget Tests', () {
    testWidgets(
      'WelcomeRoleScreen renders correct permissions for SECURITY_GUARD',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authNotifierProvider.overrideWith(
                () => _FakeAuthNotifier(
                  AuthState(
                    isAuthenticated: true,
                    role: 'SECURITY_GUARD',
                    email: 'security.guard@tmc.com',
                    name: 'Dang Minh Khoa',
                    employeeCode: 'SEC-LA-001',
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: WelcomeRoleScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Dang Minh Khoa'), findsOneWidget);
        expect(find.textContaining('SECURITY_GUARD'), findsWidgets);
        expect(find.text('Trạm quét Kiosk (Gate Station)'), findsOneWidget);
        expect(find.text('Cấu hình trạm & kết nối API (Station Settings)'), findsOneWidget);
      },
    );

    testWidgets(
      'MainShellScreen filters destinations for EMPLOYEE to only 1 tab',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authNotifierProvider.overrideWith(
                () => _FakeAuthNotifier(
                  AuthState(
                    isAuthenticated: true,
                    role: 'EMPLOYEE',
                    email: 'employee01@tmc.com',
                    name: 'Nguyen Van An',
                    employeeCode: 'EMP-BD-001',
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: MainShellScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Should NOT render NavigationBar (since there is only 1 tab)
        expect(find.byType(NavigationBar), findsNothing);
        // Employee QR card should be visible
        expect(find.byType(EmployeeQRCardScreen), findsOneWidget);
        // Blocked screens should NOT be mounted
        expect(find.byType(GateStationKioskScreen), findsNothing);
        expect(find.byType(RecentGateEventsScreen), findsNothing);
        expect(find.byType(StationSettingsScreen), findsNothing);
      },
    );

    testWidgets(
      'GateStationKioskScreen displays AccessDeniedWidget for EMPLOYEE',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authNotifierProvider.overrideWith(
                () => _FakeAuthNotifier(
                  AuthState(
                    isAuthenticated: true,
                    role: 'EMPLOYEE',
                    email: 'employee01@tmc.com',
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: GateStationKioskScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AccessDeniedWidget), findsOneWidget);
        expect(
          find.text('Từ chối quyền truy cập Trạm quét Kiosk'),
          findsOneWidget,
        );
      },
    );
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  final AuthState _initialState;

  _FakeAuthNotifier(this._initialState);

  @override
  AuthState build() => _initialState;
}
