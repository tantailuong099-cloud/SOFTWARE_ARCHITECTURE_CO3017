import '../../../core/config/api_endpoint.dart';

enum StationDirection {
  entry('ENTRY'),
  exit('EXIT');

  final String value;
  const StationDirection(this.value);

  static StationDirection parse(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () {
      throw const FormatException('Choose ENTRY or EXIT.');
    },
  );
}

enum StationStatus {
  active('ACTIVE'),
  disabled('DISABLED'),
  inactive('INACTIVE');

  final String value;
  const StationStatus(this.value);

  static StationStatus parse(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'ACTIVE') return StationStatus.active;
    if (normalized == 'DISABLED' || normalized == 'INACTIVE') {
      return StationStatus.disabled;
    }
    throw FormatException('Choose ACTIVE or DISABLED/INACTIVE (got $value).');
  }
}

const stationFactoryIds = ['BINH_DUONG', 'LONG_AN'];

final class StationConfiguration {
  final String stationId;
  final String factoryId;
  final String gateIdentifier;
  final StationDirection direction;
  final StationStatus status;
  final Uri? controllerEndpoint;

  const StationConfiguration({
    required this.stationId,
    required this.factoryId,
    required this.gateIdentifier,
    required this.direction,
    required this.status,
    this.controllerEndpoint,
  });

  static Uri? visibleControllerEndpoint(String? value) {
    if (value == null) return null;
    try {
      return parseHttpEndpoint(value);
    } on FormatException {
      return null;
    }
  }
}

final class StationDraftFields {
  final String gateIdentifier;
  final StationDirection direction;
  final Uri controllerEndpoint;

  const StationDraftFields._(
    this.gateIdentifier,
    this.direction,
    this.controllerEndpoint,
  );

  factory StationDraftFields.validate({
    required String gateIdentifier,
    required String direction,
    required String controllerEndpoint,
  }) {
    if (gateIdentifier.trim().isEmpty) {
      throw const FormatException('Enter a gate identifier.');
    }
    final Uri endpoint;
    try {
      endpoint = parseHttpEndpoint(controllerEndpoint);
    } on FormatException {
      throw const FormatException(
        'Enter a controller HTTP or HTTPS URL without credentials, query, or fragment.',
      );
    }
    return StationDraftFields._(
      gateIdentifier.trim(),
      StationDirection.parse(direction),
      endpoint,
    );
  }
}

final class StationRegistrationDraft {
  final String stationId;
  final String factoryId;
  final StationDraftFields fields;

  const StationRegistrationDraft._(this.stationId, this.factoryId, this.fields);

  factory StationRegistrationDraft.validate({
    required String stationId,
    required String factoryId,
    required StationDraftFields fields,
  }) {
    final id = stationId.trim();
    if (id.isEmpty) throw const FormatException('Enter a station ID.');
    if (!stationFactoryIds.contains(factoryId)) {
      throw const FormatException('Choose a supported factory.');
    }
    return StationRegistrationDraft._(id, factoryId, fields);
  }
}

final class StationUpdateDraft {
  final StationDraftFields fields;
  final StationStatus status;

  const StationUpdateDraft._(this.fields, this.status);

  factory StationUpdateDraft.validate({
    required StationDraftFields fields,
    required String status,
  }) => StationUpdateDraft._(fields, StationStatus.parse(status));
}
