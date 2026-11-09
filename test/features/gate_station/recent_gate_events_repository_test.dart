import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/features/gate_station/data/gate_station_repository.dart';
import 'package:tmc_gate_app/features/gate_station/domain/recent_gate_events_source.dart';

import 'support/recent_events_fixture.dart';

void main() {
  test(
    'retrieves typed events in server order from the selected station',
    () async {
      RequestOptions? request;
      final repository = _repository((options, handler) {
        request = options;
        handler.resolve(
          Response(
            requestOptions: options,
            data: [
              eventJson(eventId: 'new'),
              eventJson(eventId: 'old'),
            ],
            statusCode: 200,
          ),
        );
      });

      final events = await repository.fetchRecentEvents('BD-GATE-01');

      expect(request?.method, 'GET');
      expect(request?.path, '/access/recent-events/BD-GATE-01');
      expect(events.map((event) => event.eventId), ['new', 'old']);
    },
  );

  test(
    'rejects malformed responses and any record from another station',
    () async {
      for (final data in [
        {'events': []},
        ['invalid row'],
        [eventJson(), eventJson(stationId: 'LA-GATE-01')],
        [
          {...eventJson(), 'serverTimestamp': 'broken'},
        ],
      ]) {
        final repository = _repository((options, handler) {
          handler.resolve(Response(requestOptions: options, data: data));
        });

        await expectLater(
          repository.fetchRecentEvents('BD-GATE-01'),
          throwsA(RecentEventsFailure.invalidResponse),
        );
      }
    },
  );

  test(
    'maps authorization and transport failures separately from empty results',
    () async {
      for (final (status, error, expected) in [
        (401, null, RecentEventsFailure.unauthorized),
        (403, null, RecentEventsFailure.unauthorized),
        (503, null, RecentEventsFailure.unavailable),
        (null, null, RecentEventsFailure.unavailable),
        (null, const FormatException(), RecentEventsFailure.invalidResponse),
      ]) {
        final repository = _repository((options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: error,
              response: status == null
                  ? null
                  : Response(requestOptions: options, statusCode: status),
            ),
          );
        });

        await expectLater(
          repository.fetchRecentEvents('BD-GATE-01'),
          throwsA(expected),
        );
      }
    },
  );
}

GateStationRepository _repository(
  void Function(RequestOptions, RequestInterceptorHandler) onRequest,
) {
  final dio = Dio();
  addTearDown(dio.close);
  dio.interceptors.add(InterceptorsWrapper(onRequest: onRequest));
  return GateStationRepository(dio);
}
