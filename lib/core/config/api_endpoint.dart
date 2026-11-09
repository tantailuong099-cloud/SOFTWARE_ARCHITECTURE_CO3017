final class ApiEndpoint {
  final Uri uri;

  const ApiEndpoint._(this.uri);

  factory ApiEndpoint.parse(String input) {
    final uri = parseHttpEndpoint(input);
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
    var previousWasApi = false;
    for (final segment in segments) {
      final isApi = segment.toLowerCase() == 'api';
      if (isApi && previousWasApi) {
        throw const FormatException('Use a single /api path segment.');
      }
      previousWasApi = isApi;
    }
    return ApiEndpoint._(
      Uri.parse(uri.toString().replaceFirst(RegExp(r'/+$'), '')),
    );
  }

  String get value => uri.toString();

  bool get usesInsecureRemoteHttp {
    final host = uri.host.toLowerCase();
    final isLocal =
        host == 'localhost' ||
        host.endsWith('.localhost') ||
        host == '::1' ||
        host == '10.0.2.2' ||
        host.startsWith('127.') && _isIpv4(host);
    return uri.scheme == 'http' && !isLocal;
  }

  @override
  bool operator ==(Object other) => other is ApiEndpoint && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;
}

final _httpUrl = RegExp(r'^https?://([^/?#]+)([^?#]*)$', caseSensitive: false);
final _hostAndPort = RegExp(
  r'^(?:\[[^\]]+\]|[a-z0-9.-]+)(?::([0-9]+))?$',
  caseSensitive: false,
);
final _hostLabel = RegExp(
  r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$',
  caseSensitive: false,
);

/// Validates a non-secret HTTP URL without changing its path.
Uri parseHttpEndpoint(String input) {
  final value = input.trim();
  final match = _httpUrl.firstMatch(value);
  if (match == null ||
      RegExp(r'[\s\\\x00-\x1f\x7f]|%(?![0-9a-fA-F]{2})').hasMatch(value)) {
    throw const FormatException(
      'Enter an HTTP or HTTPS URL without a query or fragment.',
    );
  }
  final authority = match[1]!;
  if (authority.contains('@')) {
    throw const FormatException('Remove credentials from the URL.');
  }
  final hostAndPort = _hostAndPort.firstMatch(authority);
  final uri = Uri.tryParse(value);
  if (uri == null || hostAndPort == null || !_isValidHost(uri.host)) {
    throw const FormatException('Enter a valid hostname and port.');
  }
  final port = hostAndPort[1];
  if (port != null && !(uri.port >= 1 && uri.port <= 65535)) {
    throw const FormatException('Use a port between 1 and 65535.');
  }
  for (final segment in match[2]!.split('/')) {
    final decoded = Uri.decodeComponent(segment);
    if (decoded == '.' || decoded == '..') {
      throw const FormatException('Use a URL path without dot segments.');
    }
  }
  return uri;
}

bool _isValidHost(String host) {
  if (host.isEmpty || host.length > 253) return false;
  if (host.contains(':')) return true; // Uri validates IPv6 literals.
  final name = host.endsWith('.') ? host.substring(0, host.length - 1) : host;
  if (RegExp(r'^[0-9.]+$').hasMatch(name)) return _isIpv4(name);
  return name.split('.').every(_hostLabel.hasMatch);
}

bool _isIpv4(String host) {
  final parts = host.split('.');
  return parts.length == 4 &&
      parts.every((part) {
        final value = int.tryParse(part);
        return value != null &&
            value >= 0 &&
            value <= 255 &&
            value.toString() == part;
      });
}
