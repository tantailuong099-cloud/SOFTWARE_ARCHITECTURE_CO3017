import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/gate_station_repository.dart';
import '../../data/models/dynamic_qr_model.dart';
import '../providers/gate_station_provider.dart';
import '../widgets/qr_code_widget.dart';

class EmployeeQRCardScreen extends ConsumerStatefulWidget {
  const EmployeeQRCardScreen({super.key, this.now = DateTime.now});

  final DateTime Function() now;

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
      'qrStatus': 'ACTIVE',
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
      'qrStatus': 'SUSPENDED',
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
      'qrStatus': 'EXPIRED',
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
      'qrStatus': 'ACTIVE',
      'statusDesc': 'Mã QR Hợp lệ (Tại Long An)',
      'statusColor': Colors.blue,
    },
  ];

  static const _refreshInterval = Duration(seconds: 30);

  late Map<String, dynamic> _selectedEmployee;
  bool _useDynamicQR = false;
  bool _isLoading = false;
  DynamicQR? _credential;
  String? _loadError;
  int _requestGeneration = 0;
  Timer? _refreshTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _selectedEmployee = _demoEmployees.first;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _employeeId => _selectedEmployee['id'] as String;

  Duration get _remainingLifetime =>
      _credential?.expiresAt.difference(widget.now()) ?? Duration.zero;

  String? get _activePayload {
    if (!_useDynamicQR) return _selectedEmployee['qr'] as String;
    return _remainingLifetime > Duration.zero ? _credential?.qrPayload : null;
  }

  void _resetDynamicQR() {
    _requestGeneration++;
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _credential = null;
    _isLoading = false;
    _loadError = null;
  }

  Future<void> _loadDynamicQR() async {
    if (!_useDynamicQR || _isLoading) return;

    setState(() {
      _resetDynamicQR();
      _isLoading = true;
    });
    final generation = _requestGeneration;
    final employeeId = _employeeId;

    try {
      final credential = await ref
          .read(gateStationRepositoryProvider)
          .fetchDynamicQR(employeeId);
      if (!mounted || generation != _requestGeneration) return;

      setState(() {
        _credential = credential;
        _isLoading = false;
      });
      if (_remainingLifetime > Duration.zero) {
        _scheduleCountdown();
        _refreshTimer = Timer(_refreshInterval, _loadDynamicQR);
      }
    } on DioException catch (error) {
      final message = switch (error.response?.statusCode) {
        400 || 403 => 'Nhân viên này không được cấp mã QR động.',
        404 => 'Không tìm thấy nhân viên trên máy chủ.',
        _ => 'Không tải được mã QR động. Hãy kiểm tra kết nối và thử lại.',
      };
      _showLoadError(generation, message);
    } on FormatException {
      _showLoadError(generation, 'Máy chủ trả về mã QR động không hợp lệ.');
    }
  }

  void _showLoadError(int generation, String message) {
    if (!mounted || generation != _requestGeneration) return;
    setState(() {
      _isLoading = false;
      _loadError = message;
    });
  }

  void _scheduleCountdown() {
    final remaining = _remainingLifetime;
    if (remaining <= Duration.zero) return;

    // Rebuild at the next displayed second, including the expiry instant.
    final wholeSeconds =
        (remaining.inMicroseconds - 1) ~/ Duration.microsecondsPerSecond;
    _countdownTimer = Timer(remaining - Duration(seconds: wholeSeconds), () {
      setState(() {});
      _scheduleCountdown();
    });
  }

  Future<void> _copyQR() async {
    final payload = _activePayload;
    if (payload == null) return;
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép mã QR vào bộ nhớ tạm'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _submitDemoScan() {
    final payload = _activePayload;
    if (payload == null) return;
    ref.read(gateStationNotifierProvider.notifier).submitScan(payload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã yêu cầu quét mã QR'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDynamicQR(String? payload) {
    if (payload != null) {
      final seconds =
          (_remainingLifetime.inMicroseconds / Duration.microsecondsPerSecond)
              .ceil();
      return Column(
        children: [
          QRCodeWidget(data: payload, size: 190),
          const SizedBox(height: 12),
          Text(
            'Mã QR hết hạn sau: ${seconds}s',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text('Tự động yêu cầu mã mới mỗi 30 giây'),
        ],
      );
    }

    return SizedBox(
      height: 190,
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator(
                semanticsLabel: 'Đang tải mã QR động',
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _loadError ?? 'Mã QR động đã hết hạn.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _loadDynamicQR,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = _activePayload;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(title: const Text('Thẻ định danh & QR nhân viên (UC-01)')),
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
                  value: _employeeId,
                  items: _demoEmployees.map((emp) {
                    return DropdownMenuItem<String>(
                      value: emp['id'] as String,
                      child: Text(
                        '${emp["id"]} - ${emp["name"]} (QR tĩnh: ${emp["qrStatus"]})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                  onChanged: (newId) {
                    if (newId == null || newId == _employeeId) return;
                    setState(() {
                      _selectedEmployee = _demoEmployees.firstWhere(
                        (employee) => employee['id'] == newId,
                      );
                      _resetDynamicQR();
                    });
                    if (_useDynamicQR) _loadDynamicQR();
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
                    label: Text('Mã QR Động (M2)'),
                    icon: Icon(Icons.security_update_good_rounded, size: 16),
                  ),
                ],
                selected: {_useDynamicQR},
                onSelectionChanged: (selection) {
                  final useDynamicQR = selection.single;
                  if (useDynamicQR == _useDynamicQR) return;
                  setState(() {
                    _useDynamicQR = useDynamicQR;
                    _resetDynamicQR();
                  });
                  if (_useDynamicQR) _loadDynamicQR();
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
                    color: Colors.black.withValues(alpha: 0.08),
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
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedEmployee['department']} • ${_selectedEmployee['factory']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        if (_useDynamicQR)
                          _buildDynamicQR(payload)
                        else ...[
                          QRCodeWidget(
                            data: _selectedEmployee['qr'] as String,
                            size: 190,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (_selectedEmployee['statusColor'] as Color)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    _selectedEmployee['statusColor'] as Color,
                              ),
                            ),
                            child: Text(
                              _selectedEmployee['statusDesc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color:
                                    _selectedEmployee['statusColor'] as Color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Mã tĩnh dùng cho demo M1, không tự làm mới.',
                            textAlign: TextAlign.center,
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
                                onPressed: payload == null ? null : _copyQR,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.qr_code_scanner,
                                  size: 16,
                                ),
                                label: const Text('Quét thử ngay'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: payload == null
                                    ? null
                                    : _submitDemoScan,
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
