import 'package:shared_preferences/shared_preferences.dart';

import 'api_endpoint_store.dart';

class PreferencesApiEndpointStore implements ApiEndpointStore {
  static const _key = 'backend_api_base_url';
  final SharedPreferencesAsync _preferences;

  PreferencesApiEndpointStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<String?> read() => _preferences.getString(_key);

  @override
  Future<void> save(String? url) => url == null
      ? _preferences.remove(_key)
      : _preferences.setString(_key, url);
}
