import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_service.dart';

/// Exposes authentication state to widgets.
class AuthController extends ChangeNotifier {
  AuthController(this._service) : _isSignedIn = _service.isSignedIn {
    _subscription = _service.signedInChanges.listen(_handleChange);
  }

  final AuthService _service;
  late final StreamSubscription<bool> _subscription;
  bool _isSignedIn;

  bool get isSignedIn => _isSignedIn;

  String? get userId => _service.userId;

  String? get email => _service.email;

  Future<void> sendMagicLink(String email) => _service.sendMagicLink(email);

  Future<void> signOut() => _service.signOut();

  void _handleChange(bool isSignedIn) {
    if (_isSignedIn == isSignedIn) {
      return;
    }
    _isSignedIn = isSignedIn;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
