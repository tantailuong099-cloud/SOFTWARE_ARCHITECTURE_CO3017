import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/api_config.dart';
import '../providers/gate_station_provider.dart';

class StationSettingsScreen extends ConsumerStatefulWidget {
  const StationSettingsScreen({super.key});

  @override
  ConsumerState<StationSettingsScreen> createState() =>
      _StationSettingsScreenState();
}

class _StationSettingsScreenState extends ConsumerState<StationSettingsScreen> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveUrl() {
    ApiConfig.setCustomBaseUrl(_urlController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã lưu cấu hình API: ${ApiConfig.baseUrl}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gateStationNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Cấu hình trạm & Kiến trúc (UC-05)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Station Config Card
          Card(
            shape: RoundedRectangleRadius(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin trạm quét (Gate Station Config)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 20),
                  _row('Mã trạm (Station ID):', state.activeStation.stationId),
                  _row('Phân xưởng (Factory):', state.activeStation.factoryId),
                  _row('Tên cổng:', state.activeStation.gateIdentifier),
                  _row('Chiều kiểm soát:', state.activeStation.direction),
                  _row('Khóa bảo mật trạm:', state.activeStation.stationApiKey ?? 'KEY_AUTH'),
                  _row('Endpoint điều khiển:', state.activeStation.controllerEndpoint ?? 'Simulated Local Adapter'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Backend API Endpoint Card
          Card(
            shape: RoundedRectangleRadius(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Địa chỉ Backend Server (API Base URL)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dùng "http://localhost:3000/api" cho Windows/Desktop, hoặc "http://10.0.2.2:3000/api" cho Android Emulator',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveUrl,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('LƯU ĐỊA CHỈ SERVER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Architecture Compliance Info
          Card(
            shape: RoundedRectangleRadius(borderRadius: BorderRadius.circular(12)),
            color: const Color(0xFFE8EAF6),
            child: const Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kiến trúc hệ thống CO3017 - Milestone M2',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• ADR-001: Modular Monolith với 3 module nghiệp vụ độc lập:\n'
                    '    1. User & QR Management (Định danh & Vòng đời QR)\n'
                    '    2. Gate Station Management (Quản lý & Xác thực Trạm cổng)\n'
                    '    3. Attendance Event (Kiểm soát truy cập & Ghi nhận thô)\n'
                    '• ADR-002: Xác thực tính toàn vẹn QR trước khi kiểm tra quyền hạn máy chủ\n'
                    '• ADR-003: Ghi nhận bền vững quyết định trước khi phát lệnh mở cổng; Idempotency bằng Request ID\n'
                    '• NFR-PERF-01: Phản hồi cổng <= 2.0s tại giờ cao điểm ca làm việc\n'
                    '• NFR-REL-01: Fail-secure khi lỗi trạm/controller, tuyệt đối không mở cổng trái phép',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF283593)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
