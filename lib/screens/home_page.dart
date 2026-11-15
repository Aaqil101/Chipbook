import 'package:material_ui/material_ui.dart';

import '../domain/money.dart';
import '../models/fund.dart';

/// Home destination: every fund the user can open, in one list.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.funds,
    this.archivedFunds = const <Fund>[],
    this.activeFundId,
    this.onOpenFund,
    this.onCreateFund,
    this.onRedeemInvite,
    this.onRestoreFund,
  });

  /// Active funds, oldest first.
  final List<Fund> funds;

  /// Archived funds, newest first.
  final List<Fund> archivedFunds;

  /// The fund currently shown in the Ledger tab.
  final String? activeFundId;

  final ValueChanged<Fund>? onOpenFund;
  final VoidCallback? onCreateFund;
  final VoidCallback? onRedeemInvite;

  /// Restores an archived fund.
  final ValueChanged<Fund>? onRestoreFund;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Funds')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if (funds.isEmpty)
            _EmptyFunds(onCreateFund: onCreateFund)
          else ...[
            _SectionHeader(title: 'Your funds', count: funds.length),
            const SizedBox(height: 8),
            for (final fund in funds)
              _FundTile(
                fund: fund,
                isActive: fund.id == activeFundId,
                onTap: onOpenFund == null ? null : () => onOpenFund!(fund),
              ),
          ],
          if (archivedFunds.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: 'Archived', count: archivedFunds.length),
            const SizedBox(height: 8),
            for (final fund in archivedFunds)
              _ArchivedFundTile(
                fund: fund,
                onRestore: onRestoreFund == null
                    ? null
                    : () => onRestoreFund!(fund),
              ),
          ],
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRedeemInvite,
              icon: const Icon(Icons.mail_outline),
              label: const Text('Redeem an invite'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a fund to open its ledger.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      floatingActionButton: onCreateFund == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'new-fund',
              onPressed: onCreateFund,
              icon: const Icon(Icons.add),
              label: const Text('New fund'),
            ),
    );
  }
}

class _FundTile extends StatelessWidget {
  const _FundTile({required this.fund, required this.isActive, this.onTap});

  final Fund fund;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isActive ? Icons.check_circle : Icons.menu_book_outlined,
          color: isActive ? theme.colorScheme.primary : null,
        ),
        title: Text(fund.name, overflow: TextOverflow.ellipsis),
        subtitle: Text(_detail(fund)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  static String _detail(Fund fund) {
    final parts = <String>[fund.defaultCurrency, fund.cadence.label];
    final target = fund.targetMinor;
    if (target != null) {
      parts.add(
        '${Money.format(target, currency: fund.defaultCurrency)} target',
      );
    }
    return parts.join(' · ');
  }
}

class _ArchivedFundTile extends StatelessWidget {
  const _ArchivedFundTile({required this.fund, this.onRestore});

  final Fund fund;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.archive_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(fund.name, overflow: TextOverflow.ellipsis),
        subtitle: Text('Archived · ${fund.defaultCurrency}'),
        trailing: onRestore == null
            ? null
            : IconButton(
                onPressed: onRestore,
                tooltip: 'Restore ${fund.name}',
                icon: const Icon(Icons.unarchive_outlined),
              ),
      ),
    );
  }
}

class _EmptyFunds extends StatelessWidget {
  const _EmptyFunds({this.onCreateFund});

  final VoidCallback? onCreateFund;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.create_new_folder_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text('No funds yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Create a fund to start a shared ledger, or join one with an '
            'invite.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (onCreateFund != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreateFund,
              icon: const Icon(Icons.add),
              label: const Text('Create a fund'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
