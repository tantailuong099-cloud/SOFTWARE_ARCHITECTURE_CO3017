import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tmc_gate_app/core/widgets/access_denied_widget.dart';
import 'package:tmc_gate_app/features/auth/domain/user_role.dart';
import 'package:tmc_gate_app/features/auth/presentation/providers/auth_provider.dart';

import '../../domain/gate_event_types.dart';
import '../../domain/recent_gate_event.dart';
import '../../domain/recent_gate_events_source.dart';
import '../providers/gate_station_provider.dart';
import '../providers/recent_gate_events_controller.dart';

class RecentGateEventsScreen extends ConsumerWidget {
  const RecentGateEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userRole = AppUserRole.fromString(authState.role);
    if (authState.isAuthenticated && !userRole.canAccessRecentEvents) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nhật Ký Sự Kiện Ra Vào (Gate Events)')),
        body: AccessDeniedWidget(
          title: 'Từ chối quyền truy cập Nhật ký',
          message:
              'Nhật ký sự kiện ra vào chỉ dành cho Quản trị viên, Bảo vệ, Giám sát và Nhân sự.',
          currentRole: userRole,
        ),
      );
    }

    final station = ref.watch(
      gateStationNotifierProvider.select((state) => state.activeStation),
    );
    final events = ref.watch(recentGateEventsProvider);

    void refresh() => ref.invalidate(recentGateEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: Colors.indigo,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nhật Ký Quẹt Thẻ Cổng (Gate Events)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Theo dõi trực tiếp các lần quét mã QR và trạng thái đóng/mở barie từ máy chủ',
                              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: events.isLoading ? null : refresh,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Tải lại sự kiện',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Station Picker & Info Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.indigo),
                        const SizedBox(width: 6),
                        const Text(
                          'Trạm: ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Expanded(
                          child: Text(
                            '${station.stationId} • ${station.gateIdentifier}',
                            style: TextStyle(fontSize: 12, color: Colors.indigo.shade900, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          tooltip: 'Đổi trạm xem sự kiện',
                          constraints: const BoxConstraints(minWidth: 260, maxWidth: 340),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Row(
                              children: [
                                Text('Đổi trạm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down, size: 16),
                              ],
                            ),
                          ),
                          onSelected: (stationId) {
                            ref.read(gateStationNotifierProvider.notifier).switchStation(stationId);
                            refresh();
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'BD-GATE-01',
                              child: Text('BD-GATE-01 (Bình Dương Cổng 1 Vào)', overflow: TextOverflow.ellipsis),
                            ),
                            const PopupMenuItem(
                              value: 'BD-GATE-02',
                              child: Text('BD-GATE-02 (Bình Dương Cổng 1 Ra)', overflow: TextOverflow.ellipsis),
                            ),
                            const PopupMenuItem(
                              value: 'LA-GATE-01',
                              child: Text('LA-GATE-01 (Long An Turnstile A)', overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Events Content
          events.when(
            skipLoadingOnRefresh: false,
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      const Text(
                        'Không thể tải dữ liệu nhật ký sự kiện từ máy chủ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kiểm tra kết nối mạng và đảm bảo backend đang hoạt động.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: refresh,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (items) {
              if (items == null || items.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note_rounded, size: 54, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có sự kiện quẹt thẻ nào tại trạm ${station.stationId}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hãy quét thẻ nhân viên tại Trạm Kiosk để tạo bản ghi!',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
                    (context, index) => _buildEventCard(items[index]),
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(RecentGateEvent event) {
    final isApproved = event.accessDecision == AccessDecision.approved;
    final isEntry = event.direction == GateDirection.entry;

    final controllerLabel = switch (event.controllerOutcome) {
      ControllerOutcome.controllerConfirmed => 'Barie: Đã mở',
      ControllerOutcome.controllerFailed => 'Barie: Lỗi',
      ControllerOutcome.controllerUnknown => 'Barie: Chưa rõ',
      ControllerOutcome.controllerPending => 'Barie: Đang mở',
      ControllerOutcome.notApplicable => 'Barie: K/A',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isApproved ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isApproved ? Colors.green.shade50 : Colors.red.shade50,
              child: Icon(
                isApproved ? Icons.check_circle_rounded : Icons.block_rounded,
                color: isApproved ? Colors.green.shade700 : Colors.red.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          event.employeeName ?? 'Không rõ tên nhân viên',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (event.employeeId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            event.employeeId!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade800,
                            ),
                          ),
                        ),
                      const Spacer(),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isApproved ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isApproved ? Colors.green.shade300 : Colors.red.shade300,
                          ),
                        ),
                        child: Text(
                          isApproved ? 'HỢP LỆ' : 'TỪ CHỐI',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isApproved ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isEntry ? Colors.blue.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isEntry ? 'VÀO (ENTRY)' : 'RA (EXIT)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isEntry ? Colors.blue.shade700 : Colors.orange.shade800,
                          ),
                        ),
                      ),
                      Text(
                        'Trạm: ${event.stationId} (${event.factoryId ?? "N/A"})',
                        style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isApproved ? Colors.green.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          controllerLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isApproved ? Colors.green.shade800 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isApproved && event.denialReason != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'Lý do từ chối: ${event.denialReason}',
                        style: TextStyle(fontSize: 11, color: Colors.red.shade800, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Thời gian: ${event.serverTimestamp.toLocal().toString().split(".").first} • ID: ${event.eventId.substring(0, event.eventId.length > 8 ? 8 : event.eventId.length)}...',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
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
