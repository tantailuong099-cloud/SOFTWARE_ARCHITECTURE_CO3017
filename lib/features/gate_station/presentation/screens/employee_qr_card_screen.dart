import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tmc_gate_app/features/auth/domain/user_role.dart';
import 'package:tmc_gate_app/features/auth/presentation/providers/auth_provider.dart';

import '../../domain/dynamic_qr_source.dart' show DynamicQRFailure;
import '../providers/dynamic_qr_controller.dart';
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
      'name': 'Nguyen Van An',
      'factory': 'Binh Duong (BINH_DUONG)',
      'department': 'Assembly Line 1',
      'role': 'Employee',
      'qr': 'TMC:QR:EMP-BD-001:V1:SEC_VALID_KEY_001',
      'qrStatus': 'ACTIVE',
      'statusDesc': 'Active QR credential',
      'statusColor': Colors.green,
    },
    {
      'id': 'EMP-BD-002',
      'name': 'Tran Thi Bich',
      'factory': 'Binh Duong (BINH_DUONG)',
      'department': 'Quality Assurance (QA)',
      'role': 'Supervisor',
      'qr': 'TMC:QR:EMP-BD-002:V1:SEC_SUSPENDED_KEY_002',
      'qrStatus': 'SUSPENDED',
      'statusDesc': 'Suspended QR credential',
      'statusColor': Colors.orange,
    },
    {
      'id': 'EMP-BD-003',
      'name': 'Le Hoang Nam',
      'factory': 'Binh Duong (BINH_DUONG)',
      'department': 'Packaging',
      'role': 'Employee',
      'qr': 'TMC:QR:EMP-BD-003:V1:SEC_EXPIRED_KEY_003',
      'qrStatus': 'EXPIRED',
      'statusDesc': 'Expired QR credential',
      'statusColor': Colors.red,
    },
    {
      'id': 'EMP-LA-001',
      'name': 'Pham Minh Duc',
      'factory': 'Long An (LONG_AN)',
      'department': 'Machining',
      'role': 'Employee',
      'qr': 'TMC:QR:EMP-LA-001:V1:SEC_VALID_KEY_LA01',
      'qrStatus': 'ACTIVE',
      'statusDesc': 'Active QR credential (Long An)',
      'statusColor': Colors.blue,
    },
  ];

  bool _useDynamicQR = false;

  DynamicQRController get _dynamicQRController =>
      ref.read(dynamicQRControllerProvider.notifier);

  Map<String, dynamic> _resolveCurrentEmployee(AuthState authState) {
    final code = authState.employeeCode;
    if (code != null && code.isNotEmpty) {
      final found = _demoEmployees.where((e) => e['id'] == code).firstOrNull;
      if (found != null) {
        return {
          ...found,
          if (authState.name?.isNotEmpty == true) 'name': authState.name!,
        };
      }
      return {
        'id': code,
        'name': authState.name ?? authState.email ?? code,
        'factory': 'Binh Duong (BINH_DUONG)',
        'department': 'Production Department',
        'role': authState.role ?? 'Employee',
        'qr': 'TMC:QR:$code:V1:SEC_VALID_KEY_DEFAULT',
        'qrStatus': 'ACTIVE',
        'statusDesc': 'Active QR credential',
        'statusColor': Colors.green,
      };
    }
    return _demoEmployees.first;
  }

  String? _getActivePayload(Map<String, dynamic> employee) {
    return _useDynamicQR
        ? _dynamicQRController.validPayload
        : employee['qr'] as String;
  }

  Future<void> _copyQR(String? payload) async {
    if (payload == null) return;
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR payload copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _submitDemoScan(String? payload) {
    if (payload == null) return;
    ref.read(gateStationNotifierProvider.notifier).submitScan(payload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR scan requested'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDynamicQR(DynamicQRState state, String? payload) {
    if (state is DynamicQRReady && payload != null) {
      final refreshSeconds = DynamicQRController.refreshInterval.inSeconds;
      return Column(
        children: [
          QRCodeWidget(data: payload, size: 190),
          const SizedBox(height: 12),
          Text(
            'QR expires in ${state.remainingSeconds}s',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Requests a new QR every $refreshSeconds seconds',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      );
    }

    final message = switch (state) {
      DynamicQRInitial() || DynamicQRLoading() => null,
      DynamicQRReady() || DynamicQRExpired() => 'The dynamic QR has expired.',
      DynamicQRError(:final failure) => switch (failure) {
        DynamicQRFailure.employeeIneligible =>
          'This employee is not eligible for a dynamic QR.',
        DynamicQRFailure.employeeNotFound =>
          'The server could not find this employee.',
        DynamicQRFailure.unavailable =>
          'Could not load a dynamic QR. Check your connection and try again.',
        DynamicQRFailure.invalidResponse =>
          'The server returned an invalid dynamic QR.',
      },
    };

    return SizedBox(
      height: 190,
      child: Center(
        child: message == null
            ? const CircularProgressIndicator(
                semanticsLabel: 'Loading dynamic QR',
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _dynamicQRController.retry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userRole = AppUserRole.fromString(authState.role);
    final currentEmployee = _resolveCurrentEmployee(authState);
    final employeeId = currentEmployee['id'] as String;
    final employeeName = currentEmployee['name'] as String;

    final dynamicQRState = ref.watch(dynamicQRControllerProvider);
    final payload = _getActivePayload(currentEmployee);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: userRole.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Thẻ Nhân Viên & Mã QR',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$employeeName • Mã NV: $employeeId (${userRole.code})',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất tài khoản',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Switch Static QR vs Dynamic Rotating QR
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 12),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Static QR (M1)'),
                    icon: Icon(Icons.qr_code_2_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Dynamic QR (M2)'),
                    icon: Icon(Icons.security_update_good_rounded, size: 16),
                  ),
                ],
                selected: {_useDynamicQR},
                onSelectionChanged: (selection) {
                  final useDynamicQR = selection.single;
                  if (useDynamicQR == _useDynamicQR) return;
                  setState(() => _useDynamicQR = useDynamicQR);
                  _dynamicQRController.selectEmployee(
                    useDynamicQR ? employeeId : null,
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

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
                  // Card Header Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: userRole.primaryColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'TMC MANUFACTURING JSC',
                          style: TextStyle(
                            color: Colors.white70,
                            letterSpacing: 1.5,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'EMPLOYEE ACCESS PASS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
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
                          backgroundColor: userRole.backgroundColor,
                          child: Text(
                            employeeName.trim().isNotEmpty
                                ? employeeName.trim().split(' ').last[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: userRole.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          employeeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$employeeId • ${currentEmployee['role']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currentEmployee['department']} • ${currentEmployee['factory']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 18),

                        // QR Code Display
                        if (_useDynamicQR)
                          _buildDynamicQR(dynamicQRState, payload)
                        else ...[
                          QRCodeWidget(
                            data: currentEmployee['qr'] as String,
                            size: 190,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (currentEmployee['statusColor'] as Color)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: currentEmployee['statusColor'] as Color,
                              ),
                            ),
                            child: Text(
                              currentEmployee['statusDesc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: currentEmployee['statusColor'] as Color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Static QR for the M1 demo. The payload stays fixed.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Action Buttons: Copy QR & Test scan
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Copy QR'),
                                onPressed: payload == null
                                    ? null
                                    : () => _copyQR(payload),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: 16,
                                ),
                                label: const Text('Test scan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: userRole.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: payload == null
                                    ? null
                                    : () => _submitDemoScan(payload),
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
