import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:chipbook/auth/auth_controller.dart';
import 'package:chipbook/auth/auth_service.dart';
import 'package:chipbook/main.dart';
import 'package:chipbook/models/entry.dart';
import 'package:chipbook/models/fund.dart';
import 'package:chipbook/repositories/entry_repository.dart';
import 'package:chipbook/repositories/fund_repository.dart';

void main() {
  testWidgets('signed-out users see the sign-in screen', (tester) async {
    final fake = FakeAuthService();
    final auth = AuthController(fake);
    addTearDown(fake.dispose);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      ChipbookApp(
        auth: auth,
        fundRepository: FakeFundRepository(),
        entryRepository: InMemoryEntryRepository(),
      ),
    );

    expect(find.text('Send magic link'), findsOneWidget);
    expect(find.text('No entries yet'), findsNothing);
  });

  testWidgets('signed-in users see the empty ledger', (tester) async {
    await _pumpSignedIn(tester, funds: [_fund('fund-a', 'Trip fund')]);

    expect(find.text('Trip fund'), findsOneWidget);
    expect(find.text('No entries yet'), findsOneWidget);
    expect(find.text('Add entry'), findsOneWidget);
  });

  testWidgets('users without funds are prompted to create one', (tester) async {
    await _pumpSignedIn(tester);

    expect(find.text('No funds yet'), findsOneWidget);
    expect(find.text('Create a fund'), findsOneWidget);
  });

  testWidgets('creating a fund opens its empty ledger', (tester) async {
    await _pumpSignedIn(tester);

    await tester.tap(find.text('Create a fund'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Trip fund');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Trip fund'), findsOneWidget);
    expect(find.text('No entries yet'), findsOneWidget);
  });

  testWidgets('sending a magic link shows confirmation', (tester) async {
    final fake = FakeAuthService();
    final auth = AuthController(fake);
    addTearDown(fake.dispose);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      ChipbookApp(
        auth: auth,
        fundRepository: FakeFundRepository(),
        entryRepository: InMemoryEntryRepository(),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'ada@example.com');
    await tester.tap(find.text('Send magic link'));
    await tester.pumpAndSettle();

    expect(fake.lastEmail, 'ada@example.com');
    expect(find.text('Check your email'), findsOneWidget);
  });

  testWidgets('pending entries show up without changing the total', (
    tester,
  ) async {
    await _pumpSignedIn(tester, funds: [_fund('fund-a', 'Trip fund')]);

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

  testWidgets('switching funds reloads the ledger', (tester) async {
    final entries = InMemoryEntryRepository();
    await entries.add(
      Entry(
        id: 'entry-b',
        fundId: 'fund-b',
        amountMinor: 5000,
        currency: 'USD',
        contributorName: 'Grace',
        createdAt: DateTime(2026, 1, 1),
        status: EntryStatus.approved,
      ),
    );

    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund'), _fund('fund-b', 'Gift fund')],
      entries: entries,
    );

    expect(find.text('No entries yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.swap_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gift fund'));
    await tester.pumpAndSettle();

    expect(find.text('Gift fund'), findsOneWidget);
    expect(find.text('Grace'), findsOneWidget);
    expect(find.text('USD 50.00'), findsNWidgets(2));
  });

  testWidgets('signing out returns to the sign-in screen', (tester) async {
    await _pumpSignedIn(tester, funds: [_fund('fund-a', 'Trip fund')]);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.text('Send magic link'), findsOneWidget);
  });
}

Future<void> _pumpSignedIn(
  WidgetTester tester, {
  List<Fund> funds = const [],
  InMemoryEntryRepository? entries,
}) async {
  final fake = FakeAuthService(signedIn: true);
  final auth = AuthController(fake);
  addTearDown(fake.dispose);
  addTearDown(auth.dispose);

  await tester.pumpWidget(
    ChipbookApp(
      auth: auth,
      fundRepository: FakeFundRepository(funds: funds),
      entryRepository: entries ?? InMemoryEntryRepository(),
    ),
  );
  await tester.pumpAndSettle();
}

Fund _fund(String id, String name) {
  return Fund(
    id: id,
    name: name,
    defaultCurrency: 'USD',
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
  );
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

class FakeFundRepository implements FundRepository {
  FakeFundRepository({List<Fund>? funds}) : _funds = [...?funds];

  final List<Fund> _funds;
  int _nextId = 0;

  @override
  Future<List<Fund>> getFunds() async => List.unmodifiable(_funds);

  @override
  Future<Fund> createFund({
    required String name,
    required String defaultCurrency,
  }) async {
    final fund = Fund(
      id: 'created-${_nextId++}',
      name: name,
      defaultCurrency: defaultCurrency,
      createdBy: 'user-1',
      createdAt: DateTime(2026, 1, 1),
    );
    _funds.add(fund);
    return fund;
  }
}
