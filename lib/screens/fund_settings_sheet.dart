import 'package:material_ui/material_ui.dart';

import '../domain/money.dart';
import '../models/fund.dart';

/// Actions an organizer can take on the active fund.
enum FundSettingsAction { timing, archive, delete }

/// Bottom sheet listing the fund's settings and destructive actions.
///
/// Deleting is only offered while the fund has no entries; otherwise the
/// ledger would be lost, so archiving is the only option.
class FundSettingsSheet extends StatelessWidget {
  const FundSettingsSheet({
    super.key,
    required this.fund,
    required this.canDelete,
    required this.onRestoreArchived,
  });

  final Fund fund;
  final bool canDelete;

  /// Opens the list of archived funds, or null when there are none.
  final VoidCallback? onRestoreArchived;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(fund.name, style: theme.textTheme.titleLarge),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_repeat),
            title: const Text('Timing and target'),
            subtitle: Text(_timingSummary(fund)),
            onTap: () => Navigator.of(context).pop(FundSettingsAction.timing),
          ),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Archive fund'),
            subtitle: const Text(
              'Hide it from your fund list but keep the ledger',
            ),
            onTap: () => Navigator.of(context).pop(FundSettingsAction.archive),
          ),
          ListTile(
            enabled: canDelete,
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete fund'),
            subtitle: Text(
              canDelete
                  ? 'Permanently remove this fund'
                  : 'Only a fund with no entries can be deleted',
            ),
            onTap: canDelete
                ? () => Navigator.of(context).pop(FundSettingsAction.delete)
                : null,
          ),
          if (onRestoreArchived != null)
            ListTile(
              leading: const Icon(Icons.unarchive_outlined),
              title: const Text('Restore an archived fund'),
              onTap: () {
                Navigator.of(context).pop();
                onRestoreArchived!();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _timingSummary(Fund fund) {
    final target = fund.targetMinor;
    final goal = target == null
        ? 'no target'
        : '${Money.format(target, currency: fund.defaultCurrency)} target';
    return '${fund.cadence.label} · $goal';
  }
}

/// Asks before archiving [fundName]. Returns true when confirmed.
Future<bool> confirmArchiveFund(BuildContext context, String fundName) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Archive “$fundName”?'),
      content: const Text(
        'It disappears from your fund list, but every entry is kept and '
        'you can restore it later.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Archive'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

/// Asks before deleting [fundName]. Returns true when confirmed.
Future<bool> confirmDeleteFund(BuildContext context, String fundName) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete “$fundName”?'),
      content: const Text(
        'This permanently removes the fund. It has no entries, so no ledger '
        'history is lost. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
