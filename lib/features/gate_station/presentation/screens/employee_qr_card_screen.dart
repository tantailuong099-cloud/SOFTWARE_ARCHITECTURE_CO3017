import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  late Map<String, dynamic> _selectedEmployee = _demoEmployees.first;
  bool _useDynamicQR = false;

  String get _employeeId => _selectedEmployee['id'] as String;

  DynamicQRController get _dynamicQRController =>
      ref.read(dynamicQRControllerProvider.notifier);

  String? get _activePayload => _useDynamicQR
      ? _dynamicQRController.validPayload
      : _selectedEmployee['qr'] as String;

  Future<void> _copyQR() async {
    final payload = _activePayload;
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

  void _submitDemoScan() {
    final payload = _activePayload;
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
            ),
          ),
          Text('Requests a new QR every $refreshSeconds seconds'),
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
                  Text(message, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _dynamicQRController.retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicQRState = ref.watch(dynamicQRControllerProvider);
    final payload = _activePayload;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(title: const Text('Employee QR Card (UC-01)')),
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
                        '${emp["id"]} - ${emp["name"]} (Static QR: ${emp["qrStatus"]})',
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
                    });
                    if (_useDynamicQR) {
                      _dynamicQRController.selectEmployee(newId);
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
                    useDynamicQR ? _employeeId : null,
                  );
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
                          _buildDynamicQR(dynamicQRState, payload)
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
                            'Static QR for the M1 demo. The payload stays fixed.',
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
                                label: const Text('Copy QR'),
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
                                label: const Text('Test scan'),
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
