import 'dart:async';

import 'package:chipbook/auth/auth_controller.dart';
import 'package:chipbook/auth/auth_service.dart';
import 'package:chipbook/screens/sign_in_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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
}

void main() {
  testWidgets('a link that cannot be used says so on the sent screen', (
    tester,
  ) async {
    final service = _FakeAuthService();
    final auth = AuthController(service);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: auth,
          builder: (context, _) => SignInPage(auth: auth),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'you@example.com');
    await tester.tap(find.text('Send magic link'));
    await tester.pumpAndSettle();
    expect(find.text('Check your email'), findsOneWidget);

    service.emitFailure(
      const AuthException('Code verifier could not be found in local storage.'),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('cannot be used on this device'),
      findsOneWidget,
    );
  });

  testWidgets('starting over clears the failure', (tester) async {
    final service = _FakeAuthService();
    final auth = AuthController(service);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: auth,
          builder: (context, _) => SignInPage(auth: auth),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'you@example.com');
    await tester.tap(find.text('Send magic link'));
    await tester.pumpAndSettle();

    service.emitFailure(const AuthException('Token has expired'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use a different email'));
    await tester.pumpAndSettle();

    expect(find.text('Send magic link'), findsOneWidget);
    expect(find.textContaining('expired'), findsNothing);
    expect(auth.failure, isNull);
  });
}
