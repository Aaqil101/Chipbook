import 'package:material_ui/material_ui.dart';

import '../domain/entry_validation.dart';
import '../domain/money.dart';
import '../models/entry.dart';

/// Asks why an approved entry is being corrected.
///
/// The target entry is shown so the organizer can confirm they picked the
/// right row; the returned reason becomes the reversal entry's note.
class ReverseEntryDialog extends StatefulWidget {
  const ReverseEntryDialog({super.key, required this.entry});

  final Entry entry;

  @override
  State<ReverseEntryDialog> createState() => _ReverseEntryDialogState();
}

class _ReverseEntryDialogState extends State<ReverseEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop<String>(_reasonController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    final note = entry.note.trim();

    return AlertDialog(
      title: const Text('Reverse entry'),
      content: Form(
        key: _formKey,
        child: Column(
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
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Original note: $note', style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 20),
            TextFormField(
              controller: _reasonController,
              autofocus: true,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Reason',
                helperText: 'Required: explain what this correction fixes',
              ),
              validator: (value) =>
                  EntryValidation.reversalReasonError(value ?? ''),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Text(
              'The original entry stays on the ledger. A new approved '
              'reversal is added and the total drops by this amount.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Record reversal')),
      ],
    );
  }
}
