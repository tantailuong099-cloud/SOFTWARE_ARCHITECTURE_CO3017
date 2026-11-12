import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tmc_gate_app/core/widgets/access_denied_widget.dart';
import 'package:tmc_gate_app/features/auth/domain/user_role.dart';
import 'package:tmc_gate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/employee_qr_card_screen.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/gate_station_kiosk_screen.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/recent_gate_events_screen.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/station_settings_screen.dart';

class _ShellTabItem {
  final String key;
  final Widget screen;
  final NavigationDestination destination;
  final bool Function(AppUserRole) isPermitted;

  const _ShellTabItem({
    required this.key,
    required this.screen,
    required this.destination,
    required this.isPermitted,
  });
}

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;

  static final List<_ShellTabItem> _allTabs = [
    _ShellTabItem(
      key: 'kiosk',
      screen: const GateStationKioskScreen(),
      destination: const NavigationDestination(
        icon: Icon(Icons.qr_code_scanner_rounded),
        selectedIcon: Icon(Icons.qr_code_scanner),
        label: 'Trạm quét',
      ),
      isPermitted: (role) => role.canAccessKiosk,
    ),
    _ShellTabItem(
      key: 'events',
      screen: const RecentGateEventsScreen(),
      destination: const NavigationDestination(
        icon: Icon(Icons.history_rounded),
        selectedIcon: Icon(Icons.history),
        label: 'Nhật ký ra vào',
      ),
      isPermitted: (role) => role.canAccessRecentEvents,
    ),
    _ShellTabItem(
      key: 'qr_card',
      screen: const EmployeeQRCardScreen(),
      destination: const NavigationDestination(
        icon: Icon(Icons.badge_outlined),
        selectedIcon: Icon(Icons.badge_rounded),
        label: 'Mã QR Thẻ NV',
      ),
      isPermitted: (role) => role.canAccessQrCard,
    ),
    _ShellTabItem(
      key: 'settings',
      screen: const StationSettingsScreen(),
      destination: const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Cấu hình',
      ),
      isPermitted: (role) => role.canAccessSettings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userRole = AppUserRole.fromString(authState.role);

    // Lọc danh sách tab mà role hiện tại có quyền truy cập
    final permittedTabs = _allTabs
        .where((tab) => tab.isPermitted(userRole))
        .toList();

    if (permittedTabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bảng điều khiển')),
        body: AccessDeniedWidget(
          title: 'Tài khoản chưa được phân quyền',
          message:
              'Vai trò ${userRole.title} hiện chưa được cấp phép truy cập các module chức năng.',
          currentRole: userRole,
          onBack: () => context.go('/'),
        ),
      );
    }

    // Đảm bảo chỉ số tab không vượt quá danh sách được cấp quyền
    if (_currentIndex >= permittedTabs.length) {
      _currentIndex = 0;
    }

    // Trường hợp chỉ có 1 màn hình được cấp phép (ví dụ EMPLOYEE chỉ xem Mã QR Thẻ NV)
    if (permittedTabs.length == 1) {
      return Scaffold(
        body: permittedTabs[0].screen,
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: userRole.backgroundColor,
                  child: Icon(
                    userRole.icon,
                    size: 16,
                    color: userRole.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userRole.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: userRole.primaryColor,
                        ),
                      ),
                      Text(
                        'Quyền UI: Chỉ xem thẻ QR cá nhân',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Xem quyền', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Trường hợp có từ 2 màn hình trở lên (ADMIN, SECURITY_GUARD, SUPERVISOR, HR_STAFF)
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: permittedTabs.map((tab) => tab.screen).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: permittedTabs.map((tab) => tab.destination).toList(),
      ),
    );
  }
}
