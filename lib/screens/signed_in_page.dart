import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../app_info.dart';
import '../auth/auth_controller.dart';
import '../models/fund.dart';
import '../repositories/entry_repository.dart';
import '../repositories/fund_repository.dart';
import '../repositories/invite_repository.dart';
import '../repositories/membership_repository.dart';
import '../state/fund_controller.dart';
import 'create_fund_dialog.dart';
import 'entries_page.dart';
import 'fund_settings_sheet.dart';
import 'members_page.dart';
import 'redeem_invite_dialog.dart';
import 'restore_fund_dialog.dart';

/// Signed-in shell: loads funds and shows the active fund's ledger.
class SignedInPage extends StatefulWidget {
  const SignedInPage({
    super.key,
    required this.auth,
    required this.fundRepository,
    required this.entryRepository,
    required this.membershipRepository,
    required this.inviteRepository,
  });

  final AuthController auth;
  final FundRepository fundRepository;
  final EntryRepository entryRepository;
  final MembershipRepository membershipRepository;
  final InviteRepository inviteRepository;

  @override
  State<SignedInPage> createState() => _SignedInPageState();
}

class _SignedInPageState extends State<SignedInPage> {
  late final FundController _funds;

  @override
  void initState() {
    super.initState();
    _funds = FundController(
      widget.fundRepository,
      widget.entryRepository,
      widget.membershipRepository,
      userId: widget.auth.userId,
    );
    unawaited(_funds.load());
  }

  @override
  void dispose() {
    _funds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _funds,
      builder: (context, _) {
        if (_funds.isLoading) {
          return _LoadingPage(onSignOut: widget.auth.signOut);
        }

        final error = _funds.error;
        if (error != null) {
          return _FundsErrorPage(
            message: error,
            onRetry: () => unawaited(_funds.load()),
            onSignOut: widget.auth.signOut,
          );
        }

        final fund = _funds.activeFund;
        final ledger = _funds.ledger;
        if (fund == null || ledger == null) {
          return _NoFundsPage(
            archivedFunds: _funds.archivedFunds,
            onCreateFund: () => unawaited(_createFund()),
            onRedeemInvite: () => unawaited(_redeemInvite()),
            onRestoreArchivedFund: () => unawaited(_restoreArchivedFund()),
            onSignOut: widget.auth.signOut,
          );
        }

        final permissions = _funds.permissions;
        return EntriesPage(
          controller: ledger,
          fundName: fund.name,
          permissions: permissions,
          funds: _funds.funds,
          onSelectFund: (fund) => unawaited(_selectFund(fund)),
          onCreateFund: () => unawaited(_createFund()),
          onRedeemInvite: () => unawaited(_redeemInvite()),
          onOpenMembers: permissions == null
              ? null
              : () => unawaited(_openMembers(fund)),
          onManageFund: (permissions?.canManageFund ?? false)
              ? () => unawaited(_manageFund(fund))
              : null,
          onSignOut: widget.auth.signOut,
        );
      },
    );
  }

  Future<void> _createFund() async {
    final draft = await showDialog<FundDraft>(
      context: context,
      builder: (_) => const CreateFundDialog(),
    );
    if (draft == null) {
      return;
    }

    try {
      await _funds.createFund(
        name: draft.name,
        defaultCurrency: draft.currency,
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _selectFund(Fund fund) async {
    try {
      await _funds.selectFund(fund);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _manageFund(Fund fund) async {
    final permissions = _funds.permissions;
    if (permissions == null || !permissions.canManageFund) {
      return;
    }

    final ledger = _funds.ledger;

    final action = await showModalBottomSheet<FundSettingsAction>(
      context: context,
      builder: (_) => FundSettingsSheet(
        fundName: fund.name,
        canDelete:
            ledger != null && !ledger.isLoading && ledger.summary.isEmpty,
        onRestoreArchived: _funds.archivedFunds.isEmpty
            ? null
            : () => unawaited(_restoreArchivedFund()),
      ),
    );
    if (action == null || !mounted) {
      return;
    }

    switch (action) {
      case FundSettingsAction.archive:
        if (!await confirmArchiveFund(context, fund.name) || !mounted) {
          return;
        }
        await _runFundAction(
          () => _funds.archiveFund(fund),
          success: '“${fund.name}” archived',
          restore: fund,
        );
      case FundSettingsAction.delete:
        if (!await confirmDeleteFund(context, fund.name) || !mounted) {
          return;
        }
        await _runFundAction(
          () => _funds.deleteFund(fund),
          success: '“${fund.name}” deleted',
        );
    }
  }

  Future<void> _runFundAction(
    Future<void> Function() action, {
    required String success,
    Fund? restore,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(success),
          action: restore == null
              ? null
              : SnackBarAction(
                  label: 'Restore',
                  onPressed: () => unawaited(_restoreFund(restore)),
                ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _restoreFund(Fund fund) async {
    try {
      await _funds.restoreFund(fund);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _restoreArchivedFund() async {
    final archived = _funds.archivedFunds;
    if (archived.isEmpty) {
      return;
    }

    final fund = await showDialog<Fund>(
      context: context,
      builder: (_) => RestoreFundDialog(funds: archived),
    );
    if (fund == null || !mounted) {
      return;
    }

    await _restoreFund(fund);
  }

  Future<void> _openMembers(Fund fund) async {
    final permissions = _funds.permissions;
    if (permissions == null) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MembersPage(
          fundId: fund.id,
          fundName: fund.name,
          currentUserId: widget.auth.userId,
          permissions: permissions,
          membershipRepository: widget.membershipRepository,
          inviteRepository: widget.inviteRepository,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    // The user's own role, or their access, may have changed.
    await _funds.load(preferFundId: fund.id);
  }

  Future<void> _redeemInvite() async {
    final token = await showDialog<String>(
      context: context,
      builder: (_) => const RedeemInviteDialog(),
    );
    if (token == null || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      final fundId = await widget.inviteRepository.acceptInvite(token: token);
      if (!mounted) {
        return;
      }
      await _funds.load(preferFundId: fundId);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('Invite accepted')));
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppInfo.name),
        actions: [_SignOutButton(onSignOut: onSignOut)],
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _FundsErrorPage extends StatelessWidget {
  const _FundsErrorPage({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppInfo.name),
        actions: [_SignOutButton(onSignOut: onSignOut)],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Could not load funds', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoFundsPage extends StatelessWidget {
  const _NoFundsPage({
    required this.archivedFunds,
    required this.onCreateFund,
    required this.onRedeemInvite,
    required this.onRestoreArchivedFund,
    required this.onSignOut,
  });

  final List<Fund> archivedFunds;
  final VoidCallback onCreateFund;
  final VoidCallback onRedeemInvite;
  final VoidCallback onRestoreArchivedFund;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasArchived = archivedFunds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppInfo.name),
        actions: [_SignOutButton(onSignOut: onSignOut)],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.savings_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                hasArchived ? 'No active funds' : 'No funds yet',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                hasArchived
                    ? 'Your funds are archived. Restore one, create a new '
                          'fund, or join one with an invite.'
                    : 'Create a fund to start a shared ledger, '
                          'or join one with an invite.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreateFund,
                icon: const Icon(Icons.add),
                label: const Text('Create a fund'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRedeemInvite,
                icon: const Icon(Icons.mail_outline),
                label: const Text('Redeem an invite'),
              ),
              if (hasArchived) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRestoreArchivedFund,
                  icon: const Icon(Icons.unarchive_outlined),
                  label: Text(
                    archivedFunds.length == 1
                        ? 'Restore an archived fund'
                        : 'Restore an archived fund '
                              '(${archivedFunds.length})',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onSignOut,
      tooltip: 'Sign out',
      icon: const Icon(Icons.logout),
    );
  }
}
