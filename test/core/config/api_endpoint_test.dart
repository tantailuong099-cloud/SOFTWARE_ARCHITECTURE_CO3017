import 'package:flutter_test/flutter_test.dart';
import 'package:tmc_gate_app/core/config/api_endpoint.dart';

void main() {
  for (final (input, expected) in [
    ('http://localhost:3000/api', 'http://localhost:3000/api'),
    ('http://10.0.2.2:3000/api', 'http://10.0.2.2:3000/api'),
    ('http://[::1]:3000/api', 'http://[::1]:3000/api'),
    (
      ' https://example.org:8443/prefix/api/// ',
      'https://example.org:8443/prefix/api',
    ),
    ('https://example.org/', 'https://example.org'),
    ('https://example.org/custom', 'https://example.org/custom'),
  ]) {
    test('normalizes $input to $expected', () {
      final endpoint = ApiEndpoint.parse(input);
      expect(endpoint.value, expected);
      expect(ApiEndpoint.parse(endpoint.value), endpoint);
    });
  }

  for (final input in [
    '',
    'ftp://example.org/api',
    'https:///api',
    'http://bad_host/api',
    'http://999.0.0.1/api',
    'http://localhost:nope/api',
    'http://localhost:65536/api',
    'http://localhost:0/api',
    'https://example.org/api/api/',
    'https://example.org/api/%61pi/',
    'https://user:pass@example.org/api',
    'https://example.org/api?token=x',
    'https://example.org/api#fragment',
    'https://example.org/api/../other',
  ]) {
    test('rejects invalid endpoint ${input.isEmpty ? '(empty)' : input}', () {
      expect(() => ApiEndpoint.parse(input), throwsFormatException);
    });
  }

  test('warns for non-local HTTP without rewriting the destination', () {
    final endpoint = ApiEndpoint.parse('http://example.org:8080/custom');
    expect(endpoint.usesInsecureRemoteHttp, isTrue);
    expect(endpoint.value, 'http://example.org:8080/custom');
    for (final local in [
      'http://localhost:3000/api',
      'http://127.0.0.1:3000/api',
      'http://10.0.2.2:3000/api',
      'http://[::1]:3000/api',
      'https://example.org/api',
    ]) {
      expect(
        ApiEndpoint.parse(local).usesInsecureRemoteHttp,
        isFalse,
        reason: local,
      );
    }
  });
}
