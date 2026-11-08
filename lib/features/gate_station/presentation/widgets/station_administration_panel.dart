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
          () => _message = 'Draft is valid. Server configuration is unchanged.',
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
          setState(() => _message = 'Server accepted the configuration.');
        }
      } on Exception {
        if (mounted) {
          setState(
            () => _message =
                'The server rejected the configuration or could not be reached.',
          );
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    } on FormatException catch (error) {
      setState(() => _message = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(stationAdministrationProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (service == null)
          const Text(
            'Draft validation only. Server changes require secure administrator access, validation, and audit support.',
          ),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Edit selected station'),
              selected: !_registering,
              onSelected: _submitting ? null : (_) => _changeMode(false),
            ),
            ChoiceChip(
              label: const Text('Register new station'),
              selected: _registering,
              onSelected: _submitting ? null : (_) => _changeMode(true),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_registering) ...[
          _input(_stationId, 'Station ID'),
          _choice(
            'Factory',
            _factory,
            stationFactoryIds,
            (value) => _factory = value,
          ),
        ] else ...[
          const Text(
            'Edit draft starts from the local station selection. '
            'The backend configuration above may differ.',
          ),
          Text('Station ID: ${widget.station.stationId}'),
          Text('Factory: ${widget.station.factoryId}'),
        ],
        _input(_gateIdentifier, 'Gate identifier'),
        _choice(
          'Direction',
          _direction,
          StationDirection.values.map((item) => item.value),
          (value) => _direction = value,
        ),
        _input(_controllerEndpoint, 'Turnstile controller endpoint', url: true),
        if (!_registering)
          _choice(
            'Station status',
            _status,
            StationStatus.values.map((item) => item.value),
            (value) => _status = value,
          ),
        if (_message != null) Text(_message!),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: _submitting ? null : () => _validate(),
              child: const Text('Validate draft'),
            ),
            FilledButton(
              onPressed: service == null || _submitting
                  ? null
                  : () => _validate(submit: true),
              child: Text(
                _registering ? 'Register on server' : 'Save to server',
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
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: TextField(
      controller: controller,
      enabled: !_submitting,
      keyboardType: url ? TextInputType.url : TextInputType.text,
      decoration: InputDecoration(labelText: label),
    ),
  );

  Widget _choice(
    String label,
    String value,
    Iterable<String> options,
    ValueChanged<String> onChanged,
  ) => DropdownButtonFormField<String>(
    key: ValueKey((label, _registering)),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final option in options)
        DropdownMenuItem(value: option, child: Text(option)),
    ],
    onChanged: _submitting
        ? null
        : (value) {
            if (value != null) onChanged(value);
          },
  );
}
