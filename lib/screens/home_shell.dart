import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../domain/fund_permissions.dart';
import '../domain/home_dashboard.dart';
import '../models/fund.dart';
import '../repositories/invite_repository.dart';
import '../repositories/membership_repository.dart';
import '../state/ledger_controller.dart';
import '../state/theme_controller.dart';
import 'entries_page.dart';
import 'home_page.dart';
import 'members_page.dart';
import 'settings_page.dart';

/// Signed-in home with the Home, Ledger, Members, and Settings destinations.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.themes,
    required this.ledger,
    required this.fund,
    required this.funds,
    required this.dashboard,
    required this.currentUserId,
    required this.currentUsername,
    required this.membershipRepository,
    required this.inviteRepository,
    this.archivedFunds = const <Fund>[],
    this.permissions,
    this.currentUserEmail,
    this.currentUserProvider,
    this.onRenameUsername,
    this.onOpenFund,
    this.onCreateFund,
    this.onRedeemInvite,
    this.onManageFund,
    this.onRestoreFund,
    this.onRestoreArchivedFund,
    this.onAccessChanged,
    this.onSignOut,
  });

  final ThemeController themes;
  final LedgerController ledger;
  final Fund fund;
  final List<Fund> funds;

  /// Per-fund figures for the Home tab.
  final HomeDashboard dashboard;
  final List<Fund> archivedFunds;
  final String? currentUserId;
  final String currentUsername;
  final String? currentUserEmail;
  final String? currentUserProvider;
  final Future<void> Function(String username)? onRenameUsername;
  final MembershipRepository membershipRepository;
  final InviteRepository inviteRepository;

  /// The signed-in user's role in [fund], or null until it is known.
  final FundPermissions? permissions;

  /// Makes [fund] active before the shell shows the Ledger tab.
  final Future<void> Function(Fund fund)? onOpenFund;

  final VoidCallback? onCreateFund;
  final VoidCallback? onRedeemInvite;
  final VoidCallback? onManageFund;
  final ValueChanged<Fund>? onRestoreFund;

  /// Opens the chooser when more than one fund is archived.
  final VoidCallback? onRestoreArchivedFund;

  /// Reloads the signed-in user's role after it may have changed.
  final VoidCallback? onAccessChanged;
  final Future<void> Function()? onSignOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

enum _HomeTab { home, ledger, members, settings }

class _HomeShellState extends State<HomeShell> {
  _HomeTab _tab = _HomeTab.home;

  Future<void> _openFund(Fund fund) async {
    final open = widget.onOpenFund;
    if (open != null) {
      await open(fund);
    }
    if (mounted) {
      setState(() => _tab = _HomeTab.ledger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = widget.permissions;

    return PopScope<Object?>(
      canPop: _tab == _HomeTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() => _tab = _HomeTab.home);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _tab.index,
          children: [
            HomePage(
              dashboard: widget.dashboard,
              username: widget.currentUsername,
              archivedFunds: widget.archivedFunds,
              activeFundId: widget.fund.id,
              onOpenFund: (fund) => unawaited(_openFund(fund)),
              onCreateFund: widget.onCreateFund,
              onRedeemInvite: widget.onRedeemInvite,
              onRestoreFund: widget.onRestoreFund,
              onRestoreArchivedFund: widget.onRestoreArchivedFund,
            ),
            EntriesPage(
              controller: widget.ledger,
              fund: widget.fund,
              permissions: permissions,
              onManageFund: widget.onManageFund,
            ),
            if (permissions == null)
              _MembersUnavailable(onRetry: widget.onAccessChanged)
            else
              MembersPage(
                key: ValueKey<String>('members-${widget.fund.id}'),
                fundId: widget.fund.id,
                fundName: widget.fund.name,
                currentUserId: widget.currentUserId,
                permissions: permissions,
                membershipRepository: widget.membershipRepository,
                inviteRepository: widget.inviteRepository,
                onAccessChanged: widget.onAccessChanged,
              ),
            ListenableBuilder(
              listenable: widget.themes,
              builder: (context, _) => SettingsPage(
                fund: widget.fund,
                username: widget.currentUsername,
                permissions: permissions,
                email: widget.currentUserEmail,
                provider: widget.currentUserProvider,
                themePreference: widget.themes.preference,
                onThemePreferenceChanged: (preference) =>
                    unawaited(widget.themes.setPreference(preference)),
                onRenameUsername: widget.onRenameUsername,
                onManageFund: widget.onManageFund,
                onSignOut: widget.onSignOut,
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (index) =>
              setState(() => _tab = _HomeTab.values[index]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Ledger',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group),
              label: 'Members',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown on the Members tab until the signed-in user's role is known.
class _MembersUnavailable extends StatelessWidget {
  const _MembersUnavailable({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final retry = onRetry;

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.group_off_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Members are unavailable',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your role in this fund could not be loaded.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (retry != null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: retry, child: const Text('Try again')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
