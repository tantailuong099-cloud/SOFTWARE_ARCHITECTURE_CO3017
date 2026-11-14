import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_endpoint.dart';

const accessTokenStorageKey = 'access_token';

Future<({String token, ApiEndpoint endpoint})?> readScopedAccessToken(
  FlutterSecureStorage storage,
) async {
  final stored = await storage.read(key: accessTokenStorageKey);
  if (stored == null) return null;
  try {
    if (jsonDecode(stored) case {
      'token': final String token,
      'endpoint': final String endpoint,
    } when token.trim().isNotEmpty) {
      return (token: token, endpoint: ApiEndpoint.parse(endpoint));
    }
  } on FormatException {
    return null;
  }
  return null;
}
