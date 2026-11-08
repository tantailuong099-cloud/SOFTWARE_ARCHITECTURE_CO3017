import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gate_station_provider.dart';
import '../widgets/qr_viewfinder.dart';
import '../widgets/turnstile_status_card.dart';

class GateStationKioskScreen extends ConsumerStatefulWidget {
  const GateStationKioskScreen({super.key});

  @override
  ConsumerState<GateStationKioskScreen> createState() =>
      _GateStationKioskScreenState();
}

class _GateStationKioskScreenState
    extends ConsumerState<GateStationKioskScreen> {
  final TextEditingController _qrInputController = TextEditingController();

  final List<Map<String, String>> _testQRCredentials = [
    {
      'label': '🟢 Hợp lệ BD (An)',
      'payload': 'TMC:QR:EMP-BD-001:V1:SEC_VALID_KEY_001',
      'desc': 'Nhân viên BD hợp lệ, cổng sẽ MỞ (UNLOCKED)'
    },
    {
      'label': '🟡 QR Hết hạn',
      'payload': 'TMC:QR:EMP-BD-003:V1:SEC_EXPIRED_KEY_003',
      'desc': 'QR quá 24h, từ chối CREDENTIAL_EXPIRED'
    },
    {
      'label': '🔴 QR Tạm ngưng',
      'payload': 'TMC:QR:EMP-BD-002:V1:SEC_SUSPENDED_KEY_002',
      'desc': 'HR tạm ngưng, từ chối CREDENTIAL_SUSPENDED'
    },
    {
      'label': '🟣 Sai phân xưởng (LA)',
      'payload': 'TMC:QR:EMP-LA-001:V1:SEC_VALID_KEY_LA01',
      'desc': 'Nhân viên Long An quét tại cổng Bình Dương'
    },
    {
      'label': '⚫ QR lạ / Ngoài hệ thống',
      'payload': 'HTTPS://GOOGLE.COM/UNRECOGNIZED',
      'desc': 'Mã không thuộc định dạng TMC:QR:*'
    },
  ];

  @override
  void dispose() {
    _qrInputController.dispose();
    super.dispose();
  }

  void _onTriggerScan(String payload) {
    if (payload.trim().isEmpty) return;
    _qrInputController.text = payload;
    ref.read(gateStationNotifierProvider.notifier).submitScan(payload);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gateStationNotifierProvider);
    final isScanning = state.displayStatus == GateDisplayStatus.idle ||
        state.displayStatus == GateDisplayStatus.processing;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
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
          // M2 Feature: Offline mode simulation toggle (Issue 1)
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
              color: state.activeStation.status == 'ACTIVE'
                  ? Colors.green.shade600
                  : Colors.red.shade600,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Station Overview Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    state.activeStation.direction == 'ENTRY'
                        ? Icons.login_rounded
                        : Icons.logout_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${state.activeStation.gateIdentifier} • [SLA <= 2s]',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Đổi trạm kiểm soát',
                    icon: const Icon(Icons.swap_horiz_rounded),
                    onSelected: (stationId) {
                      ref
                          .read(gateStationNotifierProvider.notifier)
                          .switchStation(stationId);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'BD-GATE-01',
                        child: Text('BD-GATE-01 (Bình Dương - ENTRY)'),
                      ),
                      const PopupMenuItem(
                        value: 'BD-GATE-02',
                        child: Text('BD-GATE-02 (Bình Dương - EXIT)'),
                      ),
                      const PopupMenuItem(
                        value: 'LA-GATE-01',
                        child: Text('LA-GATE-01 (Long An - ENTRY)'),
                      ),
                      const PopupMenuItem(
                        value: 'BD-MAINT-01',
                        child: Text('BD-MAINT-01 (Vô hiệu hóa test)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

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
              child: QRViewfinder(isScanning: isScanning),
            ),

            const SizedBox(height: 16),

            // Turnstile State Feedback Card
            TurnstileStatusCard(
              status: state.displayStatus,
              response: state.latestResponse,
              activeStation: state.activeStation,
            ),

            const SizedBox(height: 20),

            // Quick Test Cases Header
            Row(
              children: [
                const Icon(Icons.touch_app_rounded,
                    size: 18, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(
                  'Thử nghiệm nhanh mẫu QR (Quick Test Payloads):',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick Test Buttons Wrap
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _testQRCredentials.map((item) {
                return ActionChip(
                  avatar: const Icon(Icons.qr_code, size: 16),
                  label: Text(
                    item['label']!,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _onTriggerScan(item['payload']!),
                  tooltip: item['desc'],
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Manual QR Input Form
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qrInputController,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Nhập hoặc dán chuỗi QR payload...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _onTriggerScan(_qrInputController.text),
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('QUÉT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
