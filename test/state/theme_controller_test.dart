import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:chipbook/repositories/preference_store.dart';
import 'package:chipbook/state/theme_controller.dart';

void main() {
  test('defaults to system', () {
    final themes = ThemeController(FakePreferenceStore());

    expect(themes.preference, ThemePreference.system);
    expect(themes.themeMode, ThemeMode.system);
  });

  test('load reads the saved preference', () async {
    final store = FakePreferenceStore(
      values: {ThemeController.storageKey: 'dark'},
    );
    final themes = ThemeController(store);

    await themes.load();

    expect(themes.preference, ThemePreference.dark);
    expect(themes.themeMode, ThemeMode.dark);
  });

  test('load falls back to system for unknown or missing values', () async {
    final unknown = ThemeController(
      FakePreferenceStore(values: {ThemeController.storageKey: 'sepia'}),
    );
    await unknown.load();
    expect(unknown.preference, ThemePreference.system);

    final missing = ThemeController(FakePreferenceStore());
    await missing.load();
    expect(missing.preference, ThemePreference.system);
  });

  test('load falls back to system when storage fails', () async {
    final themes = ThemeController(FakePreferenceStore(readError: true));

    await themes.load();

    expect(themes.preference, ThemePreference.system);
  });

  test('setPreference notifies, changes the mode, and persists', () async {
    final store = FakePreferenceStore();
    final themes = ThemeController(store);
    var notifications = 0;
    themes.addListener(() => notifications++);

    await themes.setPreference(ThemePreference.light);

    expect(themes.preference, ThemePreference.light);
    expect(themes.themeMode, ThemeMode.light);
    expect(store.values[ThemeController.storageKey], 'light');
    expect(notifications, 1);
  });

  test('setPreference keeps the choice when the write fails', () async {
    final themes = ThemeController(FakePreferenceStore(writeError: true));

    await themes.setPreference(ThemePreference.dark);

    expect(themes.preference, ThemePreference.dark);
    expect(themes.themeMode, ThemeMode.dark);
  });
}

class FakePreferenceStore implements PreferenceStore {
  FakePreferenceStore({
    Map<String, String>? values,
    this.readError = false,
    this.writeError = false,
  }) : values = values ?? <String, String>{};

  final Map<String, String> values;
  final bool readError;
  final bool writeError;

  @override
  Future<String?> read(String key) async {
    if (readError) {
      throw StateError('read failed');
    }
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (writeError) {
      throw StateError('write failed');
    }
    values[key] = value;
  }
}
