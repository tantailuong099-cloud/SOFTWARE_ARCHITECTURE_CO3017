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
          title: const Text('Khu Vực Quản Trị Viên (Admin)'),
          backgroundColor: Colors.indigo.shade900,
          foregroundColor: Colors.white,
        ),
        body: AccessDeniedWidget(
          title: 'Từ Chối Quyền Truy Cập Khu Vực Quản Trị',
          message:
              'Tài khoản của bạn thuộc vai trò Nhân viên (EMPLOYEE). Khu vực Quản trị Admin chỉ dành cho ban quản lý hệ thống.',
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
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.indigo.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'TMC ADMIN PORTAL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ADMIN SITE',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$adminName • Toàn quyền quản trị hệ thống',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Switch to User View (Xem thẻ cá nhân)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/user'),
              icon: const Icon(Icons.badge_outlined, size: 16),
              label: const Text('Xem Thẻ Nhân Viên', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.12),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Đăng xuất',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: screens[_selectedTabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) => setState(() => _selectedTabIndex = index),
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: Colors.indigo.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded, color: Colors.indigo),
            label: 'Trạm Quét Kiosk',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensor_door_outlined),
            selectedIcon: Icon(Icons.sensor_door_rounded, color: Colors.indigo),
            label: 'Quản Lý Cổng',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_alt_rounded, color: Colors.indigo),
            label: 'Người Dùng',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_toggle_off_rounded),
            selectedIcon: Icon(Icons.history_rounded, color: Colors.indigo),
            label: 'Nhật Ký Cổng',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.settings_rounded, color: Colors.indigo),
            label: 'Cấu Hình Trạm',
          ),
        ],
      ),
    );
  }
}
