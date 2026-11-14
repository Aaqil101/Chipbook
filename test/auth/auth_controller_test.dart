import 'dart:async';

import 'package:chipbook/auth/auth_controller.dart';
import 'package:chipbook/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthService implements AuthService {
  final _changes = StreamController<bool>.broadcast();

  @override
  bool get isSignedIn => false;

  @override
  String? get userId => null;

  @override
  String? get email => null;

  @override
  Stream<bool> get signedInChanges => _changes.stream;

  @override
  Future<void> sendMagicLink(String email) async {}

  @override
  Future<void> signOut() async {}

  void emitFailure(Object error) => _changes.addError(error);

  void emitSignedIn(bool isSignedIn) => _changes.add(isSignedIn);
}

void main() {
  test('a link that cannot be exchanged is reported, not dropped', () async {
    final service = _FakeAuthService();
    final auth = AuthController(service);
    addTearDown(auth.dispose);
    var notifications = 0;
    auth.addListener(() => notifications++);

    service.emitFailure(
      const AuthException('Code verifier could not be found in local storage.'),
    );
    await pumpEventQueue();

    expect(auth.failure?.message, contains('cannot be used on this device'));
    expect(notifications, 1);
  });

  test('signing in clears a previous failure', () async {
    final service = _FakeAuthService();
    final auth = AuthController(service);
    addTearDown(auth.dispose);

    service.emitFailure(const AuthException('Token has expired'));
    await pumpEventQueue();
    expect(auth.failure, isNotNull);

    service.emitSignedIn(true);
    await pumpEventQueue();

    expect(auth.isSignedIn, isTrue);
    expect(auth.failure, isNull);
  });

  test('retrying clears the message before the request is made', () async {
    final service = _FakeAuthService();
    final auth = AuthController(service);
    addTearDown(auth.dispose);

    service.emitFailure(const AuthException('Token has expired'));
    await pumpEventQueue();

    await auth.sendMagicLink('you@example.com');

    expect(auth.failure, isNull);
  });
}
