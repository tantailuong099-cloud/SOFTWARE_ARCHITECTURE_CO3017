import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/access_scan_models.dart';
import '../providers/gate_station_provider.dart';
import '../providers/kiosk_management_provider.dart';

class KioskManagementScreen extends ConsumerStatefulWidget {
  const KioskManagementScreen({super.key});

  @override
  ConsumerState<KioskManagementScreen> createState() => _KioskManagementScreenState();
}

class _KioskManagementScreenState extends ConsumerState<KioskManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddKioskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _AddKioskDialog(),
    );
  }

  void _showEditKioskDialog(BuildContext context, GateStation station) {
    showDialog(
      context: context,
      builder: (ctx) => _EditKioskDialog(station: station),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kioskManagementProvider);
    final notifier = ref.read(kioskManagementProvider.notifier);
    final activeStation = ref.watch(
      gateStationNotifierProvider.select((s) => s.activeStation),
    );
    final filteredStations = state.filteredStations;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Header Banner
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.sensor_door_rounded,
                          color: Colors.indigo,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Quản Lý Cổng Trạm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: state.isLoading ? null : () => notifier.loadStations(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        tooltip: 'Tải lại danh sách',
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _showAddKioskDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Thêm cổng', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quản lý, kích hoạt và cấu hình các trạm kiểm soát ra/vào TMC',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
                  ),

                  const SizedBox(height: 14),

                  // Quick Stats Row
                  Row(
                    children: [
                      _buildStatCard(
                        title: 'Tổng cổng',
                        count: state.totalCount,
                        color: Colors.indigo,
                        icon: Icons.meeting_room_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        title: 'Hoạt động',
                        count: state.activeCount,
                        color: Colors.teal,
                        icon: Icons.check_circle_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        title: 'Tạm dừng',
                        count: state.inactiveCount,
                        color: Colors.orange.shade800,
                        icon: Icons.pause_circle_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Filters & Search (2 rows for responsive mobile layout)
                  Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: notifier.setSearchQuery,
                        decoration: InputDecoration(
                          hintText: 'Tìm theo mã cổng, tên trạm, vị trí...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    notifier.setSearchQuery('');
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Factory Filter
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: state.factoryFilter,
                                  isExpanded: true,
                                  icon: const Icon(Icons.factory_outlined, size: 16),
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                                  onChanged: (val) {
                                    if (val != null) notifier.setFactoryFilter(val);
                                  },
                                  items: const [
                                    DropdownMenuItem(value: 'ALL', child: Text('Tất cả xưởng')),
                                    DropdownMenuItem(value: 'BINH_DUONG', child: Text('Bình Dương')),
                                    DropdownMenuItem(value: 'LONG_AN', child: Text('Long An')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status Filter
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: state.statusFilter,
                                  isExpanded: true,
                                  icon: const Icon(Icons.toggle_on_outlined, size: 16),
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                                  onChanged: (val) {
                                    if (val != null) notifier.setStatusFilter(val);
                                  },
                                  items: const [
                                    DropdownMenuItem(value: 'ALL', child: Text('Mọi trạng thái')),
                                    DropdownMenuItem(value: 'ACTIVE', child: Text('Đang hoạt động')),
                                    DropdownMenuItem(value: 'INACTIVE', child: Text('Dừng hoạt động')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Error banner
          if (state.errorMessage != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Kiosk Stations List
          if (state.isLoading && state.stations.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredStations.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.door_sliding_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Không tìm thấy cổng Kiosk phù hợp',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hãy tạo cổng mới bằng nút "Thêm cổng Kiosk" phía trên',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final station = filteredStations[index];
                    final isCurrentActive = station.stationId == activeStation.stationId;
                    return _buildKioskCard(context, station, isCurrentActive);
                  },
                  childCount: filteredStations.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKioskCard(BuildContext context, GateStation station, bool isCurrentActive) {
    final isActive = station.isActive;
    final isEntry = station.direction == 'ENTRY';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentActive
              ? Colors.indigo
              : (isActive ? Colors.grey.shade200 : Colors.orange.shade200),
          width: isCurrentActive ? 1.8 : 1.0,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Icon + Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Direction Icon Badge
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEntry ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isEntry ? Colors.green.shade200 : Colors.blue.shade200,
                    ),
                  ),
                  child: Icon(
                    isEntry ? Icons.login_rounded : Icons.logout_rounded,
                    color: isEntry ? Colors.green.shade700 : Colors.blue.shade700,
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
                          Expanded(
                            child: Text(
                              station.gateIdentifier,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.teal.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isActive ? Colors.teal.shade300 : Colors.orange.shade300,
                              ),
                            ),
                            child: Text(
                              isActive ? 'HOẠT ĐỘNG' : 'TẠM DỪNG',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.teal.shade800 : Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              station.stationId,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Text(
                            station.factoryId == 'BINH_DUONG' ? 'NM Bình Dương' : 'NM Long An',
                            style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                          ),
                          Text(
                            isEntry ? 'Cổng vào' : 'Cổng ra',
                            style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                          ),
                        ],
                      ),
                      if (station.location != null && station.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 12, color: Colors.blueGrey.shade400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                station.location!,
                                style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 8),

            // Bottom Actions Row
            Row(
              children: [
                if (isCurrentActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.indigo.shade300),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: Colors.indigo),
                        SizedBox(width: 4),
                        Text(
                          'Trạm hiện tại',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(gateStationNotifierProvider.notifier).setActiveStation(station);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã chọn ${station.gateIdentifier} làm trạm quét chính.'),
                          backgroundColor: Colors.indigo,
                        ),
                      );
                    },
                    icon: const Icon(Icons.radio_button_unchecked, size: 14),
                    label: const Text('Chọn trạm', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                const Spacer(),

                // Edit Button
                IconButton.outlined(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  tooltip: 'Chỉnh sửa cổng',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () => _showEditKioskDialog(context, station),
                ),
                const SizedBox(width: 6),

                // Toggle Stop / Start Activity
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(isActive ? 'Dừng hoạt động cổng Kiosk?' : 'Kích hoạt lại cổng Kiosk?'),
                        content: Text(
                          isActive
                              ? 'Khi dừng hoạt động, cổng ${station.gateIdentifier} (${station.stationId}) sẽ từ chối tất cả lượt quẹt thẻ (STATION_INACTIVE).'
                              : 'Kích hoạt lại cổng ${station.gateIdentifier} để cho phép nhân viên quẹt thẻ và mở barie bình thường.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Hủy'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: isActive ? Colors.orange.shade800 : Colors.teal,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(isActive ? 'Dừng hoạt động' : 'Kích hoạt'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final ok = await ref.read(kioskManagementProvider.notifier).toggleStationStatus(station.stationId);
                      if (context.mounted && ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã cập nhật trạng thái cổng '),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                    size: 14,
                    color: isActive ? Colors.orange.shade900 : Colors.teal.shade800,
                  ),
                  label: Text(
                    isActive ? 'Dừng' : 'Mở lại',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.orange.shade900 : Colors.teal.shade800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isActive ? Colors.orange.shade50 : Colors.teal.shade50,
                    side: BorderSide(color: isActive ? Colors.orange.shade200 : Colors.teal.shade200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 6),

                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                  tooltip: 'Xóa cổng Kiosk',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xác nhận xóa cổng Kiosk?'),
                        content: Text(
                          'Bạn có chắc chắn muốn xóa vĩnh viễn cổng ${station.gateIdentifier} (${station.stationId}) khỏi hệ thống không?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Hủy'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Xóa cổng'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final ok = await ref.read(kioskManagementProvider.notifier).deleteStation(station.stationId);
                      if (context.mounted && ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã xóa cổng '),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog: Thêm mới Cổng Kiosk
class _AddKioskDialog extends ConsumerStatefulWidget {
  const _AddKioskDialog();

  @override
  ConsumerState<_AddKioskDialog> createState() => _AddKioskDialogState();
}

class _AddKioskDialogState extends ConsumerState<_AddKioskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  String _factoryId = 'BINH_DUONG';
  String _direction = 'ENTRY';

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(kioskManagementProvider.notifier).createStation(
        stationCode: _codeController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        factoryId: _factoryId,
        direction: _direction,
        location: _locationController.text.trim(),
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm cổng Kiosk mới thành công!'),
              backgroundColor: Colors.teal,
            ),
          );
        } else {
          final err = ref.read(kioskManagementProvider).errorMessage ?? 'Lỗi không xác định';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kioskManagementProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.sensor_door_rounded, color: Colors.indigo),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Thêm Cổng Kiosk Mới',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Mã trạm Kiosk
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Mã trạm cổng (Station Code) *',
                      hintText: 'Ví dụ: BD-GATE-03 hoặc LA-GATE-02',
                      prefixIcon: Icon(Icons.tag_rounded, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập mã trạm' : null,
                  ),
                  const SizedBox(height: 14),

                  // Tên cổng
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên cổng Kiosk *',
                      hintText: 'Ví dụ: Cổng 3 - Lối Đi Bộ Phía Tây',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập tên cổng' : null,
                  ),
                  const SizedBox(height: 14),

                  // Phân xưởng
                  DropdownButtonFormField<String>(
                    value: _factoryId,
                    decoration: const InputDecoration(
                      labelText: 'Phân xưởng trực thuộc *',
                      prefixIcon: Icon(Icons.factory_outlined, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'BINH_DUONG', child: Text('Nhà máy Bình Dương (BINH_DUONG)')),
                      DropdownMenuItem(value: 'LONG_AN', child: Text('Nhà máy Long An (LONG_AN)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _factoryId = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Hướng kiểm soát
                  DropdownButtonFormField<String>(
                    value: _direction,
                    decoration: const InputDecoration(
                      labelText: 'Hướng cổng kiểm soát *',
                      prefixIcon: Icon(Icons.compare_arrows_rounded, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ENTRY', child: Text('Cổng vào (ENTRY - Điểm danh vào ca)')),
                      DropdownMenuItem(value: 'EXIT', child: Text('Cổng ra (EXIT - Điểm danh ra ca)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _direction = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Vị trí lắp đặt
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Vị trí lắp đặt *',
                      hintText: 'Ví dụ: Khu vực cổng số 3, dãy văn phòng B',
                      prefixIcon: Icon(Icons.place_outlined, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập vị trí' : null,
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: state.isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: state.isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                        ),
                        child: state.isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Thêm cổng Kiosk'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Dialog: Chỉnh sửa Cổng Kiosk
class _EditKioskDialog extends ConsumerStatefulWidget {
  final GateStation station;
  const _EditKioskDialog({required this.station});

  @override
  ConsumerState<_EditKioskDialog> createState() => _EditKioskDialogState();
}

class _EditKioskDialogState extends ConsumerState<_EditKioskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;

  late String _factoryId;
  late String _direction;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.station.gateIdentifier);
    _locationController = TextEditingController(text: widget.station.location ?? widget.station.gateIdentifier);
    _factoryId = widget.station.factoryId;
    _direction = widget.station.direction;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(kioskManagementProvider.notifier).updateStation(
        widget.station.stationId,
        name: _nameController.text.trim(),
        factoryId: _factoryId,
        direction: _direction,
        location: _locationController.text.trim(),
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật thông tin cổng Kiosk!'),
              backgroundColor: Colors.teal,
            ),
          );
        } else {
          final err = ref.read(kioskManagementProvider).errorMessage ?? 'Lỗi không xác định';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kioskManagementProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chỉnh Sửa Cổng Kiosk',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Mã trạm: ${widget.station.stationId}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Tên cổng
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên cổng Kiosk *',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập tên cổng' : null,
                  ),
                  const SizedBox(height: 14),

                  // Phân xưởng
                  DropdownButtonFormField<String>(
                    value: _factoryId,
                    decoration: const InputDecoration(
                      labelText: 'Phân xưởng trực thuộc *',
                      prefixIcon: Icon(Icons.factory_outlined, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'BINH_DUONG', child: Text('Nhà máy Bình Dương (BINH_DUONG)')),
                      DropdownMenuItem(value: 'LONG_AN', child: Text('Nhà máy Long An (LONG_AN)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _factoryId = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Hướng kiểm soát
                  DropdownButtonFormField<String>(
                    value: _direction,
                    decoration: const InputDecoration(
                      labelText: 'Hướng cổng kiểm soát *',
                      prefixIcon: Icon(Icons.compare_arrows_rounded, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ENTRY', child: Text('Cổng vào (ENTRY)')),
                      DropdownMenuItem(value: 'EXIT', child: Text('Cổng ra (EXIT)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _direction = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Vị trí lắp đặt
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Vị trí lắp đặt *',
                      prefixIcon: Icon(Icons.place_outlined, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập vị trí' : null,
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: state.isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: state.isSubmitting ? null : _submit,
                        child: state.isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Lưu thay đổi'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
