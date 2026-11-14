import 'package:flutter/foundation.dart';

/// Deep-link target registered in Supabase for the Android app.
const androidMagicLinkRedirect = 'chipbook://login-callback';

/// Where Supabase should send a magic link for the current build.
///
/// Returns null on the web build so Supabase uses the project's Site URL. Only
/// Android declares an intent filter for [androidMagicLinkRedirect]; other
/// platforms keep using the browser.
String? magicLinkRedirect() {
  if (kIsWeb) return null;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return androidMagicLinkRedirect;
  }
  return null;
}
