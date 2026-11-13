import 'package:material_ui/material_ui.dart';

import '../domain/fund_permissions.dart';
import '../domain/ledger.dart';
import '../domain/money.dart';
import '../models/entry.dart';
import '../models/fund.dart';
import '../state/ledger_controller.dart';
import 'add_entry_page.dart';
import 'period_progress_card.dart';
import 'reverse_entry_dialog.dart';

const _newFundAction = '__new_fund__';
const _redeemInviteAction = '__redeem_invite__';
const _fundSettingsAction = '__fund_settings__';

/// Shows the running total, approved entries, and pending entries.
class EntriesPage extends StatelessWidget {
  const EntriesPage({
    super.key,
    required this.controller,
    required this.fund,
    this.permissions,
    this.funds = const <Fund>[],
    this.onSelectFund,
    this.onCreateFund,
    this.onRedeemInvite,
    this.onOpenMembers,
    this.onManageFund,
    this.onSignOut,
  });

  final LedgerController controller;
  final Fund fund;

  /// The signed-in user's role in this fund, or null until it is known.
  final FundPermissions? permissions;

  final List<Fund> funds;
  final ValueChanged<Fund>? onSelectFund;
  final VoidCallback? onCreateFund;
  final VoidCallback? onRedeemInvite;
  final VoidCallback? onOpenMembers;

  /// Opens the archive and delete actions for the active fund.
  final VoidCallback? onManageFund;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    final signOut = onSignOut;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final summary = controller.summary;
        return Scaffold(
          appBar: AppBar(
            title: Text(fund.name, overflow: TextOverflow.ellipsis),
            actions: [
              if (onOpenMembers != null)
                IconButton(
                  onPressed: onOpenMembers,
                  tooltip: 'Members',
                  icon: const Icon(Icons.group_outlined),
                ),
              if (funds.isNotEmpty &&
                  (onSelectFund != null || onCreateFund != null))
                PopupMenuButton<String>(
                  tooltip: 'Switch fund',
                  icon: const Icon(Icons.swap_horiz),
                  onSelected: _handleFundSelection,
                  itemBuilder: (context) => [
                    for (final fund in funds)
                      PopupMenuItem<String>(
                        value: fund.id,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              child: fund.id == controller.fundId
                                  ? const Icon(Icons.check, size: 18)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                fund.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                    if (onRedeemInvite != null)
                      const PopupMenuItem<String>(
                        value: _redeemInviteAction,
                        child: Text('Redeem invite'),
                      ),
                    const PopupMenuItem<String>(
                      value: _newFundAction,
                      child: Text('New fund'),
                    ),
                    if (onManageFund != null) ...[
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: _fundSettingsAction,
                        child: Text('Fund settings'),
                      ),
                    ],
                  ],
                ),
              if (signOut != null)
                IconButton(
                  onPressed: signOut,
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout),
                ),
            ],
          ),
          body: _buildBody(context, summary),
          floatingActionButton: (permissions?.canAddEntry ?? false)
              ? FloatingActionButton.extended(
                  onPressed: () => _openAddEntry(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add entry'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, LedgerSummary summary) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final progress = PeriodProgressCard.shouldShow(fund)
        ? PeriodProgressCard(fund: fund, entries: controller.entries)
        : null;

    if (summary.isEmpty) {
      if (progress == null) {
        return const _EmptyState();
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [progress, const SizedBox(height: 24), const _EmptyState()],
      );
    }

    return _LedgerList(
      summary: summary,
      progress: progress,
      permissions: permissions,
      onApprove: (entry) => _approve(context, entry),
      onReverse: (entry) => _reverse(context, entry),
      onDelete: (entry) => _delete(context, entry),
    );
  }

  Future<void> _approve(BuildContext context, Entry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ApproveEntryDialog(entry: entry),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await controller.approve(entry.id);
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      _showError(context, error);
    }
  }

  Future<void> _delete(BuildContext context, Entry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteEntryDialog(entry: entry),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await controller.deletePending(entry.id);
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      _showError(context, error);
    }
  }

  Future<void> _reverse(BuildContext context, Entry entry) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => ReverseEntryDialog(entry: entry),
    );
    if (reason == null) {
      return;
    }

    try {
      await controller.reverse(target: entry, reason: reason);
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      _showError(context, error);
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> _openAddEntry(BuildContext context) {
    final permissions = this.permissions;
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AddEntryPage(
          controller: controller,
          canRecordPayout: permissions?.canRecordPayout ?? false,
        ),
      ),
    );
  }

  void _handleFundSelection(String value) {
    if (value == _newFundAction) {
      onCreateFund?.call();
      return;
    }
    if (value == _redeemInviteAction) {
      onRedeemInvite?.call();
      return;
    }
    if (value == _fundSettingsAction) {
      onManageFund?.call();
      return;
    }
    for (final fund in funds) {
      if (fund.id == value) {
        onSelectFund?.call(fund);
        return;
      }
    }
  }
}

class _LedgerList extends StatelessWidget {
  const _LedgerList({
    required this.summary,
    required this.progress,
    required this.permissions,
    required this.onApprove,
    required this.onReverse,
    required this.onDelete,
  });

  final LedgerSummary summary;

  /// Period progress shown above the balance, or null for a plain fund.
  final Widget? progress;

  final FundPermissions? permissions;
  final ValueChanged<Entry> onApprove;
  final ValueChanged<Entry> onReverse;
  final ValueChanged<Entry> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canApprove = permissions?.canApprove ?? false;
    final canReverse = permissions?.canReverse ?? false;
    final canDelete = permissions?.canDeleteEntry ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (progress != null) ...[progress!, const SizedBox(height: 16)],
        _TotalCard(summary: summary),
        const SizedBox(height: 24),
        if (summary.pending.isNotEmpty) ...[
          _SectionHeader(title: 'Pending', count: summary.pending.length),
          const SizedBox(height: 8),
          for (final entry in summary.pending)
            _EntryTile(
              entry: entry,
              onApprove: canApprove ? () => onApprove(entry) : null,
              onDelete: canDelete ? () => onDelete(entry) : null,
            ),
          const SizedBox(height: 24),
        ],
        _SectionHeader(title: 'Approved', count: summary.approved.length),
        const SizedBox(height: 8),
        if (summary.approved.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No approved entries yet.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          for (final entry in summary.approved)
            _EntryTile(
              entry: entry,
              isReversed: summary.reversedEntryIds.contains(entry.id),
              onReverse: canReverse && summary.canReverse(entry)
                  ? () => onReverse(entry)
                  : null,
            ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.summary});

  final LedgerSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onPrimaryContainer;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance',
              style: theme.textTheme.titleMedium?.copyWith(color: foreground),
            ),
            const SizedBox(height: 8),
            if (summary.totals.isEmpty)
              Text(
                'No approved totals yet',
                style: theme.textTheme.titleMedium?.copyWith(color: foreground),
              )
            else
              for (final total in summary.totals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Money.format(
                          total.balanceMinor,
                          currency: total.currency,
                        ),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${Money.format(total.raisedMinor, currency: total.currency)} '
                        'raised · '
                        '${Money.format(total.paidOutMinor, currency: total.currency)} '
                        'paid out',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: foreground,
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 4),
            Text(
              '${summary.approved.length} approved · '
              '${summary.pending.length} pending',
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ],
        ),
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

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    this.isReversed = false,
    this.onApprove,
    this.onReverse,
    this.onDelete,
  });

  final Entry entry;

  /// Whether a reversal already points at this entry.
  final bool isReversed;

  final VoidCallback? onApprove;
  final VoidCallback? onReverse;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = MaterialLocalizations.of(context)
        .formatShortDate(entry.createdAt.toLocal());
    final note = entry.note.trim();
    final hasActions =
        onApprove != null || onReverse != null || onDelete != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(child: Text(_initial(entry.contributorName))),
            title: Text(entry.contributorName),
            subtitle: Text([if (note.isNotEmpty) note, date].join(' · ')),
            isThreeLine: note.isNotEmpty,
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(
                    entry.signedAmountMinor,
                    currency: entry.currency,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: entry.signedAmountMinor < 0
                        ? theme.colorScheme.error
                        : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (entry.isReversal)
                  Text(
                    'Reversal',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: entry.signedAmountMinor < 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else if (isReversed)
                  Text(
                    'Reversed',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else if (entry.isPayout)
                  Text(
                    'Payout',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (hasActions)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onApprove != null)
                    TextButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                    ),
                  if (onReverse != null)
                    TextButton.icon(
                      onPressed: onReverse,
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Reverse'),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('No entries yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Add the first contribution to start the ledger.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirms approving a pending entry.
///
/// Approval is one-way: only pending entries can be deleted, so the warning
/// tells the organizer that a later mistake must be corrected with a reversal.
/// Returns true when the approval should go ahead.
class _ApproveEntryDialog extends StatelessWidget {
  const _ApproveEntryDialog({required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Approve entry?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.contributorName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            Money.format(entry.amountMinor, currency: entry.currency),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Approving makes this entry permanent. It cannot be deleted '
            'afterwards; a correction has to be recorded as a reversal.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Approve'),
        ),
      ],
    );
  }
}

/// Confirms discarding a pending entry.
///
/// The entry is shown so the organizer can check they picked the right row.
/// Returns true when the delete should go ahead.
class _DeleteEntryDialog extends StatelessWidget {
  const _DeleteEntryDialog({required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Delete pending entry?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.contributorName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            Money.format(entry.amountMinor, currency: entry.currency),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This entry was never approved. It will be removed permanently, '
            'without a reversal.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
