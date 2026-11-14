import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_failure.dart';
import 'auth_service.dart';

/// Exposes authentication state to widgets.
class AuthController extends ChangeNotifier {
  AuthController(this._service) : _isSignedIn = _service.isSignedIn {
    _subscription = _service.signedInChanges.listen(
      _handleChange,
      onError: _handleError,
    );
  }

  final AuthService _service;
  late final StreamSubscription<bool> _subscription;
  bool _isSignedIn;
  AuthFailure? _failure;

  bool get isSignedIn => _isSignedIn;

  /// Why the last magic link could not be used, or null when there is none.
  ///
  /// A link that fails is not a session change, so it is reported here for the
  /// sign-in screen instead of being left as an unhandled stream error.
  AuthFailure? get failure => _failure;

  String? get userId => _service.userId;

  String? get email => _service.email;

  Future<void> sendMagicLink(String email) {
    clearFailure();
    return _service.sendMagicLink(email);
  }

  Future<void> signOut() => _service.signOut();

  /// Drops [failure] once the user has seen it or starts over.
  void clearFailure() {
    if (_failure == null) {
      return;
    }
    _failure = null;
    notifyListeners();
  }

  void _handleChange(bool isSignedIn) {
    if (_isSignedIn == isSignedIn) {
      return;
    }
    _isSignedIn = isSignedIn;
    if (isSignedIn) {
      _failure = null;
    }
    notifyListeners();
  }

  void _handleError(Object error, StackTrace stackTrace) {
    _failure = linkFailure(error);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
