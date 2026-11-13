import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:chipbook/auth/auth_controller.dart';
import 'package:chipbook/auth/auth_service.dart';
import 'package:chipbook/main.dart';
import 'package:chipbook/models/entry.dart';
import 'package:chipbook/models/fund.dart';
import 'package:chipbook/models/invite.dart';
import 'package:chipbook/models/member_role.dart';
import 'package:chipbook/models/membership.dart';
import 'package:chipbook/repositories/entry_repository.dart';
import 'package:chipbook/repositories/fund_repository.dart';
import 'package:chipbook/repositories/invite_repository.dart';
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
        inviteRepository: FakeInviteRepository(),
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
        inviteRepository: FakeInviteRepository(),
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

  testWidgets('members page shows friendly role labels', (tester) async {
    final memberships = FakeMembershipRepository(
      members: [
        _membership('user-1', 'ada@example.com', MemberRole.organizer),
        _membership('user-2', 'grace@example.com', MemberRole.member),
        _membership('user-3', 'linus@example.com', MemberRole.observer),
      ],
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
    );

    await _openMembers(tester);

    expect(find.text('ada@example.com (you)'), findsOneWidget);
    expect(find.text('grace@example.com'), findsOneWidget);
    expect(find.text('linus@example.com'), findsOneWidget);
    expect(find.text('Organizer'), findsOneWidget);
    expect(find.text('Member'), findsOneWidget);
    expect(find.text('Observer'), findsOneWidget);
    expect(find.text('Invite'), findsOneWidget);
  });

  testWidgets('organizers create an invite for a chosen role', (tester) async {
    final memberships = FakeMembershipRepository(
      members: [_membership('user-1', 'ada@example.com', MemberRole.organizer)],
    );
    final invites = FakeInviteRepository();
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
      invites: invites,
    );

    await _openMembers(tester);
    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'grace@example.com');
    await tester.tap(find.text('Member'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Observer').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create invite'));
    await tester.pumpAndSettle();

    expect(find.text('Invite code'), findsOneWidget);
    expect(find.text(FakeInviteRepository.testToken), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(invites.lastEmail, 'grace@example.com');
    expect(invites.lastRole, MemberRole.observer);
    expect(find.text('Pending invites'), findsOneWidget);
    expect(find.text('grace@example.com'), findsOneWidget);
  });

  testWidgets('members cannot invite or manage other members', (tester) async {
    final memberships = FakeMembershipRepository(
      members: [
        _membership('user-1', 'ada@example.com', MemberRole.member),
        _membership('user-2', 'grace@example.com', MemberRole.organizer),
      ],
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
    );

    await _openMembers(tester);

    expect(find.text('Invite'), findsNothing);
    expect(find.byTooltip('Manage grace@example.com'), findsNothing);
    expect(find.text('Member'), findsOneWidget);
    expect(find.text('Organizer'), findsOneWidget);
  });

  testWidgets('the last organizer cannot be demoted or removed', (
    tester,
  ) async {
    final memberships = FakeMembershipRepository(
      members: [_membership('user-1', 'ada@example.com', MemberRole.organizer)],
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
    );

    await _openMembers(tester);

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byTooltip('Manage ada@example.com'), findsNothing);
    expect(find.text('Invite'), findsOneWidget);
  });

  testWidgets('organizers remove a member when another organizer remains', (
    tester,
  ) async {
    final memberships = FakeMembershipRepository(
      members: [
        _membership('user-1', 'ada@example.com', MemberRole.organizer),
        _membership('user-2', 'grace@example.com', MemberRole.organizer),
      ],
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
    );

    await _openMembers(tester);
    await tester.tap(find.byTooltip('Manage grace@example.com'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from fund'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(memberships.removedUserIds, ['user-2']);
    expect(find.text('grace@example.com'), findsNothing);
  });

  testWidgets('the database last-organizer guard is surfaced', (tester) async {
    final memberships = FakeMembershipRepository(
      members: [
        _membership('user-1', 'ada@example.com', MemberRole.organizer),
        _membership('user-2', 'grace@example.com', MemberRole.organizer),
      ],
      mutationError: Exception('a fund must keep at least one organizer'),
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
    );

    await _openMembers(tester);
    await tester.tap(find.byTooltip('Manage grace@example.com'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from fund'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.textContaining('at least one organizer'), findsOneWidget);
    expect(find.text('grace@example.com'), findsOneWidget);
  });

  testWidgets('expired invites are marked in the member list', (tester) async {
    final invites = FakeInviteRepository();
    invites.invites.add(
      Invite(
        id: 'old',
        fundId: 'fund-a',
        email: 'old@example.com',
        role: MemberRole.member,
        token: FakeInviteRepository.testToken,
        createdAt: DateTime(2020, 1, 1),
        expiresAt: DateTime(2020, 1, 2),
      ),
    );
    final memberships = FakeMembershipRepository(
      members: [_membership('user-1', 'ada@example.com', MemberRole.organizer)],
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
      invites: invites,
    );

    await _openMembers(tester);

    expect(find.textContaining('expired'), findsOneWidget);
    expect(find.text('old@example.com'), findsOneWidget);
  });

  testWidgets('redeeming an invite joins the fund', (tester) async {
    final fundRepository = FakeFundRepository();
    final invites = FakeInviteRepository(
      onAccept: (_) => fundRepository.addFund(_fund('fund-a', 'Trip fund')),
    );
    await _pumpSignedIn(
      tester,
      fundRepository: fundRepository,
      invites: invites,
    );

    expect(find.text('No funds yet'), findsOneWidget);
    await tester.tap(find.text('Redeem an invite'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      FakeInviteRepository.testToken,
    );
    await tester.tap(find.text('Join fund'));
    await tester.pumpAndSettle();

    expect(invites.lastToken, FakeInviteRepository.testToken);
    expect(find.text('Trip fund'), findsOneWidget);
    expect(find.text('Invite accepted'), findsOneWidget);
  });
}

Future<void> _pumpSignedIn(
  WidgetTester tester, {
  List<Fund> funds = const [],
  FakeFundRepository? fundRepository,
  InMemoryEntryRepository? entries,
  MemberRole role = MemberRole.organizer,
  FakeMembershipRepository? memberships,
  FakeInviteRepository? invites,
}) async {
  final fake = FakeAuthService(signedIn: true);
  final auth = AuthController(fake);
  addTearDown(fake.dispose);
  addTearDown(auth.dispose);

  await tester.pumpWidget(
    ChipbookApp(
      auth: auth,
      fundRepository: fundRepository ?? FakeFundRepository(funds: funds),
      entryRepository: entries ?? InMemoryEntryRepository(),
      membershipRepository: memberships ?? FakeMembershipRepository(role: role),
      inviteRepository: invites ?? FakeInviteRepository(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openMembers(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.group_outlined));
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

Membership _membership(String userId, String email, MemberRole role) {
  return Membership(
    fundId: 'fund-a',
    userId: userId,
    email: email,
    role: role,
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

  void addFund(Fund fund) => _funds.add(fund);

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
  FakeMembershipRepository({
    MemberRole role = MemberRole.organizer,
    List<Membership>? members,
    this.mutationError,
  }) : _defaultRole = role,
       _members = members == null ? null : [...members];

  final MemberRole _defaultRole;
  final List<Membership>? _members;
  final Object? mutationError;
  final List<MemberRole> roleChanges = [];
  final List<String> removedUserIds = [];

  @override
  Future<List<Membership>> getMemberships({required String fundId}) async {
    final members = _members;
    if (members != null) {
      return List.unmodifiable(members);
    }
    return [
      Membership(
        fundId: fundId,
        userId: 'user-1',
        email: 'ada@example.com',
        role: _defaultRole,
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
    if (mutationError != null) {
      throw mutationError!;
    }
    roleChanges.add(role);

    final members = _members;
    if (members == null) {
      return;
    }
    final index = members.indexWhere((member) => member.userId == userId);
    if (index == -1) {
      return;
    }
    final current = members[index];
    members[index] = Membership(
      fundId: current.fundId,
      userId: current.userId,
      role: role,
      createdAt: current.createdAt,
      email: current.email,
    );
  }

  @override
  Future<void> removeMember({
    required String fundId,
    required String userId,
  }) async {
    if (mutationError != null) {
      throw mutationError!;
    }
    removedUserIds.add(userId);
    _members?.removeWhere((member) => member.userId == userId);
  }
}

class FakeInviteRepository implements InviteRepository {
  FakeInviteRepository({this.acceptedFundId = 'fund-a', this.onAccept});

  static const testToken = '11111111-1111-4111-8111-111111111111';

  final String acceptedFundId;
  final void Function(String token)? onAccept;
  final List<Invite> invites = [];
  String? lastEmail;
  MemberRole? lastRole;
  String? lastCancelledId;
  String? lastToken;
  int _nextId = 0;

  @override
  Future<List<Invite>> getPendingInvites({required String fundId}) async {
    return List.unmodifiable(
      invites.where((invite) => invite.fundId == fundId && !invite.isAccepted),
    );
  }

  @override
  Future<Invite> createInvite({
    required String fundId,
    required String email,
    required MemberRole role,
  }) async {
    lastEmail = email;
    lastRole = role;
    final invite = Invite(
      id: 'invite-${_nextId++}',
      fundId: fundId,
      email: email,
      role: role,
      token: testToken,
      createdAt: DateTime(2026, 1, 1),
      expiresAt: DateTime(2100, 1, 1),
    );
    invites.insert(0, invite);
    return invite;
  }

  @override
  Future<void> cancelInvite({
    required String fundId,
    required String inviteId,
  }) async {
    lastCancelledId = inviteId;
    invites.removeWhere((invite) => invite.id == inviteId);
  }

  @override
  Future<String> acceptInvite({required String token}) async {
    lastToken = token;
    onAccept?.call(token);
    return acceptedFundId;
  }
}
