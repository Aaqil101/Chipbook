/// A readable label for the provider behind the current session.
String signInProviderLabel(String? provider) {
  switch (provider) {
    case 'google':
      return 'Signed in with Google';
    case 'email':
      return 'Signed in with an email code';
    default:
      return 'Signed in';
  }
}
