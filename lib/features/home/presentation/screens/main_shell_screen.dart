import 'package:flutter/material.dart';
import '../../gate_station/presentation/screens/gate_station_kiosk_screen.dart';
import '../../gate_station/presentation/screens/recent_gate_events_screen.dart';
import '../../gate_station/presentation/screens/employee_qr_card_screen.dart';
import '../../gate_station/presentation/screens/station_settings_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    GateStationKioskScreen(),
    RecentGateEventsScreen(),
    EmployeeQRCardScreen(),
    StationSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_rounded),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Trạm quét',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history),
            label: 'Nhật ký (Bảo vệ)',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge_rounded),
            label: 'Mã QR Nhân viên',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cấu hình',
          ),
        ],
      ),
    );
  }
}
