import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/config/api_endpoint.dart';
import '../../../../core/config/api_endpoint_settings.dart';
import '../../domain/station_configuration.dart';
import '../../domain/station_configuration_source.dart';
import '../providers/gate_station_provider.dart';
import '../providers/station_settings_controller.dart';
import '../widgets/station_administration_panel.dart';

class StationSettingsScreen extends ConsumerStatefulWidget {
  const StationSettingsScreen({super.key});

  @override
  ConsumerState<StationSettingsScreen> createState() =>
      _StationSettingsScreenState();
}

class _StationSettingsScreenState extends ConsumerState<StationSettingsScreen> {
  late final TextEditingController _url;
  String? _urlError;
  bool _applying = false;
  bool _warnHttp = false;

  @override
  void initState() {
    super.initState();
    final endpoint = ref.read(apiEndpointSettingsProvider);
    _url = TextEditingController(text: endpoint.value);
    _warnHttp = endpoint.usesInsecureRemoteHttp;
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _onUrlChanged(String value) {
    var warn = false;
    try {
      warn = ApiEndpoint.parse(value).usesInsecureRemoteHttp;
    } on FormatException {
      // Show validation errors when the user applies the URL.
    }
    setState(() {
      _urlError = null;
      _warnHttp = warn;
    });
  }

  Future<void> _apply({bool restoreDefault = false}) async {
    if (_applying) return;
    final ApiEndpoint next;
    try {
      next = restoreDefault
          ? ref.read(defaultApiEndpointProvider)
          : ApiEndpoint.parse(_url.text);
    } on FormatException catch (error) {
      setState(() => _urlError = error.message);
      return;
    }
    setState(() {
      _applying = true;
      _urlError = null;
    });
    try {
      if (next != ref.read(apiEndpointSettingsProvider)) {
        final pending = ref
            .read(gateStationNotifierProvider)
            .offlineQueue
            .length;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Change backend address?'),
            content: Text(
              'Use a trusted server. Future API requests go to the new address.'
              '${next.usesInsecureRemoteHttp ? '\n\nHTTP outside local development sends data without transport encryption.' : ''}'
              '${pending > 0 ? '\n\n$pending unsynchronized scans will stay in the queue.' : ''}'
              '\n\nA later manual sync sends queued scans to the configured server.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Change address'),
              ),
            ],
          ),
        );
        if (!mounted || confirmed != true) return;
      }

      final settings = ref.read(apiEndpointSettingsProvider.notifier);
      if (restoreDefault) {
        await settings.restoreDefault();
      } else {
        await settings.save(next);
      }
      if (!mounted) return;
      _url.text = next.value;
      setState(() => _warnHttp = next.usesInsecureRemoteHttp);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'API address applied. See the connection check for reachability.',
          ),
        ),
      );
    } on ApiEndpointUpdateFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _urlError = switch (failure) {
          ApiEndpointUpdateFailure.persistence =>
            'Could not save the API address. The current address is still in use.',
          ApiEndpointUpdateFailure.busy =>
            'An API address change is already in progress.',
        };
      });
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = ref.watch(
      gateStationNotifierProvider.select((state) => state.activeStation),
    );
    final endpoint = ref.watch(apiEndpointSettingsProvider);
    final remote = ref.watch(stationConfigurationProvider);
    final connection = remote.when(
      skipLoadingOnRefresh: false,
      loading: () => 'Checking station details on the applied backend…',
      data: (_) => 'Backend returned the selected station.',
      error: (error, _) => switch (error) {
        StationConfigurationFailure.unauthorized =>
          'Backend denied access to station details.',
        StationConfigurationFailure.notFound =>
          'The selected station was not found on this backend.',
        StationConfigurationFailure.invalidResponse =>
          'Backend returned invalid station details.',
        _ => 'Could not retrieve station details from the backend.',
      },
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Station Settings (UC-05)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Active Gate Station', [
            const Text('Local selection'),
            _details(
              stationId: local.stationId,
              factoryId: local.factoryId,
              gateIdentifier: local.gateIdentifier,
              direction: local.direction,
              status: local.status,
              controllerEndpoint:
                  StationConfiguration.visibleControllerEndpoint(
                    local.controllerEndpoint,
                  ),
            ),
            const Divider(),
            const Text('Backend configuration'),
            remote.when(
              skipLoadingOnRefresh: false,
              loading: () => const LinearProgressIndicator(),
              error: (_, _) =>
                  const Text('Remote configuration is unavailable.'),
              data: (station) => _details(
                stationId: station.stationId,
                factoryId: station.factoryId,
                gateIdentifier: station.gateIdentifier,
                direction: station.direction.value,
                status: station.status.value,
                controllerEndpoint: station.controllerEndpoint,
              ),
            ),
          ]),
          _section('Backend Connection', [
            Text('Current API Base URL: ${endpoint.value}'),
            const Text(
              'Use the API path required by your backend. This address is separate from the turnstile controller endpoint.',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _url,
              enabled: !_applying,
              keyboardType: TextInputType.url,
              autocorrect: false,
              onChanged: _onUrlChanged,
              decoration: InputDecoration(
                labelText: 'API Base URL',
                errorText: _urlError,
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
            ),
            if (endpoint.usesInsecureRemoteHttp || _warnHttp)
              const Text(
                'Warning: HTTP outside local development is unencrypted.',
              ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: _applying ? null : () => _apply(),
                  child: const Text('Apply address'),
                ),
                OutlinedButton(
                  onPressed: _applying
                      ? null
                      : () => _apply(restoreDefault: true),
                  child: const Text('Restore default'),
                ),
                TextButton(
                  onPressed: remote.isLoading || _applying
                      ? null
                      : () => ref.invalidate(stationConfigurationProvider),
                  child: const Text('Check applied connection'),
                ),
              ],
            ),
            Text(connection),
          ]),
          _section('Administrator Gate Configuration', [
            StationAdministrationPanel(
              key: ValueKey(local.stationId),
              station: local,
            ),
          ]),
          _section('Architecture', const [
            Text(
              'ADR-001 defines separate modules for QR management, gate stations, and attendance events.',
            ),
            Text(
              'ADR-003 defines durable event recording and idempotent access requests as backend requirements.',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );

  Widget _details({
    required String stationId,
    required String factoryId,
    required String gateIdentifier,
    required String direction,
    required String status,
    required Uri? controllerEndpoint,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Station ID: $stationId'),
      Text('Factory: $factoryId'),
      Text('Gate identifier: $gateIdentifier'),
      Text('Direction: $direction'),
      Text('Status: $status'),
      Text(
        'Turnstile controller endpoint: ${controllerEndpoint ?? 'Unavailable'}',
      ),
    ],
  );
}
