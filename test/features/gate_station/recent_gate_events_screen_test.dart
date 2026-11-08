import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/features/gate_station/data/gate_station_repository.dart';
import 'package:tmc_gate_app/features/gate_station/data/models/access_scan_models.dart';
import 'package:tmc_gate_app/features/gate_station/domain/recent_gate_events_source.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/gate_station_provider.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/recent_gate_events_controller.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/screens/recent_gate_events_screen.dart';

import 'support/recent_events_fixture.dart';

void main() {
  testWidgets(
    'renders server records and distinguishes access from turnstile outcomes',
    (tester) async {
      final source = await _openScreen(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        _container(tester).read(gateStationNotifierProvider).scanHistory,
        isEmpty,
      );
      source.complete(0, [
        eventJson(outcome: 'CONTROLLER_FAILED'),
        eventJson(eventId: 'event-unknown', outcome: 'CONTROLLER_UNKNOWN'),
        eventJson(eventId: 'event-pending', outcome: 'CONTROLLER_PENDING'),
        {
          ...eventJson(
            eventId: 'event-denied',
            decision: 'DENIED',
            outcome: 'NOT_APPLICABLE',
          ),
          'denialReason': 'CREDENTIAL_SUSPENDED',
          'employeeName': null,
        },
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Access decision: APPROVED'), findsNWidgets(3));
      expect(find.text('Controller outcome: Failed'), findsOneWidget);
      expect(find.text('Controller outcome: Unknown'), findsOneWidget);
      expect(find.text('Controller outcome: Pending'), findsOneWidget);
      expect(find.text('Controller outcome: Confirmed'), findsNothing);
      expect(find.text('Access decision: DENIED'), findsOneWidget);
      expect(find.text('Denial reason: CREDENTIAL_SUSPENDED'), findsOneWidget);
      expect(find.text('Employee unavailable'), findsOneWidget);
      expect(find.text('Recorded: 2026-11-08T01:23:45.678Z'), findsNWidgets(4));
    },
  );

  testWidgets(
    'keeps only server records even when local history contains the same event',
    (tester) async {
      final source = await _openScreen(tester, withLocalHistory: true);
      source.complete(0, [eventJson()]);
      await tester.pumpAndSettle();

      expect(find.text('Event ID: event-a'), findsOneWidget);
      expect(find.text('Local scan only'), findsNothing);
      expect(find.text('999ms'), findsNothing);
      expect(find.text('Controller outcome: Confirmed'), findsOneWidget);
    },
  );

  testWidgets(
    'clears old station events while the mounted screen loads the new station',
    (tester) async {
      final source = await _openScreen(tester);
      source.complete(0, [eventJson()]);
      await tester.pumpAndSettle();
      expect(find.text('Event ID: event-a'), findsOneWidget);

      _container(
        tester,
      ).read(gateStationNotifierProvider.notifier).switchStation('LA-GATE-01');
      await tester.pump();
      expect(source.requests[1].stationId, 'LA-GATE-01');
      expect(find.text('Event ID: event-a'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      source.complete(1, [
        eventJson(eventId: 'event-b', stationId: 'LA-GATE-01'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Event ID: event-b'), findsOneWidget);
      expect(find.text('Event ID: event-a'), findsNothing);
    },
  );

  testWidgets(
    'distinguishes empty from failure and supports refresh and retry',
    (tester) async {
      final source = await _openScreen(tester);
      source.complete(0, []);
      await tester.pumpAndSettle();
      final empty = find.text('No recent events recorded for this station.');
      expect(empty, findsOneWidget);

      await tester.tap(find.byTooltip('Refresh events'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      source.fail(1, RecentEventsFailure.unavailable);
      await tester.pumpAndSettle();
      expect(empty, findsNothing);
      expect(
        find.textContaining('Could not load recent events'),
        findsOneWidget,
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();
      source.complete(2, [eventJson(eventId: 'recovered')]);
      await tester.pumpAndSettle();
      expect(find.text('Event ID: recovered'), findsOneWidget);

      await tester.tap(find.byTooltip('Refresh events'));
      await tester.pump();
      expect(find.text('Event ID: recovered'), findsNothing);
      source.fail(3, RecentEventsFailure.unauthorized);
      await tester.pumpAndSettle();
      expect(find.textContaining('station permissions'), findsOneWidget);
      expect(find.text('Event ID: recovered'), findsNothing);
    },
  );

  testWidgets('ignores request completion after screen disposal', (
    tester,
  ) async {
    final source = await _openScreen(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    source.complete(0, [eventJson()]);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Future<ControlledRecentEventsSource> _openScreen(
  WidgetTester tester, {
  bool withLocalHistory = false,
}) async {
  tester.view.physicalSize = const Size(800, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final source = ControlledRecentEventsSource();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recentGateEventsSourceProvider.overrideWithValue(source.fetch),
        if (withLocalHistory)
          gateStationNotifierProvider.overrideWith(
            (ref) =>
                _StationWithHistory(ref.read(gateStationRepositoryProvider)),
          ),
      ],
      child: const MaterialApp(home: RecentGateEventsScreen()),
    ),
  );
  return source;
}

ProviderContainer _container(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(RecentGateEventsScreen)),
);

class _StationWithHistory extends GateStationNotifier {
  _StationWithHistory(super.repository) {
    state = state.copyWith(
      scanHistory: [
        AccessScanResponse(
          requestId: 'request-event-a',
          eventId: 'event-a',
          accessDecision: AccessDecision.approved,
          controllerOutcome: 'CONTROLLER_CONFIRMED',
          employeeName: 'Local scan only',
          serverTimestamp: DateTime.utc(2026, 11, 8),
          processingLatencyMs: 999,
        ),
      ],
    );
  }
}
