import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/core/config/api_endpoint.dart';
import 'package:tmc_gate_app/core/config/api_endpoint_settings.dart';
import 'package:tmc_gate_app/features/gate_station/data/dio_station_configuration_reader.dart';
import 'package:tmc_gate_app/features/gate_station/domain/station_configuration.dart';
import 'package:tmc_gate_app/features/gate_station/domain/station_configuration_source.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/gate_station_provider.dart';
import 'package:tmc_gate_app/features/gate_station/presentation/providers/station_settings_controller.dart';

import 'support/memory_api_endpoint_store.dart';

const _stationJson = {
  'stationId': 'BD-GATE-01',
  'factoryId': 'BINH_DUONG',
  'gateIdentifier': 'Main gate',
  'direction': 'ENTRY',
  'status': 'ACTIVE',
};

void main() {
  test(
    'reads authoritative station details and omits sensitive or missing endpoints',
    () async {
      for (final endpoint in [
        'http://controller.internal:8080/unlock',
        null,
        'https://user:password@controller.example.org/unlock',
        'https://controller.example.org/unlock?token=private-sample',
      ]) {
        RequestOptions? sent;
        final dio = Dio();
        addTearDown(dio.close);
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              sent = options;
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    ..._stationJson,
                    'stationApiKey': 'private-sample',
                    'controllerEndpoint': ?endpoint,
                  },
                ),
              );
            },
          ),
        );
        final station = await DioStationConfigurationReader(
          dio,
        ).read('BD-GATE-01');
        expect(sent?.path, '/gate-stations/BD-GATE-01');
        expect(sent?.method, 'GET');
        expect(sent?.followRedirects, isFalse);
        expect(station.gateIdentifier, 'Main gate');
        expect(station.direction, StationDirection.entry);
        expect(station.status, StationStatus.active);
        if (endpoint?.startsWith('http://') ?? false) {
          expect(station.controllerEndpoint, Uri.parse(endpoint!));
        } else {
          expect(station.controllerEndpoint, isNull);
        }
      }
    },
  );

  test(
    'station source preserves errors instead of returning fallback data',
    () async {
      for (final (status, data, expected) in [
        (401, null, StationConfigurationFailure.unauthorized),
        (403, null, StationConfigurationFailure.unauthorized),
        (404, null, StationConfigurationFailure.notFound),
        (503, null, StationConfigurationFailure.unavailable),
        (
          200,
          {..._stationJson, 'stationId': 'LA-GATE-01'},
          StationConfigurationFailure.invalidResponse,
        ),
        (
          200,
          {..._stationJson, 'direction': 'INVALID'},
          StationConfigurationFailure.invalidResponse,
        ),
      ]) {
        final dio = Dio();
        addTearDown(dio.close);
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final response = Response(
                requestOptions: options,
                statusCode: status,
                data: data,
              );
              if (status == 200) {
                handler.resolve(response);
              } else {
                handler.reject(
                  DioException.badResponse(
                    statusCode: status,
                    requestOptions: options,
                    response: response,
                  ),
                );
              }
            },
          ),
        );
        await expectLater(
          DioStationConfigurationReader(dio).read('BD-GATE-01'),
          throwsA(expected),
        );
      }
    },
  );

  test(
    'station and endpoint changes ignore stale connectivity results',
    () async {
      final requests =
          <({String stationId, Completer<StationConfiguration> result})>[];
      final container = ProviderContainer.test(
        overrides: [
          apiEndpointStoreProvider.overrideWithValue(MemoryApiEndpointStore()),
          applyApiEndpointProvider.overrideWithValue((_) {}),
          stationConfigurationReaderProvider.overrideWithValue((id) {
            final result = Completer<StationConfiguration>();
            requests.add((stationId: id, result: result));
            return result.future;
          }),
        ],
      );
      final subscription = container.listen(
        stationConfigurationProvider,
        (_, _) {},
      );
      container
          .read(gateStationNotifierProvider.notifier)
          .switchStation('LA-GATE-01');
      expect(subscription.read().isLoading, isTrue);
      await container
          .read(apiEndpointSettingsProvider.notifier)
          .save(ApiEndpoint.parse('https://replacement.example.org/api'));
      expect(subscription.read().isLoading, isTrue);
      expect(requests.map((request) => request.stationId), [
        'BD-GATE-01',
        'LA-GATE-01',
        'LA-GATE-01',
      ]);

      requests[2].result.complete(
        const StationConfiguration(
          stationId: 'LA-GATE-01',
          factoryId: 'LONG_AN',
          gateIdentifier: 'New server',
          direction: StationDirection.exit,
          status: StationStatus.disabled,
        ),
      );
      expect(
        (await container.read(
          stationConfigurationProvider.future,
        )).gateIdentifier,
        'New server',
      );
      requests[0].result.completeError(
        StationConfigurationFailure.unauthorized,
      );
      requests[1].result.completeError(StationConfigurationFailure.unavailable);
      await container.pump();

      expect(subscription.read().requireValue.stationId, 'LA-GATE-01');
      expect(subscription.read().requireValue.gateIdentifier, 'New server');
    },
  );

  test(
    'draft validates required fields, direction, status, factory and controller URL',
    () {
      StationDraftFields fields({
        String gate = '  Main gate  ',
        String direction = 'ENTRY',
        String endpoint = 'https://controller.example.org/unlock/',
      }) => StationDraftFields.validate(
        gateIdentifier: gate,
        direction: direction,
        controllerEndpoint: endpoint,
      );

      final valid = fields();
      expect(valid.gateIdentifier, 'Main gate');
      expect(valid.controllerEndpoint.path, '/unlock/');
      expect(() => fields(gate: ' '), throwsFormatException);
      expect(() => fields(direction: 'BOTH'), throwsFormatException);
      expect(
        () => fields(endpoint: 'ftp://controller.example.org'),
        throwsFormatException,
      );
      expect(
        () => fields(endpoint: 'https://controller.example.org/unlock?token=x'),
        throwsFormatException,
      );
      expect(
        () => StationRegistrationDraft.validate(
          stationId: '',
          factoryId: 'LONG_AN',
          fields: valid,
        ),
        throwsFormatException,
      );
      expect(
        () => StationRegistrationDraft.validate(
          stationId: 'NEW-STATION',
          factoryId: 'UNKNOWN',
          fields: valid,
        ),
        throwsFormatException,
      );
      expect(
        () => StationUpdateDraft.validate(fields: valid, status: 'UNKNOWN'),
        throwsFormatException,
      );
      expect(
        StationUpdateDraft.validate(fields: valid, status: 'DISABLED').status,
        StationStatus.disabled,
      );
    },
  );
}
