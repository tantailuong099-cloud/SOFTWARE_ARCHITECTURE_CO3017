import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/core/config/api_config.dart';
import 'package:tmc_gate_app/core/config/api_endpoint.dart';
import 'package:tmc_gate_app/core/config/api_endpoint_settings.dart';
import 'package:tmc_gate_app/features/gate_station/domain/station_configuration.dart';
import 'package:tmc_gate_app/features/gate_station/domain/station_configuration_source.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/gate_station_provider.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/station_settings_controller.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/station_settings_screen.dart';

import 'support/memory_api_endpoint_store.dart';

final _default = ApiEndpoint.parse('http://localhost:3000/api');
final _alternate = ApiEndpoint.parse('https://replacement.example.org/api');

void main() {
  testWidgets(
    'shows local and remote details separately and keeps secrets out of the UI',
    (tester) async {
      await _open(tester);
      await tester.pumpAndSettle();
      expect(find.text('Local selection'), findsOneWidget);
      expect(find.text('Backend configuration'), findsOneWidget);
      expect(find.text('Gate identifier: Remote main gate'), findsOneWidget);
      expect(
        find.text('Gate identifier: Gate 01 - Main Entrance'),
        findsOneWidget,
      );
      expect(find.text('Status: DISABLED'), findsOneWidget);
      expect(find.textContaining('STATION_KEY'), findsNothing);
      expect(
        find.text('Turnstile controller endpoint: Unavailable'),
        findsNWidgets(2),
      );
      expect(
        find.text('Current API Base URL: ${_default.value}'),
        findsOneWidget,
      );
    },
  );

  testWidgets('rejects an invalid address and warns for remote HTTP', (
    tester,
  ) async {
    final fixture = await _open(tester);
    await tester.pumpAndSettle();
    await tester.enterText(_apiField(), 'not a URL');
    await tester.tap(find.text('Apply address'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter an HTTP or HTTPS URL'), findsOneWidget);
    expect(fixture.container.read(apiEndpointSettingsProvider), _default);
    expect(fixture.store.url, isNull);

    await tester.enterText(_apiField(), 'http://replacement.example.org/api');
    await tester.pump();
    expect(
      find.text('Warning: HTTP outside local development is unencrypted.'),
      findsOneWidget,
    );
  });

  testWidgets('warns about queued scans and allows cancel without applying', (
    tester,
  ) async {
    final fixture = await _open(tester);
    final notifier = fixture.container.read(
      gateStationNotifierProvider.notifier,
    );
    notifier.toggleOfflineSimulation();
    await notifier.submitScan('queued-fixture');
    final before = fixture.container.read(gateStationNotifierProvider);
    await tester.pumpAndSettle();
    await tester.enterText(_apiField(), _alternate.value);
    await tester.tap(find.text('Apply address'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('1 unsynchronized scans will stay in the queue'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(fixture.container.read(apiEndpointSettingsProvider), _default);
    expect(fixture.container.read(gateStationNotifierProvider), same(before));
    expect(fixture.store.url, isNull);
  });

  testWidgets(
    'applies the normalized address, separates reachability, and restores default',
    (tester) async {
      final fixture = await _open(
        tester,
        reader: (ref, id) async {
          if (ref.read(apiEndpointSettingsProvider) == _alternate) {
            throw StationConfigurationFailure.unavailable;
          }
          return _station(id);
        },
      );
      await tester.pumpAndSettle();
      await tester.enterText(_apiField(), '${_alternate.value}///');
      await tester.tap(find.text('Apply address'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change address'));
      await tester.pumpAndSettle();

      expect(fixture.store.url, _alternate.value);
      expect(
        find.text('Current API Base URL: ${_alternate.value}'),
        findsOneWidget,
      );
      expect(
        find.text('Could not retrieve station details from the backend.'),
        findsOneWidget,
      );
      expect(find.text('Backend returned the selected station.'), findsNothing);

      await tester.tap(find.text('Restore default'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change address'));
      await tester.pumpAndSettle();
      expect(fixture.store.url, isNull);
      expect(
        find.text('Current API Base URL: ${_default.value}'),
        findsOneWidget,
      );
      expect(
        find.text('Backend returned the selected station.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'validates an edit draft while the production server action stays unavailable',
    (tester) async {
      await _open(tester);
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Edit draft starts from the local station selection',
        ),
        findsOneWidget,
      );
      final draftGate = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Gate identifier'),
      );
      expect(draftGate.controller?.text, 'Gate 01 - Main Entrance');
      expect(find.text('Gate identifier: Remote main gate'), findsOneWidget);
      final validate = find.text('Validate draft');
      await tester.ensureVisible(validate);
      await tester.tap(validate);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Enter a controller HTTP or HTTPS URL'),
        findsOneWidget,
      );

      final field = find.widgetWithText(
        TextField,
        'Turnstile controller endpoint',
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, 'https://controller.example.org/unlock');
      await tester.ensureVisible(validate);
      await tester.tap(validate);
      await tester.pumpAndSettle();
      expect(
        find.text('Draft is valid. Server configuration is unchanged.'),
        findsOneWidget,
      );
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save to server'),
      );
      expect(save.onPressed, isNull);
    },
  );

  testWidgets(
    'an injected administrator adapter can deny a validated request',
    (tester) async {
      final administration = _DeniedAdministration();
      await _open(tester, administration: administration);
      await tester.pumpAndSettle();
      final field = find.widgetWithText(
        TextField,
        'Turnstile controller endpoint',
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, 'https://controller.example.org/unlock');
      final save = find.text('Save to server');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(administration.updated, ['BD-GATE-01']);
      expect(find.textContaining('The server rejected'), findsOneWidget);
      expect(find.text('Server accepted the configuration.'), findsNothing);
    },
  );

  testWidgets(
    'registration validates a distinct local draft with server action disabled',
    (tester) async {
      await _open(tester);
      await tester.pumpAndSettle();
      final register = find.text('Register new station');
      await tester.ensureVisible(register);
      await tester.tap(register);
      await tester.pumpAndSettle();

      for (final (label, value) in [
        ('Station ID', 'NEW-GATE-01'),
        ('Gate identifier', 'New entrance'),
        (
          'Turnstile controller endpoint',
          'https://controller.example.org/unlock',
        ),
      ]) {
        final field = find.widgetWithText(TextField, label);
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
      }
      final validate = find.text('Validate draft');
      await tester.ensureVisible(validate);
      await tester.tap(validate);
      await tester.pumpAndSettle();
      expect(
        find.text('Draft is valid. Server configuration is unchanged.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Register on server'),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'reports persistence failure without changing the applied address',
    (tester) async {
      final fixture = await _open(tester);
      fixture.store.rejectWrites = true;
      await tester.pumpAndSettle();
      await tester.enterText(_apiField(), _alternate.value);
      await tester.tap(find.text('Apply address'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change address'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not save the API address'),
        findsOneWidget,
      );
      expect(fixture.container.read(apiEndpointSettingsProvider), _default);
      expect(fixture.store.url, isNull);
    },
  );

  testWidgets(
    'small screens scroll without overflow and discard results after disposal',
    (tester) async {
      final response = Completer<StationConfiguration>();
      await _open(
        tester,
        size: const Size(320, 640),
        reader: (_, _) => response.future,
      );
      await tester.scrollUntilVisible(
        find.text('Architecture'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      response.complete(_station('BD-GATE-01'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

Finder _apiField() => find.widgetWithText(TextField, 'API Base URL');

Future<({ProviderContainer container, MemoryApiEndpointStore store})> _open(
  WidgetTester tester, {
  Size size = const Size(800, 1500),
  Future<StationConfiguration> Function(Ref ref, String stationId)? reader,
  StationAdministration? administration,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final store = MemoryApiEndpointStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        defaultApiEndpointProvider.overrideWithValue(_default),
        apiEndpointStoreProvider.overrideWithValue(store),
        stationConfigurationReaderProvider.overrideWith(
          (ref) =>
              (id) => reader?.call(ref, id) ?? Future.value(_station(id)),
        ),
        if (administration != null)
          stationAdministrationProvider.overrideWithValue(administration),
      ],
      child: const MaterialApp(home: StationSettingsScreen()),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(StationSettingsScreen)),
  );
  return (container: container, store: store);
}

StationConfiguration _station(String id) => StationConfiguration(
  stationId: id,
  factoryId: 'BINH_DUONG',
  gateIdentifier: 'Remote main gate',
  direction: StationDirection.entry,
  status: StationStatus.disabled,
);

class _DeniedAdministration implements StationAdministration {
  final updated = <String>[];

  @override
  Future<void> register(StationRegistrationDraft draft) async {
    throw StationConfigurationFailure.unauthorized;
  }

  @override
  Future<void> update(String stationId, StationUpdateDraft draft) async {
    updated.add(stationId);
    throw StationConfigurationFailure.unauthorized;
  }
}
