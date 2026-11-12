import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tmc_gate_app/core/widgets/access_denied_widget.dart';
import 'package:tmc_gate_app/features/auth/domain/user_role.dart';
import 'package:tmc_gate_app/features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/access_scan_models.dart';
import '../providers/gate_station_provider.dart';
import '../providers/kiosk_management_provider.dart';
import '../providers/recent_gate_events_controller.dart';
import '../widgets/qr_viewfinder.dart';
import '../widgets/turnstile_status_card.dart';

class GateStationKioskScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  const GateStationKioskScreen({super.key, this.showAppBar = false});

  @override
  ConsumerState<GateStationKioskScreen> createState() =>
      _GateStationKioskScreenState();
}

class _GateStationKioskScreenState
    extends ConsumerState<GateStationKioskScreen> {
  final TextEditingController _qrInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kioskManagementProvider.notifier).loadStations();
    });
  }

  @override
  void dispose() {
    _qrInputController.dispose();
    super.dispose();
  }

  void _onTriggerScan(String payload) async {
    if (payload.trim().isEmpty) return;
    _qrInputController.text = payload;
    await ref.read(gateStationNotifierProvider.notifier).submitScan(payload);
    ref.invalidate(recentGateEventsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userRole = AppUserRole.fromString(authState.role);
    if (authState.isAuthenticated && !userRole.canAccessKiosk) {
      return Scaffold(
        appBar: AppBar(title: const Text('TMC Gate Station Kiosk')),
        body: AccessDeniedWidget(
          title: 'Từ chối quyền truy cập Trạm quét Kiosk',
          message:
              'Trạm quét Kiosk và điều khiển barie chỉ dành cho Quản trị viên (ADMIN) và Nhân viên Bảo vệ (SECURITY_GUARD).',
          currentRole: userRole,
        ),
      );
    }

    final state = ref.watch(gateStationNotifierProvider);
    final kioskList = ref.watch(kioskManagementProvider.select((s) => s.stations));
    final isScanning = state.displayStatus == GateDisplayStatus.idle ||
        state.displayStatus == GateDisplayStatus.processing;

    final dynamicStations = kioskList.isNotEmpty
        ? kioskList
        : [
            GateStation(
              stationId: 'BD-GATE-01',
              factoryId: 'BINH_DUONG',
              gateIdentifier: 'Binh Duong - Main Entrance',
              direction: 'ENTRY',
              status: 'ACTIVE',
            ),
            GateStation(
              stationId: 'BD-GATE-02',
              factoryId: 'BINH_DUONG',
              gateIdentifier: 'Binh Duong - Main Exit',
              direction: 'EXIT',
              status: 'ACTIVE',
            ),
            GateStation(
              stationId: 'BD-GATE-03',
              factoryId: 'BINH_DUONG',
              gateIdentifier: 'Binh Duong - Auxiliary Entry',
              direction: 'ENTRY',
              status: 'ACTIVE',
            ),
            GateStation(
              stationId: 'BD-GATE-04',
              factoryId: 'BINH_DUONG',
              gateIdentifier: 'Binh Duong - Auxiliary Exit',
              direction: 'EXIT',
              status: 'ACTIVE',
            ),
            GateStation(
              stationId: 'LA-GATE-01',
              factoryId: 'LONG_AN',
              gateIdentifier: 'Long An - Gate A Entrance',
              direction: 'ENTRY',
              status: 'ACTIVE',
            ),
            GateStation(
              stationId: 'LA-GATE-02',
              factoryId: 'LONG_AN',
              gateIdentifier: 'Long An - Gate A Exit',
              direction: 'EXIT',
              status: 'ACTIVE',
            ),
            GateStation(
              stationId: 'LA-GATE-03',
              factoryId: 'LONG_AN',
              gateIdentifier: 'Long An - Auxiliary Entry',
              direction: 'ENTRY',
              status: 'ACTIVE',
            ),
            GateStation(
              stationId: 'LA-GATE-04',
              factoryId: 'LONG_AN',
              gateIdentifier: 'Long An - Auxiliary Exit',
              direction: 'EXIT',
              status: 'ACTIVE',
            ),
          ];

    final isStationActive = state.activeStation.isActive;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: widget.showAppBar
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TMC Gate Station Kiosk',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    '${state.activeStation.factoryId} • ${state.activeStation.stationId} (${state.activeStation.direction})',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: state.isSimulatingOffline
                      ? 'Đang mất mạng (Bấm để bật lại Online)'
                      : 'Mô phỏng Mất mạng (Offline Mode)',
                  icon: Icon(
                    state.isSimulatingOffline
                        ? Icons.wifi_off_rounded
                        : Icons.wifi_rounded,
                    color: state.isSimulatingOffline ? Colors.amberAccent : Colors.white,
                  ),
                  onPressed: () {
                    ref
                        .read(gateStationNotifierProvider.notifier)
                        .toggleOfflineSimulation();
                  },
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isStationActive ? Colors.green.shade600 : Colors.red.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        state.activeStation.status,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Station Overview Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: state.activeStation.direction == 'ENTRY'
                          ? Colors.blue.shade50
                          : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      state.activeStation.direction == 'ENTRY'
                          ? Icons.login_rounded
                          : Icons.logout_rounded,
                      color: state.activeStation.direction == 'ENTRY'
                          ? Colors.blue.shade700
                          : Colors.amber.shade800,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.activeStation.factoryId} • ${state.activeStation.stationId}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                        Text(
                          state.activeStation.gateIdentifier,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: state.isSimulatingOffline
                        ? 'Đang mô phỏng ngoại tuyến (Bấm để kết nối lại)'
                        : 'Mạng trực tuyến (Bấm để mô phỏng mất mạng)',
                    icon: Icon(
                      state.isSimulatingOffline
                          ? Icons.wifi_off_rounded
                          : Icons.wifi_rounded,
                      color: state.isSimulatingOffline ? Colors.orange : Colors.green.shade600,
                      size: 20,
                    ),
                    onPressed: () {
                      ref
                          .read(gateStationNotifierProvider.notifier)
                          .toggleOfflineSimulation();
                    },
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isStationActive ? Colors.green.shade600 : Colors.red.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          state.activeStation.status,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    tooltip: 'Đổi trạm kiểm soát',
                    icon: const Icon(Icons.swap_horiz_rounded),
                    constraints: const BoxConstraints(minWidth: 280, maxWidth: 360),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    onSelected: (stationId) {
                      final found = dynamicStations
                          .where((s) => s.stationId == stationId)
                          .firstOrNull;
                      if (found != null) {
                        ref
                            .read(gateStationNotifierProvider.notifier)
                            .setActiveStation(found);
                      } else {
                        ref
                            .read(gateStationNotifierProvider.notifier)
                            .switchStation(stationId);
                      }
                    },
                    itemBuilder: (context) => dynamicStations.map((st) {
                      final isSelected = st.stationId == state.activeStation.stationId;
                      return PopupMenuItem<String>(
                        value: st.stationId,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: st.isActive ? Colors.green.shade600 : Colors.red.shade600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        st.stationId,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 13,
                                          color: isSelected ? Colors.blue.shade700 : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: st.direction == 'ENTRY'
                                              ? Colors.blue.shade50
                                              : Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          st.direction,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: st.direction == 'ENTRY'
                                                ? Colors.blue.shade800
                                                : Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    st.gateIdentifier,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Inactive Kiosk Warning Banner
            if (!isStationActive) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'CỔNG KIOSK NÀY ĐANG DỪNG HOẠT ĐỘNG (INACTIVE). Mọi lượt quét thẻ sẽ bị từ chối với lý do STATION_INACTIVE.',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // M2 Edge Resilience: Offline Banner and Sync Actions
            if (state.isSimulatingOffline || state.offlineQueue.isNotEmpty || state.syncStatusMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: state.isSimulatingOffline ? const Color(0xFFFFF3CD) : const Color(0xFFE2F0D9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: state.isSimulatingOffline ? const Color(0xFFFFEEBA) : const Color(0xFFC3E6CB),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      state.isSimulatingOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                      color: state.isSimulatingOffline ? Colors.orange.shade800 : Colors.green.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.syncStatusMessage ??
                            'Hàng đợi ngoại tuyến: ${state.offlineQueue.length} lượt quét đang chờ đẩy lên server',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: state.isSimulatingOffline ? Colors.orange.shade900 : Colors.green.shade900,
                        ),
                      ),
                    ),
                    if (state.offlineQueue.isNotEmpty && !state.isSimulatingOffline)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          ref.read(gateStationNotifierProvider.notifier).syncOfflineQueue();
                        },
                        icon: const Icon(Icons.sync_rounded, size: 16),
                        label: const Text('Đồng bộ ngay'),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // QR Camera Viewfinder
            Center(
              child: QRViewfinder(
                isScanning: isScanning,
                onScanned: _onTriggerScan,
              ),
            ),

            const SizedBox(height: 16),

            // Turnstile State Feedback Card
            TurnstileStatusCard(
              status: state.displayStatus,
              response: state.latestResponse,
              activeStation: state.activeStation,
            ),

            const SizedBox(height: 20),

            // Production Manual QR / Barcode Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.keyboard_alt_outlined, color: Colors.indigo.shade400, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _qrInputController,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Nhập hoặc dùng máy quét mã vạch USB/Bluetooth...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          _onTriggerScan(val.trim());
                          _qrInputController.clear();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dán mã QR từ bộ nhớ tạm (Paste)',
                    icon: Icon(Icons.content_paste_rounded, size: 20, color: Colors.indigo.shade600),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null && data!.text!.trim().isNotEmpty) {
                        _qrInputController.text = data.text!.trim();
                        _onTriggerScan(data.text!.trim());
                        _qrInputController.clear();
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  if (_qrInputController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      onPressed: () => setState(() => _qrInputController.clear()),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_qrInputController.text.trim().isNotEmpty) {
                        _onTriggerScan(_qrInputController.text.trim());
                        _qrInputController.clear();
                      }
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Xác thực thẻ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
