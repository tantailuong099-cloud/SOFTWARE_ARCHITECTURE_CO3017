import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/gate_station_repository.dart';
import '../providers/gate_station_provider.dart';
import '../widgets/qr_code_widget.dart';

class EmployeeQRCardScreen extends ConsumerStatefulWidget {
  const EmployeeQRCardScreen({super.key});

  @override
  ConsumerState<EmployeeQRCardScreen> createState() =>
      _EmployeeQRCardScreenState();
}

class _EmployeeQRCardScreenState extends ConsumerState<EmployeeQRCardScreen> {
  final List<Map<String, dynamic>> _demoEmployees = [
    {
      'id': 'EMP-BD-001',
      'name': 'Nguyễn Văn An',
      'factory': 'Bình Dương (BINH_DUONG)',
      'department': 'Dây chuyền lắp ráp 1',
      'role': 'Nhân viên',
      'qr': 'TMC:QR:EMP-BD-001:V1:SEC_VALID_KEY_001',
      'status': 'ACTIVE',
      'statusDesc': 'Mã QR Hợp lệ (Active)',
      'statusColor': Colors.green,
    },
    {
      'id': 'EMP-BD-002',
      'name': 'Trần Thị Bích',
      'factory': 'Bình Dương (BINH_DUONG)',
      'department': 'Quản lý chất lượng (QA)',
      'role': 'Giám sát viên (Supervisor)',
      'qr': 'TMC:QR:EMP-BD-002:V1:SEC_SUSPENDED_KEY_002',
      'status': 'SUSPENDED',
      'statusDesc': 'Mã QR Đang tạm ngưng (Suspended)',
      'statusColor': Colors.orange,
    },
    {
      'id': 'EMP-BD-003',
      'name': 'Lê Hoàng Nam',
      'factory': 'Bình Dương (BINH_DUONG)',
      'department': 'Đóng gói bao bì',
      'role': 'Nhân viên',
      'qr': 'TMC:QR:EMP-BD-003:V1:SEC_EXPIRED_KEY_003',
      'status': 'EXPIRED',
      'statusDesc': 'Mã QR Đã hết hạn (Expired)',
      'statusColor': Colors.red,
    },
    {
      'id': 'EMP-LA-001',
      'name': 'Phạm Minh Đức',
      'factory': 'Long An (LONG_AN)',
      'department': 'Gia công cơ khí',
      'role': 'Nhân viên',
      'qr': 'TMC:QR:EMP-LA-001:V1:SEC_VALID_KEY_LA01',
      'status': 'ACTIVE',
      'statusDesc': 'Mã QR Hợp lệ (Tại Long An)',
      'statusColor': Colors.blue,
    },
  ];

  late Map<String, dynamic> _selectedEmployee;
  bool _useDynamicQR = false;
  String? _dynamicQRPayload;
  int _countdown = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _selectedEmployee = _demoEmployees[0];
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startDynamicTimer() {
    _countdownTimer?.cancel();
    _refreshDynamicQR();
    _countdown = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _countdown = 30;
          _refreshDynamicQR();
        }
      });
    });
  }

  void _stopDynamicTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _refreshDynamicQR() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final empId = _selectedEmployee['id'] as String;
    // Generate rotating payload format: TMC:DYN:<empId>:<timestamp>:<nonce>:<sig>
    final nonce = (now % 10000).toString().padLeft(4, '0');
    // Using demo signature matching backend algorithm
    final sig = 'DEMO_SIG_$nonce';
    setState(() {
      _dynamicQRPayload = 'TMC:DYN:$empId:$now:$nonce:$sig';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Thẻ định danh & QR nhân viên (UC-01)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dropdown selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedEmployee['id'] as String,
                  items: _demoEmployees.map((emp) {
                    return DropdownMenuItem<String>(
                      value: emp['id'] as String,
                      child: Text(
                        '${emp["id"]} - ${emp["name"]} (${emp["status"]})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                  onChanged: (newId) {
                    if (newId != null) {
                      setState(() {
                        _selectedEmployee = _demoEmployees
                            .firstWhere((e) => e['id'] == newId);
                      });
                    }
                  },
                ),
              ),
            ),

            // M2 Enhancement: Static vs Dynamic Rotating QR Toggle (ADR-007)
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Mã QR Tĩnh (M1)'),
                    icon: Icon(Icons.qr_code_2_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Mã QR Động 30s (M2)'),
                    icon: Icon(Icons.security_update_good_rounded, size: 16),
                  ),
                ],
                selected: {_useDynamicQR},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _useDynamicQR = newSelection.first;
                    if (_useDynamicQR) {
                      _startDynamicTimer();
                    } else {
                      _stopDynamicTimer();
                    }
                  });
                },
              ),
            ),

            const SizedBox(height: 12),

            // Employee Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TMC MANUFACTURING JSC',
                          style: TextStyle(
                            color: Colors.white70,
                            letterSpacing: 1.5,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'EMPLOYEE ACCESS PASS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Avatar placeholder & Name
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            (_selectedEmployee['name'] as String)
                                .split(' ')
                                .last[0],
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedEmployee['name'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedEmployee['id']} • ${_selectedEmployee['role']}',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedEmployee['department']} • ${_selectedEmployee['factory']}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.blueGrey.shade700),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // QR Code Graphic (Dynamic rotating in M2 vs Static in M1)
                        QRCodeWidget(
                          data: _useDynamicQR
                              ? (_dynamicQRPayload ?? _selectedEmployee['qr'] as String)
                              : _selectedEmployee['qr'] as String,
                          size: 190,
                        ),

                        const SizedBox(height: 12),

                        // Credential Status Badge
                        if (_useDynamicQR) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade400),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    value: _countdown / 30,
                                    strokeWidth: 2.5,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Mã QR Động xoay mã sau: ${_countdown}s',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '🛡️ Chống chụp lén & chống điểm danh hộ (ADR-007)',
                            style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (_selectedEmployee['statusColor'] as Color)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedEmployee['statusColor'] as Color,
                              ),
                            ),
                            child: Text(
                              _selectedEmployee['statusDesc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedEmployee['statusColor'] as Color,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Sao chép mã'),
                                onPressed: () {
                                  final activeQR = _useDynamicQR
                                      ? (_dynamicQRPayload ?? _selectedEmployee['qr'] as String)
                                      : _selectedEmployee['qr'] as String;
                                  Clipboard.setData(
                                    ClipboardData(text: activeQR),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_useDynamicQR
                                          ? 'Đã sao chép Mã QR Động (Có hiệu lực 60s)'
                                          : 'Đã sao chép mã QR vào bộ nhớ tạm'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.qr_code_scanner, size: 16),
                                label: const Text('Quét thử ngay'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  final activeQR = _useDynamicQR
                                      ? (_dynamicQRPayload ?? _selectedEmployee['qr'] as String)
                                      : _selectedEmployee['qr'] as String;
                                  ref
                                      .read(gateStationNotifierProvider.notifier)
                                      .submitScan(activeQR);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Đã gửi lệnh quét cho ${_selectedEmployee["name"]}',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
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
    );
  }
}
