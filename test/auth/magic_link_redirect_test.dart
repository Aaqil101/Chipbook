import 'package:chipbook/auth/magic_link_redirect.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('Android sends magic links back to the app', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(magicLinkRedirect(), androidMagicLinkRedirect);
  });

  test('other platforms fall back to the Supabase Site URL', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    expect(magicLinkRedirect(), isNull);
  });
}
