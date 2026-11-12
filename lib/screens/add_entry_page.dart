import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../domain/entry_validation.dart';
import '../domain/money.dart';
import '../state/ledger_controller.dart';

/// Records a new contribution.
class AddEntryPage extends StatefulWidget {
  const AddEntryPage({super.key, required this.controller});

  final LedgerController controller;

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amountMinor = Money.tryParseToMinor(_amountController.text);
    if (amountMinor == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.controller.addEntry(
        amountMinor: amountMinor,
        contributorName: _nameController.text,
        note: _noteController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add entry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${AppConfig.defaultCurrency} ',
                hintText: '0.00',
              ),
              validator: (value) => EntryValidation.amountError(value ?? ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Contributor name'),
              validator: (value) =>
                  EntryValidation.contributorError(value ?? ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save entry'),
            ),
          ],
        ),
      ),
    );
  }
}
