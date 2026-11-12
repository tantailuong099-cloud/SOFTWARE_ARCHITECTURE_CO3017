import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/access_scan_models.dart' show GateStation;
import '../../domain/station_configuration.dart';
import '../providers/station_settings_controller.dart';

class StationAdministrationPanel extends ConsumerStatefulWidget {
  final GateStation station;

  const StationAdministrationPanel({super.key, required this.station});

  @override
  ConsumerState<StationAdministrationPanel> createState() =>
      _StationAdministrationPanelState();
}

class _StationAdministrationPanelState
    extends ConsumerState<StationAdministrationPanel> {
  final _stationId = TextEditingController();
  final _gateIdentifier = TextEditingController();
  final _controllerEndpoint = TextEditingController();
  bool _registering = false;
  bool _submitting = false;
  late String _factory;
  late String _direction;
  late String _status;
  String? _message;

  @override
  void initState() {
    super.initState();
    _resetDraft();
  }

  @override
  void dispose() {
    _stationId.dispose();
    _gateIdentifier.dispose();
    _controllerEndpoint.dispose();
    super.dispose();
  }

  void _resetDraft() {
    final station = widget.station;
    _stationId.text = _registering ? '' : station.stationId;
    _gateIdentifier.text = _registering ? '' : station.gateIdentifier;
    _controllerEndpoint.text = _registering
        ? ''
        : StationConfiguration.visibleControllerEndpoint(
                station.controllerEndpoint,
              )?.toString() ??
              '';
    _factory = stationFactoryIds.contains(station.factoryId)
        ? station.factoryId
        : stationFactoryIds.first;
    _direction = station.direction == 'EXIT' ? 'EXIT' : 'ENTRY';
    _status = station.status == 'DISABLED' ? 'DISABLED' : 'ACTIVE';
    _message = null;
  }

  Future<void> _validate({bool submit = false}) async {
    final service = ref.read(stationAdministrationProvider);
    if (_submitting || (submit && service == null)) return;

    try {
      final fields = StationDraftFields.validate(
        gateIdentifier: _gateIdentifier.text,
        direction: _direction,
        controllerEndpoint: _controllerEndpoint.text,
      );
      final registration = _registering
          ? StationRegistrationDraft.validate(
              stationId: _stationId.text,
              factoryId: _factory,
              fields: fields,
            )
          : null;
      final update = _registering
          ? null
          : StationUpdateDraft.validate(fields: fields, status: _status);
      if (!submit) {
        setState(
          () => _message = 'Bản nháp thông số phần cứng hợp lệ! Cấu hình máy chủ chưa thay đổi.',
        );
        return;
      }

      setState(() => _submitting = true);
      try {
        if (registration != null) {
          await service!.register(registration);
        } else {
          await service!.update(widget.station.stationId, update!);
        }
        if (mounted) {
          setState(() => _message = 'Máy chủ đã chấp nhận và lưu cấu hình.');
        }
      } on Exception {
        if (mounted) {
          setState(
            () => _message =
                'Máy chủ từ chối cấu hình hoặc không thể kết nối tới trạm.',
          );
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    } on FormatException catch (error) {
      setState(() => _message = 'Lỗi nhập liệu: ${error.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(stationAdministrationProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (service == null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 20, color: Colors.blue.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chế độ kiểm thử thông số phần cứng (Local Turnstile Simulator). '
                    'Để quản lý và chỉnh sửa trực tiếp dữ liệu trạm trên máy chủ, bạn cũng có thể sử dụng tab Quản Lý Cổng.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.edit_note_rounded, size: 16),
              label: const Text('Chỉnh sửa trạm hiện tại'),
              selected: !_registering,
              onSelected: _submitting ? null : (_) => _changeMode(false),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text('Đăng ký trạm mới'),
              selected: _registering,
              onSelected: _submitting ? null : (_) => _changeMode(true),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_registering) ...[
          _input(_stationId, 'Mã trạm (Station ID, ví dụ: BD-GATE-05)', icon: Icons.badge_outlined),
          _choice(
            'Nhà máy (Factory)',
            _factory,
            stationFactoryIds,
            (value) => _factory = value,
            icon: Icons.factory_outlined,
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã trạm: ${widget.station.stationId}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nhà máy: ${widget.station.factoryId}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.station.isActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: widget.station.isActive ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
                  child: Text(
                    widget.station.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: widget.station.isActive ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        _input(_gateIdentifier, 'Tên định danh cổng (Gate Identifier)', icon: Icons.door_front_door_outlined),
        _choice(
          'Hướng di chuyển qua cổng (Direction)',
          _direction,
          StationDirection.values.map((item) => item.value),
          (value) => _direction = value,
          icon: Icons.swap_vert_rounded,
        ),
        _input(
          _controllerEndpoint,
          'Địa chỉ Turnstile Controller Endpoint (URL phần cứng)',
          url: true,
          icon: Icons.settings_ethernet_rounded,
        ),
        if (!_registering)
          _choice(
            'Trạng thái cổng (Station Status)',
            _status,
            StationStatus.values.map((item) => item.value),
            (value) => _status = value,
            icon: Icons.toggle_on_outlined,
          ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _message!.contains('Lỗi') ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _message!.contains('Lỗi') ? Colors.red.shade200 : Colors.green.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _message!.contains('Lỗi') ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: _message!.contains('Lỗi') ? Colors.red.shade700 : Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _message!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _message!.contains('Lỗi') ? Colors.red.shade900 : Colors.green.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.rule_folder_rounded, size: 18),
              onPressed: _submitting ? null : () => _validate(),
              label: const Text('Kiểm tra hợp lệ (Validate)'),
            ),
            FilledButton.icon(
              icon: Icon(_registering ? Icons.add_rounded : Icons.save_rounded, size: 18),
              onPressed: service == null || _submitting
                  ? null
                  : () => _validate(submit: true),
              label: Text(
                _registering ? 'Đăng ký lên máy chủ' : 'Lưu lên máy chủ',
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _changeMode(bool registering) {
    if (registering == _registering) return;
    setState(() {
      _registering = registering;
      _resetDraft();
    });
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    bool url = false,
    IconData? icon,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: controller,
      enabled: !_submitting,
      keyboardType: url ? TextInputType.url : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    ),
  );

  Widget _choice(
    String label,
    String value,
    Iterable<String> options,
    ValueChanged<String> onChanged, {
    IconData? icon,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DropdownButtonFormField<String>(
      key: ValueKey((label, _registering)),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: _submitting
          ? null
          : (value) {
              if (value != null) onChanged(value);
            },
    ),
  );
}
