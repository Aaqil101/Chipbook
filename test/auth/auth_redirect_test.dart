import 'package:chipbook/auth/auth_redirect.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('Android sends sign-ins back to the app', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(authRedirect(), androidAuthRedirect);
  });

  test('other platforms fall back to the Supabase Site URL', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    expect(authRedirect(), isNull);
  });
}
