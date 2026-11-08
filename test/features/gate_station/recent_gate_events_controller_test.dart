import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/core/network/dio_client.dart';
import 'package:tmc_gate_app/features/gate_station/domain/recent_gate_events_source.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/gate_station_provider.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/recent_gate_events_controller.dart';

import 'support/recent_events_fixture.dart';

void main() {
  for (final useFake in [false, true]) {
    final sourceName = useFake ? 'injected fake' : 'Dio repository';
    test('$sourceName distinguishes empty, unavailable, and ready', () async {
      final fake = ControlledRecentEventsSource();
      final dio = Dio();
      addTearDown(dio.close);
      var transportRequests = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final index = transportRequests++;
            if (index == 1) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                ),
              );
              return;
            }
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: index == 0 ? [] : [eventJson()],
              ),
            );
          },
        ),
      );
      final container = ProviderContainer.test(
        overrides: [
          dioProvider.overrideWithValue(dio),
          if (useFake)
            recentGateEventsSourceProvider.overrideWithValue(fake.fetch),
        ],
      );
      final subscription = container.listen(
        recentGateEventsProvider,
        (_, _) {},
      );
      expect(subscription.read().isLoading, isTrue);

      if (useFake) fake.complete(0, []);
      expect(await container.read(recentGateEventsProvider.future), isEmpty);
      expect(subscription.read().hasError, isFalse);

      expect(container.refresh(recentGateEventsProvider).isLoading, isTrue);
      final failure = expectLater(
        container.read(recentGateEventsProvider.future),
        throwsA(RecentEventsFailure.unavailable),
      );
      if (useFake) fake.fail(1, RecentEventsFailure.unavailable);
      await failure;
      expect(subscription.read().error, RecentEventsFailure.unavailable);

      expect(container.refresh(recentGateEventsProvider).isLoading, isTrue);
      if (useFake) fake.complete(2, [eventJson()]);
      final events = await container.read(recentGateEventsProvider.future);
      expect(events?.single.eventId, 'event-a');
      expect(transportRequests, useFake ? 0 : 3);
    });
  }

  test('A to B to A ignores both superseded station requests', () async {
    final fake = ControlledRecentEventsSource();
    final container = ProviderContainer.test(
      overrides: [recentGateEventsSourceProvider.overrideWithValue(fake.fetch)],
    );
    final subscription = container.listen(recentGateEventsProvider, (_, _) {});
    final stations = container.read(gateStationNotifierProvider.notifier);

    stations.switchStation('LA-GATE-01');
    expect(subscription.read().isLoading, isTrue);
    stations.switchStation('BD-GATE-01');
    expect(subscription.read().isLoading, isTrue);
    expect(fake.requests.map((request) => request.stationId), [
      'BD-GATE-01',
      'LA-GATE-01',
      'BD-GATE-01',
    ]);

    fake.complete(2, [eventJson(eventId: 'new-a')]);
    await container.read(recentGateEventsProvider.future);
    fake.complete(1, [eventJson(eventId: 'stale-b', stationId: 'LA-GATE-01')]);
    fake.complete(0, [eventJson(eventId: 'stale-a')]);
    await container.pump();

    expect(subscription.read().requireValue?.single.eventId, 'new-a');
  });

  test('overlapping refreshes keep only the latest request result', () async {
    final fake = ControlledRecentEventsSource();
    final container = ProviderContainer.test(
      overrides: [recentGateEventsSourceProvider.overrideWithValue(fake.fetch)],
    );
    final subscription = container.listen(recentGateEventsProvider, (_, _) {});
    expect(container.refresh(recentGateEventsProvider).isLoading, isTrue);
    expect(container.refresh(recentGateEventsProvider).isLoading, isTrue);

    fake.complete(2, [eventJson(eventId: 'latest')]);
    await container.read(recentGateEventsProvider.future);
    fake.fail(1, RecentEventsFailure.unavailable);
    fake.complete(0, [eventJson(eventId: 'oldest')]);
    await container.pump();

    expect(subscription.read().requireValue?.single.eventId, 'latest');
    expect(subscription.read().hasError, isFalse);
  });
}
