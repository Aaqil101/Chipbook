import 'package:material_ui/material_ui.dart';

import '../domain/home_dashboard.dart';
import '../domain/money.dart';
import '../models/fund.dart';

/// Home destination: a dashboard of the user's funds with live figures.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.dashboard,
    required this.username,
    this.archivedFunds = const <Fund>[],
    this.activeFundId,
    this.onOpenFund,
    this.onCreateFund,
    this.onRedeemInvite,
    this.onRestoreFund,
    this.onRestoreArchivedFund,
  });

  /// Per-fund figures, built from one bulk entry read.
  final HomeDashboard dashboard;

  /// Shown in the greeting.
  final String username;

  /// Archived funds, newest first.
  final List<Fund> archivedFunds;

  /// The fund currently shown in the Ledger tab.
  final String? activeFundId;

  final ValueChanged<Fund>? onOpenFund;
  final VoidCallback? onCreateFund;
  final VoidCallback? onRedeemInvite;

  /// Restores an archived fund from its own row.
  final ValueChanged<Fund>? onRestoreFund;

  /// Opens the chooser when several funds are archived.
  final VoidCallback? onRestoreArchivedFund;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Funds')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text(
            'Hi, $username',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dashboard.isEmpty
                ? 'Start a shared ledger for your group.'
                : 'Here is where your funds stand today.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _Overview(
            activeCount: dashboard.funds.length,
            archivedCount: archivedFunds.length,
            pendingCount: dashboard.pendingCount,
          ),
          const SizedBox(height: 24),
          if (dashboard.isEmpty)
            _EmptyFunds(onCreateFund: onCreateFund)
          else ...[
            _SectionHeader(
              title: 'Your funds',
              count: dashboard.funds.length,
            ),
            const SizedBox(height: 8),
            for (final snapshot in dashboard.funds)
              _FundCard(
                snapshot: snapshot,
                isActive: snapshot.fund.id == activeFundId,
                onTap: onOpenFund == null
                    ? null
                    : () => onOpenFund!(snapshot.fund),
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
            if (onRestoreArchivedFund != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onRestoreArchivedFund,
                  icon: const Icon(Icons.unarchive_outlined),
                  label: const Text('Restore an archived fund'),
                ),
              ),
            ],
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

/// Active, archived, and pending counts. No money is aggregated here.
class _Overview extends StatelessWidget {
  const _Overview({
    required this.activeCount,
    required this.archivedCount,
    required this.pendingCount,
  });

  final int activeCount;
  final int archivedCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Active',
            value: '$activeCount',
            icon: Icons.menu_book_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Archived funds',
            value: '$archivedCount',
            icon: Icons.archive_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Pending',
            value: '$pendingCount',
            icon: Icons.pending_actions_outlined,
            highlight: pendingCount > 0,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = highlight ? scheme.primary : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FundCard extends StatelessWidget {
  const _FundCard({
    required this.snapshot,
    required this.isActive,
    this.onTap,
  });

  final FundSnapshot snapshot;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fund = snapshot.fund;
    final currency = fund.defaultCurrency;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        isThreeLine: true,
        leading: Icon(
          isActive ? Icons.check_circle : Icons.menu_book_outlined,
          color: isActive ? scheme.primary : null,
        ),
        title: Text(fund.name, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_detail(fund)),
              const SizedBox(height: 4),
              Text(
                'Raised ${Money.format(snapshot.raisedMinor, currency: currency)}'
                ' · Paid ${Money.format(snapshot.paidOutMinor, currency: currency)}'
                ' · Balance ${Money.format(snapshot.balanceMinor, currency: currency)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              if (snapshot.pendingCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${snapshot.pendingCount} pending approval',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 32),
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
