import 'package:material_ui/material_ui.dart';

/// The brand seed. Both schemes are derived from it, so they stay consistent.
const Color brandSeedColor = Colors.teal;

/// The light scheme used when the system is light or the user picks Light.
ThemeData buildLightTheme() {
  return _theme(Brightness.light);
}

/// The dark scheme used when the system is dark or the user picks Dark.
ThemeData buildDarkTheme() {
  return _theme(Brightness.dark);
}

ThemeData _theme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandSeedColor,
      brightness: brightness,
    ),
  );
}
