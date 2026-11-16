import 'package:chipbook/domain/sign_in_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('names the provider behind the session', () {
    expect(signInProviderLabel('google'), 'Signed in with Google');
    expect(signInProviderLabel('email'), 'Signed in with an email link');
  });

  test('falls back when the provider is unknown', () {
    expect(signInProviderLabel(null), 'Signed in');
    expect(signInProviderLabel('github'), 'Signed in');
  });
}
