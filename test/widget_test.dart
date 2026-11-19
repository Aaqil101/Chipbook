import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:chipbook/app_info.dart';
import 'package:chipbook/auth/auth_controller.dart';
import 'package:chipbook/auth/auth_service.dart';
import 'package:chipbook/main.dart';
import 'package:chipbook/models/entry.dart';
import 'package:chipbook/models/fund.dart';
import 'package:chipbook/models/fund_cadence.dart';
import 'package:chipbook/models/invite.dart';
import 'package:chipbook/models/member_role.dart';
import 'package:chipbook/models/membership.dart';
import 'package:chipbook/models/profile.dart';
import 'package:chipbook/repositories/entry_repository.dart';
import 'package:chipbook/repositories/fund_repository.dart';
import 'package:chipbook/repositories/invite_repository.dart';
import 'package:chipbook/repositories/membership_repository.dart';
import 'package:chipbook/repositories/preference_store.dart';
import 'package:chipbook/repositories/profile_repository.dart';
import 'package:chipbook/state/theme_controller.dart';

void main() {
  testWidgets('signed-out users land on the sign-in form', (tester) async {
    final fake = FakeAuthService();
    final auth = AuthController(fake);
    addTearDown(fake.dispose);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      ChipbookApp(
        themes: _themes(),
        auth: auth,
        fundRepository: FakeFundRepository(),
        entryRepository: InMemoryEntryRepository(),
        membershipRepository: FakeMembershipRepository(),
        inviteRepository: FakeInviteRepository(),
        profileRepository: FakeProfileRepository(),
      ),
    );

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Send magic link'), findsOneWidget);
    expect(find.text('No entries yet'), findsNothing);
  });

  testWidgets('home lists funds and opens a ledger', (tester) async {
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      openLedger: false,
    );

    expect(find.text('Funds'), findsOneWidget);
    expect(find.text('Trip fund'), findsOneWidget);
    expect(find.text('No entries yet'), findsNothing);

    await tester.tap(find.text('Trip fund'));
    await tester.pumpAndSettle();

    expect(find.text('No entries yet'), findsOneWidget);
    expect(find.text('Add entry'), findsOneWidget);
  });

  testWidgets('bottom navigation exposes home, ledger, members, and settings', (
    tester,
  ) async {
    final memberships = FakeMembershipRepository(
      members: [_membership('user-1', 'ada', MemberRole.organizer)],
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
      openLedger: false,
    );

    final navigation = find.byType(NavigationBar);
    expect(navigation, findsOneWidget);
    for (final label in ['Home', 'Ledger', 'Members', 'Settings']) {
      expect(
        find.descendant(of: navigation, matching: find.text(label)),
        findsOneWidget,
      );
    }

    expect(find.text('Funds'), findsOneWidget);

    await _openTab(tester, 'Ledger');
    expect(find.text('No entries yet'), findsOneWidget);

    await _openMembers(tester);
    expect(find.text('People with access to this ledger.'), findsOneWidget);

    await _openSettings(tester);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Current fund'), findsOneWidget);
  });

  testWidgets('settings opens the about page', (tester) async {
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      openLedger: false,
    );

    await _openSettings(tester);
    final about = find.text('About ${AppInfo.name}');
    await tester.scrollUntilVisible(about, 200);
    await tester.pumpAndSettle();
    await tester.tap(about);
    await tester.pumpAndSettle();

    expect(find.text(AppInfo.name), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('Open source licenses'), findsOneWidget);
  });

  testWidgets('the members tab follows the active fund', (tester) async {
    final memberships = FakeMembershipRepository(
      membersByFund: {
        'fund-a': [_membership('user-1', 'ada', MemberRole.organizer)],
        'fund-b': [
          _membership('user-1', 'ada', MemberRole.organizer),
          _membership('user-2', 'grace', MemberRole.member, fundId: 'fund-b'),
        ],
      },
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund'), _fund('fund-b', 'Gift fund')],
      memberships: memberships,
      openLedger: false,
    );

    await _openMembers(tester);
    expect(find.text('Trip fund'), findsOneWidget);
    expect(find.text('grace'), findsNothing);

    await _openTab(tester, 'Home');
    await tester.tap(find.text('Gift fund'));
    await tester.pumpAndSettle();

    await _openMembers(tester);
    expect(find.text('Gift fund'), findsOneWidget);
    expect(find.text('grace'), findsOneWidget);
  });

  testWidgets('changing your own role refreshes ledger permissions', (
    tester,
  ) async {
    final memberships = FakeMembershipRepository(
      members: [
        _membership('user-1', 'ada', MemberRole.organizer),
        _membership('user-2', 'grace', MemberRole.organizer),
      ],
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
    );

    await _openMembers(tester);
    await tester.tap(find.byTooltip('Manage ada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change to Observer'));
    await tester.pumpAndSettle();

    expect(memberships.roleChanges, [MemberRole.observer]);

    await _openTab(tester, 'Ledger');
    expect(find.text('Add entry'), findsNothing);
    expect(find.text('No entries yet'), findsOneWidget);
  });

  testWidgets('back from another tab returns home', (tester) async {
    final memberships = FakeMembershipRepository(
      members: [_membership('user-1', 'ada', MemberRole.organizer)],
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
    );

    await _openSettings(tester);
    expect(find.text('Account'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Funds'), findsOneWidget);
    expect(find.text('Trip fund'), findsOneWidget);
  });

  testWidgets('home shows each fund in its own currency', (tester) async {
    final entries = InMemoryEntryRepository();
    await entries.add(
      _entry(id: 'usd', amountMinor: 2500, status: EntryStatus.approved),
    );
    await entries.add(
      _entry(
        id: 'jpy',
        fundId: 'fund-b',
        amountMinor: 1000,
        currency: 'JPY',
        status: EntryStatus.approved,
      ),
    );
    await entries.add(
      _entry(id: 'waiting', amountMinor: 300, status: EntryStatus.pending),
    );

    await _pumpSignedIn(
      tester,
      funds: [
        _fund('fund-a', 'Trip fund'),
        _fund('fund-b', 'Class fees', currency: 'JPY'),
      ],
      entries: entries,
      openLedger: false,
    );

    expect(find.text('Hi, ada'), findsOneWidget);
    expect(find.textContaining('Raised USD 25.00'), findsOneWidget);
    expect(find.textContaining('Raised JPY 1,000'), findsOneWidget);
    expect(find.text('1 pending approval'), findsOneWidget);
  });

  testWidgets('home lists archived funds with a restore action', (
    tester,
  ) async {
    final fundRepository = FakeFundRepository(
      funds: [
        _fund('fund-a', 'Trip fund'),
        _fund('fund-b', 'Old fund', archivedAt: DateTime(2026, 2, 1)),
      ],
    );
    await _pumpSignedIn(
      tester,
      fundRepository: fundRepository,
      openLedger: false,
    );

    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('Old fund'), findsOneWidget);

    final restore = find.byTooltip('Restore Old fund');
    await tester.ensureVisible(restore);
    await tester.pumpAndSettle();
    await tester.tap(restore);
    await tester.pumpAndSettle();

    expect(
      fundRepository.funds.firstWhere((fund) => fund.id == 'fund-b').isArchived,
      isFalse,
    );
    expect(find.text('Old fund'), findsOneWidget);
  });

  testWidgets('users without funds are prompted to create one', (tester) async {
    await _pumpSignedIn(tester);

    expect(find.text('No funds yet'), findsOneWidget);
    expect(find.text('Create a fund'), findsOneWidget);
  });

  testWidgets('creating a fund adds it to the home list', (tester) async {
    await _pumpSignedIn(tester);

    await tester.tap(find.text('Create a fund'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Trip fund');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Trip fund'), findsOneWidget);

    await tester.tap(find.text('Trip fund'));
    await tester.pumpAndSettle();

    expect(find.text('No entries yet'), findsOneWidget);
  });

  testWidgets('sending a magic link shows confirmation', (tester) async {
    final fake = FakeAuthService();
    final auth = AuthController(fake);
    addTearDown(fake.dispose);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      ChipbookApp(
        themes: _themes(),
        auth: auth,
        fundRepository: FakeFundRepository(),
        entryRepository: InMemoryEntryRepository(),
        membershipRepository: FakeMembershipRepository(),
        inviteRepository: FakeInviteRepository(),
        profileRepository: FakeProfileRepository(),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'ada@example.com');
    await tester.tap(find.text('Send magic link'));
    await tester.pumpAndSettle();

    expect(fake.lastEmail, 'ada@example.com');
    expect(find.text('Check your email'), findsOneWidget);
  });

  testWidgets('signed-in users choose a username before the app', (
    tester,
  ) async {
    final profiles = FakeProfileRepository();
    await _pumpSignedIn(
      tester,
      profiles: profiles,
      funds: [_fund('fund-a', 'Trip fund')],
      openLedger: false,
    );

    expect(find.text('Choose a username'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Ada');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Use lowercase letters only'), findsOneWidget);
    expect(profiles.saveCount, 0);

    await tester.enterText(find.byType(TextFormField), 'ada_l');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(profiles.profile?.username, 'ada_l');
    expect(find.text('Funds'), findsOneWidget);
  });

  testWidgets('settings shows the username and renames it', (tester) async {
    final profiles = FakeProfileRepository(profile: _profile('user-1', 'ada'));
    await _pumpSignedIn(
      tester,
      profiles: profiles,
      funds: [_fund('fund-a', 'Trip fund')],
    );

    await _openSettings(tester);
    expect(find.text('@ada'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('Signed in with an email link'), findsOneWidget);

    await tester.tap(find.byTooltip('Change username'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'ada_l');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(profiles.profile?.username, 'ada_l');
    expect(find.text('@ada_l'), findsOneWidget);
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

    expect(find.text('Approve entry?'), findsOneWidget);
    expect(find.textContaining('cannot be deleted'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    expect(find.text('Approve'), findsNothing);
    expect(find.text('Pending'), findsNothing);
    expect(find.text('USD 12.50'), findsNWidgets(2));
  });

  testWidgets('cancelling approval leaves the entry pending', (tester) async {
    final entries = InMemoryEntryRepository();
    await entries.add(_entry(id: 'pending', amountMinor: 1250));

    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      entries: entries,
    );

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('USD 0.00'), findsOneWidget);

    final stored = await entries.getAll(fundId: 'fund-a');
    expect(stored.single.status, EntryStatus.pending);
  });

  testWidgets('organizers delete a pending entry after confirming', (
    tester,
  ) async {
    final entries = InMemoryEntryRepository();
    await entries.add(_entry(id: 'pending', amountMinor: 1250));

    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      entries: entries,
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete pending entry?'), findsOneWidget);
    expect(find.text('USD 12.50'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No entries yet'), findsOneWidget);
    expect(await entries.getAll(fundId: 'fund-a'), isEmpty);
  });

  testWidgets('cancelling a pending delete keeps the entry', (tester) async {
    final entries = InMemoryEntryRepository();
    await entries.add(_entry(id: 'pending', amountMinor: 1250));

    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      entries: entries,
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(await entries.getAll(fundId: 'fund-a'), hasLength(1));
  });

  testWidgets('approved entries have no delete control', (tester) async {
    final entries = InMemoryEntryRepository();
    await entries.add(
      _entry(id: 'approved', amountMinor: 5000, status: EntryStatus.approved),
    );

    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      entries: entries,
    );

    expect(find.text('Reverse'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('members see no approve, reverse, or delete controls', (
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
      role: MemberRole.member,
    );

    expect(find.text('Approve'), findsNothing);
    expect(find.text('Reverse'), findsNothing);
    expect(find.text('Delete'), findsNothing);
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
    expect(find.text('Delete'), findsNothing);
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

    await _openTab(tester, 'Home');
    await tester.tap(find.text('Gift fund'));
    await tester.pumpAndSettle();

    expect(find.text('Gift fund'), findsOneWidget);
    expect(find.text('Grace'), findsOneWidget);
    expect(find.text('USD 50.00'), findsNWidgets(2));
    expect(find.text('Reverse'), findsOneWidget);
  });

  testWidgets('signing out returns to the sign-in form', (tester) async {
    await _pumpSignedIn(tester, funds: [_fund('fund-a', 'Trip fund')]);

    await _openSettings(tester);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Send magic link'), findsOneWidget);
    expect(find.text('Funds'), findsNothing);
  });

  testWidgets('members page shows friendly role labels', (tester) async {
    final memberships = FakeMembershipRepository(
      members: [
        _membership('user-1', 'ada', MemberRole.organizer),
        _membership('user-2', 'grace', MemberRole.member),
        _membership('user-3', 'linus', MemberRole.observer),
      ],
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
    );

    await _openMembers(tester);

    expect(find.text('ada (you)'), findsOneWidget);
    expect(find.text('grace'), findsOneWidget);
    expect(find.text('linus'), findsOneWidget);
    expect(find.text('Organizer'), findsOneWidget);
    expect(find.text('Member'), findsOneWidget);
    expect(find.text('Observer'), findsOneWidget);
    expect(find.text('Invite'), findsOneWidget);
  });

  testWidgets('organizers create an invite for a chosen role', (tester) async {
    final memberships = FakeMembershipRepository(
      members: [_membership('user-1', 'ada', MemberRole.organizer)],
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
        _membership('user-1', 'ada', MemberRole.member),
        _membership('user-2', 'grace', MemberRole.organizer),
      ],
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
    );

    await _openMembers(tester);

    expect(find.text('Invite'), findsNothing);
    expect(find.byTooltip('Manage grace'), findsNothing);
    expect(find.text('Member'), findsOneWidget);
    expect(find.text('Organizer'), findsOneWidget);
  });

  testWidgets('the last organizer cannot be demoted or removed', (
    tester,
  ) async {
    final memberships = FakeMembershipRepository(
      members: [_membership('user-1', 'ada', MemberRole.organizer)],
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
    );

    await _openMembers(tester);

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byTooltip('Manage ada'), findsNothing);
    expect(find.text('Invite'), findsOneWidget);
  });

  testWidgets('organizers remove a member when another organizer remains', (
    tester,
  ) async {
    final memberships = FakeMembershipRepository(
      members: [
        _membership('user-1', 'ada', MemberRole.organizer),
        _membership('user-2', 'grace', MemberRole.organizer),
      ],
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
    );

    await _openMembers(tester);
    await tester.tap(find.byTooltip('Manage grace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from fund'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(memberships.removedUserIds, ['user-2']);
    expect(find.text('grace'), findsNothing);
  });

  testWidgets('the database last-organizer guard is surfaced', (tester) async {
    final memberships = FakeMembershipRepository(
      members: [
        _membership('user-1', 'ada', MemberRole.organizer),
        _membership('user-2', 'grace', MemberRole.organizer),
      ],
      mutationError: Exception('a fund must keep at least one organizer'),
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      memberships: memberships,
    );

    await _openMembers(tester);
    await tester.tap(find.byTooltip('Manage grace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from fund'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.textContaining('at least one organizer'), findsOneWidget);
    expect(find.text('grace'), findsOneWidget);
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
      members: [_membership('user-1', 'ada', MemberRole.organizer)],
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
    expect(find.text('Invite accepted'), findsOneWidget);
    expect(find.text('Trip fund'), findsOneWidget);

    await tester.tap(find.text('Trip fund'));
    await tester.pumpAndSettle();
    expect(find.text('No entries yet'), findsOneWidget);
  });

  testWidgets('add-entry form records in the fund currency', (tester) async {
    await _pumpSignedIn(tester, funds: [_fund('fund-a', 'Trip fund')]);

    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();

    expect(find.text('Recorded in USD, the fund currency'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '1500');
    await tester.enterText(fields.at(1), 'Grace');
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('USD 1,500.00'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    expect(find.text('USD 1,500.00'), findsNWidgets(2));
  });

  testWidgets('creating a fund picks its default currency', (tester) async {
    final fundRepository = FakeFundRepository();
    await _pumpSignedIn(tester, fundRepository: fundRepository);

    await tester.tap(find.text('Create a fund'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Travel fund');
    await tester.tap(find.text('USD · US Dollar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('currency-search')),
      'uruguayan',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('UYU · Uruguayan Peso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(fundRepository.funds.single.defaultCurrency, 'UYU');
    expect(find.text('Travel fund'), findsOneWidget);

    await tester.tap(find.text('Travel fund'));
    await tester.pumpAndSettle();
    expect(find.text('No entries yet'), findsOneWidget);
  });

  testWidgets('organizers record a payout that lowers the balance', (
    tester,
  ) async {
    final entries = InMemoryEntryRepository();
    await entries.add(
      _entry(id: 'in', amountMinor: 5000, status: EntryStatus.approved),
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Class fund')],
      entries: entries,
    );

    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payout'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '20');
    await tester.enterText(fields.at(1), 'Teacher');
    await tester.enterText(fields.at(2), 'Monthly class fee');
    await tester.tap(find.widgetWithText(FilledButton, 'Record payout'));
    await tester.pumpAndSettle();

    expect(find.text('USD 30.00'), findsOneWidget);
    expect(find.text('-USD 20.00'), findsOneWidget);
    expect(find.text('Payout'), findsOneWidget);
  });

  testWidgets('a payout needs a reason', (tester) async {
    await _pumpSignedIn(tester, funds: [_fund('fund-a', 'Class fund')]);

    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payout'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '20');
    await tester.enterText(fields.at(1), 'Teacher');
    final save = find.widgetWithText(FilledButton, 'Record payout');
    await tester.ensureVisible(save);
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Enter a reason for the payout'), findsOneWidget);
    expect(find.text('Record payout'), findsWidgets);
  });

  testWidgets('a payout over the balance warns but is allowed', (tester) async {
    final entries = InMemoryEntryRepository();
    await entries.add(
      _entry(id: 'in', amountMinor: 5000, status: EntryStatus.approved),
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Class fund')],
      entries: entries,
    );

    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payout'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '80');
    await tester.pumpAndSettle();

    expect(find.textContaining('balance will go negative'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '40');
    await tester.pumpAndSettle();

    expect(find.textContaining('balance will go negative'), findsNothing);
  });

  testWidgets('members cannot record payouts', (tester) async {
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Class fund')],
      role: MemberRole.member,
    );

    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();

    expect(find.text('Payout'), findsNothing);
    expect(find.text('Contributor name'), findsOneWidget);
  });

  testWidgets('organizers archive a fund and restore it', (tester) async {
    final fundRepository = FakeFundRepository(
      funds: [_fund('fund-a', 'Class fees')],
    );
    await _pumpSignedIn(tester, fundRepository: fundRepository);

    await _openFundSettings(tester);
    await tester.tap(find.text('Archive fund'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
    await tester.pumpAndSettle();

    expect(fundRepository.funds.single.isArchived, isTrue);
    expect(find.text('No active funds'), findsOneWidget);

    await tester.tap(find.text('Restore an archived fund'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class fees'));
    await tester.pumpAndSettle();

    expect(fundRepository.funds.single.isArchived, isFalse);
    expect(find.text('Class fees'), findsOneWidget);

    await tester.tap(find.text('Class fees'));
    await tester.pumpAndSettle();
    expect(find.text('No entries yet'), findsOneWidget);
  });

  testWidgets('a fund with entries can only be archived', (tester) async {
    final entries = InMemoryEntryRepository();
    await entries.add(
      _entry(id: 'approved', amountMinor: 5000, status: EntryStatus.approved),
    );
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Class fees')],
      entries: entries,
    );

    await _openFundSettings(tester);

    expect(
      find.text('Only a fund with no entries can be deleted'),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete fund'));
    await tester.pumpAndSettle();

    expect(find.text('Delete “Class fees”?'), findsNothing);
  });

  testWidgets('organizers delete an empty fund', (tester) async {
    final fundRepository = FakeFundRepository(
      funds: [_fund('fund-a', 'Class fees')],
    );
    await _pumpSignedIn(tester, fundRepository: fundRepository);

    await _openFundSettings(tester);
    await tester.tap(find.text('Delete fund'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(fundRepository.funds, isEmpty);
    expect(find.text('No funds yet'), findsOneWidget);
  });

  testWidgets('members cannot archive or delete a fund', (tester) async {
    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Class fees')],
      role: MemberRole.member,
    );

    expect(find.byTooltip('Fund settings'), findsNothing);

    await _openSettings(tester);
    expect(find.text('Manage fund'), findsNothing);
    expect(find.text('Archive fund'), findsNothing);
    expect(find.text('Delete fund'), findsNothing);
  });

  testWidgets('creating a monthly fund stores its cadence and target', (
    tester,
  ) async {
    final fundRepository = FakeFundRepository();
    await _pumpSignedIn(tester, fundRepository: fundRepository);

    await tester.tap(find.text('Create a fund'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Class fees');
    await _chooseCadence(tester, 'Monthly');
    await tester.enterText(find.byType(TextFormField).at(1), '500');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    final fund = fundRepository.funds.single;
    expect(fund.cadence, FundCadence.monthly);
    expect(fund.targetMinor, 50000);
    expect(find.text('Class fees'), findsOneWidget);

    await tester.tap(find.text('Class fees'));
    await tester.pumpAndSettle();

    expect(find.text('This month'), findsOneWidget);
    expect(find.text('of USD 500.00 · 0% of target'), findsOneWidget);
  });

  testWidgets('organizers change the timing and target from fund settings', (
    tester,
  ) async {
    final fundRepository = FakeFundRepository(
      funds: [_fund('fund-a', 'Class fees')],
    );
    await _pumpSignedIn(tester, fundRepository: fundRepository);

    await _openFundSettings(tester);
    expect(find.text('One-off · no target'), findsOneWidget);

    await tester.tap(find.text('Timing and target'));
    await tester.pumpAndSettle();

    await _chooseCadence(tester, 'Monthly');
    await tester.enterText(find.byType(TextFormField), '500');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final fund = fundRepository.funds.single;
    expect(fund.cadence, FundCadence.monthly);
    expect(fund.targetMinor, 50000);

    await _openTab(tester, 'Ledger');
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('of USD 500.00 · 0% of target'), findsOneWidget);
  });

  testWidgets('appearance selector repaints and saves the choice', (
    tester,
  ) async {
    final stored = <String, String>{};
    final themes = ThemeController(_FakePreferenceStore(stored));
    addTearDown(themes.dispose);

    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      themes: themes,
      openLedger: false,
    );

    await _openSettings(tester);
    final appearance = find.text('Appearance');
    await tester.scrollUntilVisible(appearance, 200);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);

    final dark = find.text('Dark');
    await tester.scrollUntilVisible(dark, 200);
    await tester.tap(dark);
    await tester.pumpAndSettle();

    expect(themes.themeMode, ThemeMode.dark);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.dark,
    );
    expect(stored[ThemeController.storageKey], 'dark');
  });

  testWidgets('system appearance follows the platform brightness live', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await _pumpSignedIn(
      tester,
      funds: [_fund('fund-a', 'Trip fund')],
      openLedger: false,
    );

    expect(
      Theme.of(tester.element(find.text('Funds'))).brightness,
      Brightness.dark,
    );

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Funds'))).brightness,
      Brightness.light,
    );
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
  FakeProfileRepository? profiles,
  ThemeController? themes,
  bool openLedger = true,
}) async {
  final fake = FakeAuthService(signedIn: true);
  final auth = AuthController(fake);
  addTearDown(fake.dispose);
  addTearDown(auth.dispose);

  final repository = fundRepository ?? FakeFundRepository(funds: funds);

  await tester.pumpWidget(
    ChipbookApp(
      themes: themes ?? _themes(),
      auth: auth,
      fundRepository: repository,
      entryRepository: entries ?? InMemoryEntryRepository(),
      membershipRepository: memberships ?? FakeMembershipRepository(role: role),
      inviteRepository: invites ?? FakeInviteRepository(),
      profileRepository:
          profiles ?? FakeProfileRepository(profile: _profile('user-1', 'ada')),
    ),
  );
  await tester.pumpAndSettle();

  if (!openLedger) {
    return;
  }

  Fund? firstActive;
  for (final fund in repository.funds) {
    if (!fund.isArchived) {
      firstActive = fund;
      break;
    }
  }
  if (firstActive == null) {
    return;
  }

  await tester.tap(find.widgetWithText(ListTile, firstActive.name).first);
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> _openMembers(WidgetTester tester) => _openTab(tester, 'Members');

Future<void> _openSettings(WidgetTester tester) => _openTab(tester, 'Settings');

Future<void> _openFundSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Fund settings'));
  await tester.pumpAndSettle();
}

Future<void> _chooseCadence(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<FundCadence>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Fund _fund(
  String id,
  String name, {
  String currency = 'USD',
  FundCadence cadence = FundCadence.oneOff,
  int? targetMinor,
  DateTime? archivedAt,
}) {
  return Fund(
    id: id,
    name: name,
    defaultCurrency: currency,
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    cadence: cadence,
    targetMinor: targetMinor,
    archivedAt: archivedAt,
  );
}

Profile _profile(String userId, String username) {
  return Profile(
    userId: userId,
    username: username,
    createdAt: DateTime(2026, 1, 1),
  );
}

Membership _membership(
  String userId,
  String username,
  MemberRole role, {
  String fundId = 'fund-a',
}) {
  return Membership(
    fundId: fundId,
    userId: userId,
    username: username,
    role: role,
    createdAt: DateTime(2026, 1, 1),
  );
}

Entry _entry({
  required String id,
  required int amountMinor,
  String fundId = 'fund-a',
  String currency = 'USD',
  EntryStatus status = EntryStatus.pending,
  EntryKind kind = EntryKind.contribution,
  String note = '',
}) {
  return Entry(
    id: id,
    fundId: fundId,
    amountMinor: amountMinor,
    currency: currency,
    contributorName: 'Ada',
    note: note,
    createdAt: DateTime(2026, 1, 1),
    status: status,
    kind: kind,
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
  String? get provider => _isSignedIn ? 'email' : null;

  @override
  Stream<bool> get signedInChanges => _changes.stream;

  @override
  Future<void> signInWithGoogle() async {}

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

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.profile});

  Profile? profile;
  int saveCount = 0;

  @override
  Future<Profile?> getProfile({required String userId}) async => profile;

  @override
  Future<Profile> saveUsername({
    required String userId,
    required String username,
  }) async {
    saveCount++;
    final saved = Profile(
      userId: userId,
      username: username,
      createdAt: DateTime(2026, 1, 1),
    );
    profile = saved;
    return saved;
  }
}

class FakeFundRepository implements FundRepository {
  FakeFundRepository({List<Fund>? funds}) : _funds = [...?funds];

  final List<Fund> _funds;
  int _nextId = 0;

  List<Fund> get funds => List.unmodifiable(_funds);

  void addFund(Fund fund) => _funds.add(fund);

  @override
  Future<List<Fund>> getFunds({bool includeArchived = false}) async {
    return List.unmodifiable(
      _funds.where((fund) => includeArchived || !fund.isArchived),
    );
  }

  @override
  Future<Fund> createFund({
    required String name,
    required String defaultCurrency,
    FundCadence cadence = FundCadence.oneOff,
    int? targetMinor,
  }) async {
    final fund = Fund(
      id: 'created-${_nextId++}',
      name: name,
      defaultCurrency: defaultCurrency,
      createdBy: 'user-1',
      createdAt: DateTime(2026, 1, 1),
      cadence: cadence,
      targetMinor: targetMinor,
    );
    _funds.add(fund);
    return fund;
  }

  @override
  Future<Fund> updateFundSettings({
    required String fundId,
    required FundCadence cadence,
    int? targetMinor,
  }) async {
    final index = _funds.indexWhere((fund) => fund.id == fundId);
    if (index == -1) {
      throw StateError('no such fund');
    }
    final updated = _funds[index].withSettings(
      cadence: cadence,
      targetMinor: targetMinor,
    );
    _funds[index] = updated;
    return updated;
  }

  @override
  Future<void> archiveFund(String fundId) async {
    _replace(fundId, archivedAt: DateTime(2026, 2, 1));
  }

  @override
  Future<void> restoreFund(String fundId) async {
    _replace(fundId, archivedAt: null);
  }

  @override
  Future<void> deleteFund(String fundId) async {
    _funds.removeWhere((fund) => fund.id == fundId);
  }

  void _replace(String fundId, {required DateTime? archivedAt}) {
    final index = _funds.indexWhere((fund) => fund.id == fundId);
    if (index == -1) {
      return;
    }
    final current = _funds[index];
    _funds[index] = Fund(
      id: current.id,
      name: current.name,
      defaultCurrency: current.defaultCurrency,
      createdBy: current.createdBy,
      createdAt: current.createdAt,
      cadence: current.cadence,
      targetMinor: current.targetMinor,
      archivedAt: archivedAt,
    );
  }
}

class FakeMembershipRepository implements MembershipRepository {
  FakeMembershipRepository({
    MemberRole role = MemberRole.organizer,
    List<Membership>? members,
    this.membersByFund,
    this.mutationError,
  }) : _defaultRole = role,
       _members = members == null ? null : [...members];

  final MemberRole _defaultRole;
  final List<Membership>? _members;
  final Map<String, List<Membership>>? membersByFund;
  final Object? mutationError;
  final List<MemberRole> roleChanges = [];
  final List<String> removedUserIds = [];

  @override
  Future<List<Membership>> getMemberships({required String fundId}) async {
    final byFund = membersByFund;
    if (byFund != null) {
      return List.unmodifiable(byFund[fundId] ?? const <Membership>[]);
    }
    final members = _members;
    if (members != null) {
      return List.unmodifiable(members);
    }
    return [
      Membership(
        fundId: fundId,
        userId: 'user-1',
        username: 'ada',
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
      username: current.username,
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

ThemeController _themes([Map<String, String>? values]) {
  return ThemeController(_FakePreferenceStore(values ?? <String, String>{}));
}

class _FakePreferenceStore implements PreferenceStore {
  _FakePreferenceStore(this.values);

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
