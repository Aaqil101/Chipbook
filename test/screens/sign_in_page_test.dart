import 'dart:async';

import 'package:chipbook/auth/auth_controller.dart';
import 'package:chipbook/auth/auth_failure.dart';
import 'package:chipbook/auth/auth_service.dart';
import 'package:chipbook/screens/sign_in_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeAuthService implements AuthService {
  final _changes = StreamController<bool>.broadcast();

  String? lastEmail;
  String? lastCode;
  Object? verifyError;

  @override
  bool get isSignedIn => false;

  @override
  String? get userId => null;

  @override
  String? get email => null;

  @override
  String? get provider => null;

  @override
  Stream<bool> get signedInChanges => _changes.stream;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> sendSignInCode(String email) async {
    lastEmail = email;
  }

  @override
  Future<void> verifySignInCode(String email, String code) async {
    lastEmail = email;
    lastCode = code;
    final error = verifyError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('Google is offered above the email fallback', (tester) async {
    final service = _FakeAuthService();
    final auth = AuthController(service);
    addTearDown(auth.dispose);

    await tester.pumpWidget(MaterialApp(home: SignInPage(auth: auth)));

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('or use email'), findsOneWidget);
    expect(find.text('Email me a sign-in code'), findsOneWidget);
  });

  testWidgets('sending a code shows the code step', (tester) async {
    final (:auth, :service) = await _pumpSentCodeStep(tester);

    expect(service.lastEmail, 'you@example.com');
    expect(find.text('Check your email'), findsOneWidget);
    expect(
      find.textContaining('6-digit code to you@example.com'),
      findsOneWidget,
    );
    expect(find.text('Verify code'), findsOneWidget);
    expect(auth.failure, isNull);
  });

  testWidgets('the code is verified with the emailed address', (tester) async {
    final (:auth, :service) = await _pumpSentCodeStep(tester);

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Verify code'));
    await tester.pumpAndSettle();

    expect(service.lastEmail, 'you@example.com');
    expect(service.lastCode, '123456');
    expect(auth.failure, isNull);
  });

  testWidgets('a wrong code stays on the code step with the address', (
    tester,
  ) async {
    final (:auth, :service) = await _pumpSentCodeStep(tester);
    service.verifyError = const AuthFailure(
      'That code is incorrect or has expired. Send a new code.',
    );

    await tester.enterText(find.byType(TextFormField), '000000');
    await tester.tap(find.text('Verify code'));
    await tester.pumpAndSettle();

    expect(find.textContaining('code is incorrect'), findsOneWidget);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('you@example.com'), findsOneWidget);
    expect(find.text('Email me a sign-in code'), findsNothing);
    expect(auth.failure, isNull);
  });

  testWidgets('the code must be six digits', (tester) async {
    final (:auth, :service) = await _pumpSentCodeStep(tester);

    await tester.enterText(find.byType(TextFormField), '123');
    await tester.tap(find.text('Verify code'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the 6-digit code from the email'), findsOneWidget);
    expect(service.lastCode, isNull);
  });

  testWidgets('resending clears the code field', (tester) async {
    final (:auth, :service) = await _pumpSentCodeStep(tester);

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Resend code'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.controller?.text, isEmpty);
    expect(service.lastEmail, 'you@example.com');
    expect(find.text('Check your email'), findsOneWidget);
  });

  testWidgets('starting over returns to the email step', (tester) async {
    final (:auth, :service) = await _pumpSentCodeStep(tester);
    service.verifyError = const AuthFailure('That code has expired.');

    await tester.enterText(find.byType(TextFormField), '000000');
    await tester.tap(find.text('Verify code'));
    await tester.pumpAndSettle();
    expect(find.textContaining('expired'), findsOneWidget);

    await tester.tap(find.text('Use a different email'));
    await tester.pumpAndSettle();

    expect(find.text('Email me a sign-in code'), findsOneWidget);
    expect(find.textContaining('expired'), findsNothing);
    expect(auth.failure, isNull);
  });
}

Future<({AuthController auth, _FakeAuthService service})> _pumpSentCodeStep(
  WidgetTester tester,
) async {
  final service = _FakeAuthService();
  final auth = AuthController(service);
  addTearDown(auth.dispose);

  await tester.pumpWidget(MaterialApp(home: SignInPage(auth: auth)));
  await tester.enterText(find.byType(TextFormField), 'you@example.com');
  await tester.tap(find.text('Email me a sign-in code'));
  await tester.pumpAndSettle();

  return (auth: auth, service: service);
}
