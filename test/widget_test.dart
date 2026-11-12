import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:chipbook/app_info.dart';
import 'package:chipbook/auth/auth_controller.dart';
import 'package:chipbook/auth/auth_service.dart';
import 'package:chipbook/main.dart';
import 'package:chipbook/repositories/entry_repository.dart';
import 'package:chipbook/state/ledger_controller.dart';

void main() {
  testWidgets('signed-out users see the sign-in screen', (tester) async {
    final fake = FakeAuthService();
    final auth = AuthController(fake);
    addTearDown(fake.dispose);
    addTearDown(auth.dispose);

    final ledger = LedgerController(InMemoryEntryRepository());
    await ledger.load();
    addTearDown(ledger.dispose);

    await tester.pumpWidget(ChipbookApp(auth: auth, ledger: ledger));

    expect(find.text('Send magic link'), findsOneWidget);
    expect(find.text('No entries yet'), findsNothing);
  });

  testWidgets('signed-in users see the empty ledger', (tester) async {
    final fake = FakeAuthService(signedIn: true);
    final auth = AuthController(fake);
    addTearDown(fake.dispose);
    addTearDown(auth.dispose);

    final ledger = LedgerController(InMemoryEntryRepository());
    await ledger.load();
    addTearDown(ledger.dispose);

    await tester.pumpWidget(ChipbookApp(auth: auth, ledger: ledger));

    expect(find.text(AppInfo.name), findsOneWidget);
    expect(find.text('No entries yet'), findsOneWidget);
    expect(find.text('Add entry'), findsOneWidget);
  });

  testWidgets('sending a magic link shows confirmation', (tester) async {
    final fake = FakeAuthService();
    final auth = AuthController(fake);
    addTearDown(fake.dispose);
    addTearDown(auth.dispose);

    final ledger = LedgerController(InMemoryEntryRepository());
    await ledger.load();
    addTearDown(ledger.dispose);

    await tester.pumpWidget(ChipbookApp(auth: auth, ledger: ledger));

    await tester.enterText(find.byType(TextFormField), 'ada@example.com');
    await tester.tap(find.text('Send magic link'));
    await tester.pumpAndSettle();

    expect(fake.lastEmail, 'ada@example.com');
    expect(find.text('Check your email'), findsOneWidget);
  });

  testWidgets('pending entries show up without changing the total', (
    tester,
  ) async {
    final fake = FakeAuthService(signedIn: true);
    final auth = AuthController(fake);
    addTearDown(fake.dispose);
    addTearDown(auth.dispose);

    final ledger = LedgerController(InMemoryEntryRepository());
    await ledger.load();
    addTearDown(ledger.dispose);

    await tester.pumpWidget(ChipbookApp(auth: auth, ledger: ledger));

    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '12.50');
    await tester.enterText(fields.at(1), 'Ada');
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('USD 12.50'), findsOneWidget);
    expect(find.text('USD 0.00'), findsOneWidget);
  });

  testWidgets('signing out returns to the sign-in screen', (tester) async {
    final fake = FakeAuthService(signedIn: true);
    final auth = AuthController(fake);
    addTearDown(fake.dispose);
    addTearDown(auth.dispose);

    final ledger = LedgerController(InMemoryEntryRepository());
    await ledger.load();
    addTearDown(ledger.dispose);

    await tester.pumpWidget(ChipbookApp(auth: auth, ledger: ledger));

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.text('Send magic link'), findsOneWidget);
  });
}

class FakeAuthService implements AuthService {
  FakeAuthService({bool signedIn = false}) : _isSignedIn = signedIn;

  final _changes = StreamController<bool>.broadcast();
  bool _isSignedIn;
  String? lastEmail;

  @override
  bool get isSignedIn => _isSignedIn;

  @override
  String? get email => _isSignedIn ? 'ada@example.com' : null;

  @override
  Stream<bool> get signedInChanges => _changes.stream;

  @override
  Future<void> sendMagicLink(String email) async {
    lastEmail = email;
  }

  @override
  Future<void> signOut() async {
    _isSignedIn = false;
    _changes.add(false);
  }

  void dispose() => _changes.close();
}
