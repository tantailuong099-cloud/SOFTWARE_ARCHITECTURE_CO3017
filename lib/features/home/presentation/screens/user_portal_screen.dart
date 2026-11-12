import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tmc_gate_app/features/auth/domain/user_role.dart';
import 'package:tmc_gate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:tmc_gate_app/features/gate_station/data/models/access_scan_models.dart';
import 'package:tmc_gate_app/features/gate_station/domain/dynamic_qr_source.dart';
import 'package:tmc_gate_app/features/gate_station/domain/gate_event_types.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/dynamic_qr_controller.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/employee_attendance_provider.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/widgets/qr_code_widget.dart';

class UserPortalScreen extends ConsumerStatefulWidget {
  const UserPortalScreen({super.key});

  @override
  ConsumerState<UserPortalScreen> createState() => _UserPortalScreenState();
}

class _UserPortalScreenState extends ConsumerState<UserPortalScreen> {
  int _selectedTab = 0;
  bool _useDynamicQR = true;

  DynamicQRController get _dynamicQRController =>
      ref.read(dynamicQRControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authNotifierProvider);
      final empCode = auth.employeeCode ?? 'EMP-BD-001';
      _dynamicQRController.selectEmployee(empCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userRole = AppUserRole.fromString(authState.role);
    final employeeCode = authState.employeeCode ?? 'EMP-BD-001';
    final employeeName = authState.name ?? authState.email ?? 'Nhân viên';
    final dynamicQRState = ref.watch(dynamicQRControllerProvider);

    final staticQRPayload = 'TMC:QR:$employeeCode:V1:SEC_VALID_KEY_001';
    final activePayload = _useDynamicQR
        ? (_dynamicQRController.validPayload ?? staticQRPayload)
        : staticQRPayload;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.badge_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TMC EMPLOYEE PASS',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '$employeeName • $employeeCode',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Switch to Admin Portal button if user is Admin
          if (userRole == AppUserRole.admin)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TextButton.icon(
                onPressed: () => context.go('/admin'),
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 16, color: Colors.amber),
                label: const Text(
                  'Sang Trang Admin',
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
      body: IndexedStack(
        index: _selectedTab,
        children: [
          // Tab 0: Digital Badge & QR Pass
          _buildPassTab(
            context: context,
            employeeName: employeeName,
            employeeCode: employeeCode,
            userRole: userRole,
            dynamicQRState: dynamicQRState,
            activePayload: activePayload,
          ),

          // Tab 1: Attendance History
          _buildAttendanceHistoryTab(context, employeeCode),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (idx) => setState(() => _selectedTab = idx),
        backgroundColor: Colors.white,
        elevation: 4,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge_rounded),
            label: 'Thẻ Nhân Viên',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_toggle_off_rounded),
            label: 'Lịch Sử Cá Nhân',
          ),
        ],
      ),
    );
  }

  // --- TAB 0: DIGITAL EMPLOYEE PASS ---
  Widget _buildPassTab({
    required BuildContext context,
    required String employeeName,
    required String employeeCode,
    required AppUserRole userRole,
    required DynamicQRState dynamicQRState,
    required String activePayload,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: [
              // Digital Employee Card
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Card Top Banner
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.shield_rounded,
                                  color: Colors.blueAccent,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'TMC SMART PASS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                            ),
                            child: const Row(
                              children: [
                                CircleAvatar(radius: 3, backgroundColor: Colors.greenAccent),
                                SizedBox(width: 5),
                                Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // QR Surface
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          // QR Code Widget
                          if (_useDynamicQR)
                            _buildDynamicQRView(dynamicQRState, activePayload)
                          else
                            QRCodeWidget(data: activePayload, size: 180),

                          const SizedBox(height: 14),

                          // Mode badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: _useDynamicQR ? Colors.blue.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _useDynamicQR ? Colors.blue.shade200 : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              _useDynamicQR
                                  ? '🛡️ Dynamic QR (Mã xoay vòng bảo mật 30s)'
                                  : '🏷️ Static QR (Mã QR tiêu chuẩn)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _useDynamicQR ? Colors.blue.shade800 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Employee Details Footer
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white12,
                            child: Text(
                              employeeName.isNotEmpty ? employeeName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employeeName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mã NV: $employeeCode • Nhà máy Bình Dương',
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Segmented Toggle Dynamic vs Static
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Mã Động 30s (Khuyên dùng)'),
                    icon: Icon(Icons.sync_lock_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Mã Tĩnh'),
                    icon: Icon(Icons.qr_code_2_rounded, size: 16),
                  ),
                ],
                selected: {_useDynamicQR},
                onSelectionChanged: (val) {
                  final dynamicMode = val.single;
                  setState(() => _useDynamicQR = dynamicMode);
                  _dynamicQRController.selectEmployee(dynamicMode ? employeeCode : null);
                },
              ),

              const SizedBox(height: 16),

              // Quick Actions Row
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: activePayload));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép mã QR vào bộ nhớ tạm'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Sao chép chuỗi mã QR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Xuất trình mã QR này trước camera Trạm Kiosk tại cổng do Bảo vệ/Quản trị viên vận hành để quét vào/ra.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicQRView(DynamicQRState state, String payload) {
    if (state is DynamicQRReady) {
      return Column(
        children: [
          QRCodeWidget(data: payload, size: 180),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: Colors.blueAccent),
              const SizedBox(width: 6),
              Text(
                'Mã làm mới sau: ${state.remainingSeconds}s',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 160,
              height: 4,
              child: LinearProgressIndicator(
                value: state.remainingSeconds / 30.0,
                backgroundColor: Colors.grey.shade200,
                color: state.remainingSeconds < 6 ? Colors.red : Colors.blueAccent,
              ),
            ),
          ),
        ],
      );
    }

    if (state is DynamicQRError) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
              const SizedBox(height: 8),
              const Text(
                'Chưa lấy được mã động từ máy chủ',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              FilledButton.tonalIcon(
                onPressed: () {
                  _dynamicQRController.selectEmployee(null);
                  final auth = ref.read(authNotifierProvider);
                  final empCode = auth.employeeCode ?? 'EMP-BD-001';
                  _dynamicQRController.selectEmployee(empCode);
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox(
      height: 180,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  // --- TAB 1: PERSONAL ATTENDANCE HISTORY ---
  Widget _buildAttendanceHistoryTab(BuildContext context, String employeeCode) {
    final historyAsync = ref.watch(employeeAttendanceEventsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.history_rounded, color: Colors.teal.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lịch Sử Quẹt Thẻ Cá Nhân',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Dữ liệu điểm danh thời gian thực lưu trên cơ sở dữ liệu Backend',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => ref.invalidate(employeeAttendanceEventsProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Tải lại',
                  ),
                ],
              ),
            ),
          ),

          historyAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Text('Không thể tải lịch sử: $err'),
              ),
            ),
            data: (events) {
              if (events.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có dữ liệu quẹt thẻ nào được lưu trên máy chủ',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Hãy thực hiện quẹt thẻ ở Tab "Thẻ Nhân Viên" hoặc "Quẹt Thẻ / Vào Ca" để tạo lịch sử!',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ev = events[index];
                      final isApproved = ev.accessDecision == AccessDecision.approved;
                      final isEntry = ev.direction == GateDirection.entry;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isApproved ? Colors.green.shade50 : Colors.red.shade50,
                                child: Icon(
                                  isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
                                  color: isApproved ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isEntry ? Colors.blue.shade50 : Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isEntry ? 'VÀO CA (ENTRY)' : 'TAN CA (EXIT)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isEntry ? Colors.blue.shade800 : Colors.orange.shade800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isApproved ? 'HỢP LỆ • CỔNG ĐÃ MỞ' : 'BỊ TỪ CHỐI',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isApproved ? Colors.green.shade700 : Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Trạm: ${ev.stationId} (${ev.factoryId ?? "N/A"})',
                                      style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
                                    ),
                                    if (ev.denialReason != null)
                                      Text(
                                        'Lý do từ chối: ${ev.denialReason}',
                                        style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    ev.serverTimestamp.toLocal().toString().split('.').first,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ev.controllerOutcome.name,
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: events.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
