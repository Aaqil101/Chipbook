import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../app_info.dart';
import '../auth/auth_controller.dart';
import '../models/fund.dart';
import '../repositories/entry_repository.dart';
import '../repositories/fund_repository.dart';
import '../state/fund_controller.dart';
import 'create_fund_dialog.dart';
import 'entries_page.dart';

/// Signed-in shell: loads funds and shows the active fund's ledger.
class SignedInPage extends StatefulWidget {
  const SignedInPage({
    super.key,
    required this.auth,
    required this.fundRepository,
    required this.entryRepository,
  });

  final AuthController auth;
  final FundRepository fundRepository;
  final EntryRepository entryRepository;

  @override
  State<SignedInPage> createState() => _SignedInPageState();
}

class _SignedInPageState extends State<SignedInPage> {
  late final FundController _funds;

  @override
  void initState() {
    super.initState();
    _funds = FundController(widget.fundRepository, widget.entryRepository);
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
        if (error != null && _funds.funds.isEmpty) {
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
            onCreateFund: () => unawaited(_createFund()),
            onSignOut: widget.auth.signOut,
          );
        }

        return EntriesPage(
          controller: ledger,
          fundName: fund.name,
          funds: _funds.funds,
          onSelectFund: (fund) => unawaited(_selectFund(fund)),
          onCreateFund: () => unawaited(_createFund()),
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
  const _NoFundsPage({required this.onCreateFund, required this.onSignOut});

  final VoidCallback onCreateFund;
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
                Icons.savings_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('No funds yet', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Create a fund to start a shared ledger.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreateFund,
                icon: const Icon(Icons.add),
                label: const Text('Create a fund'),
              ),
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
