/// Validation for the sign-in form.
abstract final class AuthValidation {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? emailError(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return 'Enter your email';
    }
    if (!_email.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }
}
