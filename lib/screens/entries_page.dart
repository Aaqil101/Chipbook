import 'package:material_ui/material_ui.dart';

import '../app_info.dart';
import '../domain/ledger.dart';
import '../domain/money.dart';
import '../models/entry.dart';
import '../state/ledger_controller.dart';
import 'add_entry_page.dart';

/// Shows the running total, approved entries, and pending entries.
class EntriesPage extends StatelessWidget {
  const EntriesPage({super.key, required this.controller, this.onSignOut});

  final LedgerController controller;
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
            title: const Text(AppInfo.name),
            actions: [
              if (signOut != null)
                IconButton(
                  onPressed: signOut,
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout),
                ),
            ],
          ),
          body: _buildBody(summary),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddEntry(context),
            icon: const Icon(Icons.add),
            label: const Text('Add entry'),
          ),
        );
      },
    );
  }

  Widget _buildBody(LedgerSummary summary) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (summary.isEmpty) {
      return const _EmptyState();
    }
    return _LedgerList(summary: summary);
  }

  Future<void> _openAddEntry(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AddEntryPage(controller: controller),
      ),
    );
  }
}

class _LedgerList extends StatelessWidget {
  const _LedgerList({required this.summary});

  final LedgerSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _TotalCard(summary: summary),
        const SizedBox(height: 24),
        if (summary.pending.isNotEmpty) ...[
          _SectionHeader(title: 'Pending', count: summary.pending.length),
          const SizedBox(height: 8),
          for (final entry in summary.pending) _EntryTile(entry: entry),
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
          for (final entry in summary.approved) _EntryTile(entry: entry),
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
  const _EntryTile({required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = MaterialLocalizations.of(context)
        .formatShortDate(entry.createdAt.toLocal());
    final note = entry.note.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
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
              Money.format(entry.signedAmountMinor, currency: entry.currency),
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
              ),
          ],
        ),
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
