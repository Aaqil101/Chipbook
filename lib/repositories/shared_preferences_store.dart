import 'package:shared_preferences/shared_preferences.dart';

import 'preference_store.dart';

/// Device-local preferences backed by `shared_preferences`.
///
/// Uses `localStorage` on web and DataStore on Android, so the same appearance
/// choice survives a reload and a cold start.
class SharedPreferencesStore implements PreferenceStore {
  SharedPreferencesStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}
