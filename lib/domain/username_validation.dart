/// Validation for the username other members see.
///
/// Mirrors the `profiles.username` check in the database: 3-20 lowercase
/// letters, digits, or underscores.
abstract final class UsernameValidation {
  static final RegExp _pattern = RegExp(r'^[a-z0-9_]{3,20}$');
  static final RegExp _uppercase = RegExp('[A-Z]');

  static String? error(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return 'Choose a username';
    }
    if (value.length < 3) {
      return 'Use at least 3 characters';
    }
    if (value.length > 20) {
      return 'Use 20 characters or fewer';
    }
    if (_uppercase.hasMatch(value)) {
      return 'Use lowercase letters only';
    }
    if (!_pattern.hasMatch(value)) {
      return 'Use letters, numbers, and underscores only';
    }
    return null;
  }
}
