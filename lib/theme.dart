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
  final scheme = ColorScheme.fromSeed(
    seedColor: brandSeedColor,
    brightness: brightness,
  );

  return ThemeData(
    colorScheme: brightness == Brightness.dark
        ? _neutralDarkSurfaces(scheme)
        : scheme,
  );
}

/// Material tints every dark surface with the seed, which reads as green over
/// large areas. Keep the teal accents but give the surfaces a neutral scale.
ColorScheme _neutralDarkSurfaces(ColorScheme seeded) {
  return seeded.copyWith(
    surface: const Color(0xFF111315),
    surfaceDim: const Color(0xFF0C0E10),
    surfaceBright: const Color(0xFF303234),
    surfaceContainerLowest: const Color(0xFF0B0D0F),
    surfaceContainerLow: const Color(0xFF16181A),
    surfaceContainer: const Color(0xFF1B1D1F),
    surfaceContainerHigh: const Color(0xFF242628),
    surfaceContainerHighest: const Color(0xFF2C2E30),
    onSurface: const Color(0xFFE5E7E7),
    onSurfaceVariant: const Color(0xFFB6BABA),
    inverseSurface: const Color(0xFFE2E4E4),
    onInverseSurface: const Color(0xFF2B2D2F),
    outline: const Color(0xFF8A8E8E),
    outlineVariant: const Color(0xFF3C4040),
    surfaceTint: Colors.transparent,
  );
}
