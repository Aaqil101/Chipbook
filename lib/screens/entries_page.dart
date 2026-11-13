import 'package:material_ui/material_ui.dart';

import '../domain/fund_permissions.dart';
import '../domain/ledger.dart';
import '../domain/money.dart';
import '../models/entry.dart';
import '../models/fund.dart';
import '../state/ledger_controller.dart';
import 'add_entry_page.dart';
import 'reverse_entry_dialog.dart';

const _newFundAction = '__new_fund__';

/// Shows the running total, approved entries, and pending entries.
class EntriesPage extends StatelessWidget {
  const EntriesPage({
    super.key,
    required this.controller,
    required this.fundName,
    this.permissions,
    this.funds = const <Fund>[],
    this.onSelectFund,
    this.onCreateFund,
    this.onSignOut,
  });

  final LedgerController controller;
  final String fundName;

  /// The signed-in user's role in this fund, or null until it is known.
  final FundPermissions? permissions;

  final List<Fund> funds;
  final ValueChanged<Fund>? onSelectFund;
  final VoidCallback? onCreateFund;
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
            title: Text(fundName, overflow: TextOverflow.ellipsis),
            actions: [
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
                    const PopupMenuItem<String>(
                      value: _newFundAction,
                      child: Text('New fund'),
                    ),
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
    if (summary.isEmpty) {
      return const _EmptyState();
    }
    return _LedgerList(
      summary: summary,
      permissions: permissions,
      onApprove: (entry) => _approve(context, entry),
      onReverse: (entry) => _reverse(context, entry),
    );
  }

  Future<void> _approve(BuildContext context, Entry entry) async {
    try {
      await controller.approve(entry.id);
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
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AddEntryPage(controller: controller),
      ),
    );
  }

  void _handleFundSelection(String value) {
    if (value == _newFundAction) {
      onCreateFund?.call();
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
    required this.permissions,
    required this.onApprove,
    required this.onReverse,
  });

  final LedgerSummary summary;
  final FundPermissions? permissions;
  final ValueChanged<Entry> onApprove;
  final ValueChanged<Entry> onReverse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canApprove = permissions?.canApprove ?? false;
    final canReverse = permissions?.canReverse ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _TotalCard(summary: summary),
        const SizedBox(height: 24),
        if (summary.pending.isNotEmpty) ...[
          _SectionHeader(title: 'Pending', count: summary.pending.length),
          const SizedBox(height: 8),
          for (final entry in summary.pending)
            _EntryTile(
              entry: entry,
              onApprove: canApprove ? () => onApprove(entry) : null,
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
              'Raised so far',
              style: theme.textTheme.titleMedium?.copyWith(color: foreground),
            ),
            const SizedBox(height: 8),
            Text(
              Money.format(summary.totalMinor, currency: summary.currency),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.bold,
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
  });

  final Entry entry;

  /// Whether a reversal already points at this entry.
  final bool isReversed;

  final VoidCallback? onApprove;
  final VoidCallback? onReverse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = MaterialLocalizations.of(context)
        .formatShortDate(entry.createdAt.toLocal());
    final note = entry.note.trim();
    final hasActions = onApprove != null || onReverse != null;

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
                    color: entry.isReversal ? theme.colorScheme.error : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (entry.isReversal)
                  Text(
                    'Reversal',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  )
                else if (isReversed)
                  Text(
                    'Reversed',
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
