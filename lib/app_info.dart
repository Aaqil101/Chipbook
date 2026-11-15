/// Single source of truth for the app's display name and metadata.
abstract final class AppInfo {
  static const String name = 'Chipbook';

  /// One-line description shown on the About page.
  static const String tagline = 'A shared ledger for group fundraising.';

  /// Keep in sync with `version` in `pubspec.yaml`.
  static const String version = '1.0.0';

  static const String license = 'GPL-3.0';
}
