/// Parses the invite codes organizers share with new members.
abstract final class InviteCode {
  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Returns the invite token in [raw], or null when it is not valid.
  ///
  /// Accepts a bare UUID or a URL with an `invite` query parameter, so a
  /// pasted link works too.
  static String? tryParse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }

    if (_uuid.hasMatch(value)) {
      return value.toLowerCase();
    }

    final uri = Uri.tryParse(value);
    final token = uri?.queryParameters['invite'];
    if (token != null && _uuid.hasMatch(token)) {
      return token.toLowerCase();
    }
    return null;
  }

  static String? error(String raw) {
    return tryParse(raw) == null ? 'Enter a valid invite code or link' : null;
  }
}
