import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gate_station_provider.dart';
import '../../data/gate_station_repository.dart';
import '../../data/models/access_scan_models.dart';

class RecentGateEventsScreen extends ConsumerStatefulWidget {
  const RecentGateEventsScreen({super.key});

  @override
  ConsumerState<RecentGateEventsScreen> createState() =>
      _RecentGateEventsScreenState();
}

class _RecentGateEventsScreenState extends ConsumerState<RecentGateEventsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _remoteEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    final station = ref.read(gateStationNotifierProvider).activeStation;
    final repo = ref.read(gateStationRepositoryProvider);
    final events = await repo.fetchRecentEvents(station.stationId);
    if (mounted) {
      setState(() {
        _remoteEvents = events;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gateStationNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhật ký quét trạm (UC-04)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(
              'Trạm: ${state.activeStation.stationId} • Chế độ Bảo vệ (Security Guard)',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: _fetchEvents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.scanHistory.isEmpty && _remoteEvents.isEmpty
              ? _buildEmptyState()
              : _buildEventsList(state.scanHistory),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Chưa có lượt quét nào tại trạm này',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy chuyển qua tab "Quét QR" để thực hiện lượt quét đầu tiên',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<AccessScanResponse> localHistory) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: localHistory.length,
      itemBuilder: (context, index) {
        final ev = localHistory[index];
        final isApproved = ev.accessDecision == AccessDecision.approved;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isApproved ? Colors.green.shade200 : Colors.red.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor:
                      isApproved ? Colors.green.shade100 : Colors.red.shade100,
                  child: Icon(
                    isApproved ? Icons.check_circle : Icons.cancel,
                    color: isApproved ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ev.employeeName ?? 'Không xác định',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isApproved
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isApproved
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                              ),
                            ),
                            child: Text(
                              isApproved ? 'HỢP LỆ' : 'TỪ CHỐI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isApproved
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mã NV: ${ev.employeeId ?? "N/A"} • ${ev.direction ?? "ENTRY"}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      if (!isApproved && ev.reasonCode != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Lý do: ${ev.reasonCode}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Thời gian: ${_formatTime(ev.serverTimestamp)}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                          Text(
                            '${ev.processingLatencyMs}ms',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
