import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:chipbook/auth/auth_controller.dart';
import 'package:chipbook/auth/auth_service.dart';
import 'package:chipbook/main.dart';
import 'package:chipbook/models/entry.dart';
import 'package:chipbook/models/fund.dart';
import 'package:chipbook/models/member_role.dart';
import 'package:chipbook/models/membership.dart';
import 'package:chipbook/repositories/entry_repository.dart';
import 'package:chipbook/repositories/fund_repository.dart';
import 'package:chipbook/repositories/membership_repository.dart';

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
        membershipRepository: FakeMembershipRepository(),
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
        membershipRepository: FakeMembershipRepository(),
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

  testWidgets('organizers can approve a pending entry', (tester) async {
    final entries = InMemoryEntryRepository();
    await entries.add(_entry(id: 'pending', amountMinor: 1250));

    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      entries: entries,
    );

    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('USD 0.00'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    expect(find.text('Approve'), findsNothing);
    expect(find.text('Pending'), findsNothing);
    expect(find.text('USD 12.50'), findsNWidgets(2));
  });

  testWidgets('members see no approve or reverse controls', (tester) async {
    final entries = InMemoryEntryRepository();
    await entries.add(_entry(id: 'pending', amountMinor: 1250));
    await entries.add(
      _entry(id: 'approved', amountMinor: 5000, status: EntryStatus.approved),
    );

    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      entries: entries,
      role: MemberRole.member,
    );

    expect(find.text('Approve'), findsNothing);
    expect(find.text('Reverse'), findsNothing);
    expect(find.text('Add entry'), findsOneWidget);
  });

  testWidgets('observers can read the ledger but not add or approve', (
    tester,
  ) async {
    final entries = InMemoryEntryRepository();
    await entries.add(_entry(id: 'pending', amountMinor: 1250));
    await entries.add(
      _entry(id: 'approved', amountMinor: 5000, status: EntryStatus.approved),
    );

    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      entries: entries,
      role: MemberRole.observer,
    );

    expect(find.text('Approve'), findsNothing);
    expect(find.text('Reverse'), findsNothing);
    expect(find.text('Add entry'), findsNothing);
    expect(find.text('USD 50.00'), findsNWidgets(2));
  });

  testWidgets('reversing an approved entry records a reason', (tester) async {
    final entries = InMemoryEntryRepository();
    await entries.add(
      _entry(
        id: 'approved',
        amountMinor: 5000,
        status: EntryStatus.approved,
        note: 'Original note',
      ),
    );

    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      entries: entries,
    );

    await tester.tap(find.text('Reverse'));
    await tester.pumpAndSettle();

    expect(find.text('Reverse entry'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('Ada')),
      findsOneWidget,
    );
    expect(find.text('USD 50.00'), findsWidgets);

    await tester.enterText(find.byType(TextFormField), 'Recorded twice');
    await tester.tap(find.text('Record reversal'));
    await tester.pumpAndSettle();

    expect(find.text('Reversal'), findsOneWidget);
    expect(find.text('Reversed'), findsOneWidget);
    expect(find.textContaining('Recorded twice'), findsOneWidget);
    expect(find.text('USD 50.00'), findsOneWidget);
    expect(find.text('-USD 50.00'), findsOneWidget);
    expect(find.text('USD 0.00'), findsOneWidget);
  });

  testWidgets('a reversal cannot be recorded without a reason', (tester) async {
    final entries = InMemoryEntryRepository();
    await entries.add(
      _entry(id: 'approved', amountMinor: 5000, status: EntryStatus.approved),
    );

    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      entries: entries,
    );

    await tester.tap(find.text('Reverse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record reversal'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a reason for the reversal'), findsOneWidget);
    expect(find.text('Reverse entry'), findsOneWidget);
  });

  testWidgets('switching funds reloads the ledger and role', (tester) async {
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
    expect(find.text('Reverse'), findsOneWidget);
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
  MemberRole role = MemberRole.organizer,
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
      membershipRepository: FakeMembershipRepository(role: role),
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

Entry _entry({
  required String id,
  required int amountMinor,
  EntryStatus status = EntryStatus.pending,
  String note = '',
}) {
  return Entry(
    id: id,
    fundId: 'fund-a',
    amountMinor: amountMinor,
    currency: 'USD',
    contributorName: 'Ada',
    note: note,
    createdAt: DateTime(2026, 1, 1),
    status: status,
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
  String? get userId => _isSignedIn ? 'user-1' : null;

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

class FakeMembershipRepository implements MembershipRepository {
  FakeMembershipRepository({this.role = MemberRole.organizer});

  final MemberRole role;

  @override
  Future<List<Membership>> getMemberships({required String fundId}) async {
    return [
      Membership(
        fundId: fundId,
        userId: 'user-1',
        role: role,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
  }

  @override
  Future<void> setRole({
    required String fundId,
    required String userId,
    required MemberRole role,
  }) async {
    throw UnsupportedError('setRole is covered by member management');
  }

  @override
  Future<void> removeMember({
    required String fundId,
    required String userId,
  }) async {
    throw UnsupportedError('removeMember is covered by member management');
  }
}
