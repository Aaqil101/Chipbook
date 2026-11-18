import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:chipbook/theme.dart';

void main() {
  test('light and dark themes are seeded from the same teal', () {
    final light = buildLightTheme();
    final dark = buildDarkTheme();

    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);
    expect(
      light.colorScheme.primary,
      ColorScheme.fromSeed(seedColor: brandSeedColor).primary,
    );
    expect(
      dark.colorScheme.primary,
      ColorScheme.fromSeed(
        seedColor: brandSeedColor,
        brightness: Brightness.dark,
      ).primary,
    );
  });

  test('the dark scheme has a dark surface and light text', () {
    final scheme = buildDarkTheme().colorScheme;

    expect(scheme.surface.computeLuminance(), lessThan(0.05));
    expect(scheme.onSurface.computeLuminance(), greaterThan(0.5));
  });

  test('the dark surfaces stay neutral instead of green-tinted', () {
    final scheme = buildDarkTheme().colorScheme;
    final channels = [
      (scheme.surface.r * 255).round(),
      (scheme.surface.g * 255).round(),
      (scheme.surface.b * 255).round(),
    ];
    final spread = channels.reduce(math.max) - channels.reduce(math.min);

    expect(spread, lessThanOrEqualTo(6));
    expect(scheme.surfaceTint, Colors.transparent);
  });
}
