import 'package:dio/dio.dart';

import '../domain/station_configuration.dart';
import '../domain/station_configuration_source.dart';

final class DioStationConfigurationReader {
  final Dio _dio;

  const DioStationConfigurationReader(this._dio);

  Future<StationConfiguration> read(String stationId) async {
    try {
      final response = await _dio.get(
        '/gate-stations/${Uri.encodeComponent(stationId)}',
        options: Options(followRedirects: false),
      );
      final json = response.data;
      if (json is! Map<String, dynamic> || json['stationId'] != stationId) {
        throw const FormatException('Unexpected station response.');
      }
      String readText(String field) {
        final value = json[field];
        if (value is String && value.trim().isNotEmpty) return value;
        throw const FormatException('Missing station configuration field.');
      }

      final endpoint = json['controllerEndpoint'];
      if (endpoint != null && endpoint is! String) {
        throw const FormatException('Invalid station endpoint field.');
      }

      return StationConfiguration(
        stationId: stationId,
        factoryId: readText('factoryId'),
        gateIdentifier: readText('gateIdentifier'),
        direction: StationDirection.parse(readText('direction')),
        status: StationStatus.parse(readText('status')),
        controllerEndpoint: StationConfiguration.visibleControllerEndpoint(
          endpoint as String?,
        ),
      );
    } on DioException catch (error) {
      throw switch (error.response?.statusCode) {
        401 || 403 => StationConfigurationFailure.unauthorized,
        404 => StationConfigurationFailure.notFound,
        _ when error.error is FormatException =>
          StationConfigurationFailure.invalidResponse,
        _ => StationConfigurationFailure.unavailable,
      };
    } on FormatException {
      throw StationConfigurationFailure.invalidResponse;
    }
  }
}
