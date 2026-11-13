/// Validation for inviting someone to a fund.
abstract final class InviteValidation {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? emailError(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return 'Enter an email address';
    }
    if (!_email.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    if (value.length > 254) {
      return 'Use 254 characters or fewer';
    }
    return null;
  }
}
