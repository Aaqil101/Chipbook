/// Key-value storage for small, device-local settings.
///
/// Kept behind an interface so tests can use a fake and so future settings,
/// such as the biometric lock in issue #30, can share one store.
abstract interface class PreferenceStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}
