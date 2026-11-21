import 'package:flutter/foundation.dart';

/// Deep-link target registered in Supabase for the Android app.
const androidAuthRedirect = 'chipbook://login-callback';

/// Where Supabase should send a Google sign-in.
///
/// Returns null on the web build so Supabase uses the project's Site URL. Only
/// Android declares an intent filter for [androidAuthRedirect]; other platforms
/// keep using the browser.
String? authRedirect() {
  if (kIsWeb) return null;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return androidAuthRedirect;
  }
  return null;
}
