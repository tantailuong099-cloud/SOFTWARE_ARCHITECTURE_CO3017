import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tmc_gate_app/core/widgets/access_denied_widget.dart';
import 'package:tmc_gate_app/features/auth/domain/user_role.dart';
import 'package:tmc_gate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/gate_station_kiosk_screen.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/kiosk_management_screen.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/recent_gate_events_screen.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/station_settings_screen.dart';
import 'package:tmc_gate_app/features/user_management/presentation/screens/user_management_screen.dart';

class AdminPortalScreen extends ConsumerStatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  ConsumerState<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends ConsumerState<AdminPortalScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userRole = AppUserRole.fromString(authState.role);

    // BẢO VỆ ROUTE ADMIN: Nếu vai trò là EMPLOYEE thông thường -> Chặn truy cập
    if (userRole == AppUserRole.employee) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Khu Vực Quản Trị'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
            ),
          ],
        ),
        body: AccessDeniedWidget(
          message: 'Bạn không có quyền truy cập vào Khu Vực Quản Trị Hệ Thống TMC. '
              'Tài khoản của bạn có vai trò: ${userRole.name.toUpperCase()}.',
          currentRole: userRole,
          onBack: () => context.go('/user'),
        ),
      );
    }

    final adminName = authState.name ?? authState.email ?? 'Quản trị viên';

    final screens = [
      const GateStationKioskScreen(),
      const KioskManagementScreen(),
      const UserManagementScreen(),
      const RecentGateEventsScreen(),
      const StationSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B), // Deep Indigo / Slate
        foregroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.indigo.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'TMC ADMIN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PORTAL',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$adminName • Toàn quyền quản trị',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Switch to User View (Xem thẻ cá nhân)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/user'),
              icon: const Icon(Icons.badge_outlined, size: 15),
              label: const Text('Thẻ NV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 18),
            tooltip: 'Đăng xuất',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: screens[_selectedTabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) => setState(() => _selectedTabIndex = index),
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: Colors.indigo.shade100,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded, color: Colors.indigo),
            label: 'Kiosk',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensor_door_outlined),
            selectedIcon: Icon(Icons.sensor_door_rounded, color: Colors.indigo),
            label: 'Cổng trạm',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_alt_rounded, color: Colors.indigo),
            label: 'Người dùng',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_toggle_off_rounded),
            selectedIcon: Icon(Icons.history_rounded, color: Colors.indigo),
            label: 'Nhật ký',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.settings_rounded, color: Colors.indigo),
            label: 'Cấu hình',
          ),
        ],
      ),
    );
  }
}
