import 'package:material_ui/material_ui.dart';

import '../repositories/preference_store.dart';

/// How the app chooses between its light and dark themes.
enum ThemePreference {
  system,
  light,
  dark;

  /// Parses a stored value, falling back to [system] for anything unknown.
  static ThemePreference fromStorage(String? value) {
    for (final preference in values) {
      if (preference.name == value) {
        return preference;
      }
    }
    return system;
  }
}

/// Persists the user's appearance choice and exposes it as a [ThemeMode].
class ThemeController extends ChangeNotifier {
  ThemeController(this._store) : _preference = ThemePreference.system;

  /// Device-local key; the web splash reads the same key before Flutter loads.
  static const storageKey = 'theme_preference';

  final PreferenceStore _store;
  ThemePreference _preference;

  ThemePreference get preference => _preference;

  ThemeMode get themeMode => switch (_preference) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };

  /// Reads the saved choice. Call this before `runApp` so the first frame is
  /// already in the right appearance.
  Future<void> load() async {
    String? stored;
    try {
      stored = await _store.read(storageKey);
    } on Object {
      stored = null;
    }

    _preference = ThemePreference.fromStorage(stored);
    notifyListeners();
  }

  /// Applies [preference] immediately and saves it for the next launch.
  Future<void> setPreference(ThemePreference preference) async {
    if (preference == _preference) {
      return;
    }

    _preference = preference;
    notifyListeners();

    try {
      await _store.write(storageKey, preference.name);
    } on Object {
      // The session keeps the new appearance even if the write fails.
    }
  }
}
