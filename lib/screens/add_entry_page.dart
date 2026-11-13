import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../domain/currency.dart';
import '../domain/entry_validation.dart';
import '../domain/money.dart';
import '../models/entry.dart';
import '../state/ledger_controller.dart';
import '../widgets/amount_input_formatter.dart';

/// Records a new contribution, or a payout when the user is an organizer.
class AddEntryPage extends StatefulWidget {
  const AddEntryPage({
    super.key,
    required this.controller,
    this.canRecordPayout = false,
  });

  final LedgerController controller;

  /// Whether the signed-in user may record money leaving the fund.
  final bool canRecordPayout;

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountFieldKey = GlobalKey<FormFieldState<String>>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  late String _currency;
  EntryKind _kind = EntryKind.contribution;
  bool _saving = false;

  bool get _isPayout => _kind == EntryKind.payout;

  @override
  void initState() {
    super.initState();
    _currency =
        CurrencyCatalog.byCode(widget.controller.defaultCurrency)?.code ??
        CurrencyCatalog.byCode(AppConfig.defaultCurrency)?.code ??
        CurrencyCatalog.currencies.first.code;
  }

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

    final amountMinor = Money.tryParseToMinor(
      _amountController.text,
      currency: _currency,
    );
    if (amountMinor == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.controller.addEntry(
        amountMinor: amountMinor,
        contributorName: _nameController.text,
        note: _noteController.text,
        currency: _currency,
        kind: _kind,
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isPayout ? 'Record payout' : 'Add entry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.canRecordPayout) ...[
              SegmentedButton<EntryKind>(
                segments: const [
                  ButtonSegment<EntryKind>(
                    value: EntryKind.contribution,
                    label: Text('Contribution'),
                    icon: Icon(Icons.savings_outlined),
                  ),
                  ButtonSegment<EntryKind>(
                    value: EntryKind.payout,
                    label: Text('Payout'),
                    icon: Icon(Icons.payments_outlined),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (selection) {
                  setState(() => _kind = selection.first);
                },
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<String>(
              initialValue: _currency,
              isExpanded: true,
              menuMaxHeight: 420,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: [
                for (final currency in CurrencyCatalog.currencies)
                  DropdownMenuItem<String>(
                    value: currency.code,
                    child: Text(
                      currency.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (code) {
                if (code != null) {
                  setState(() => _currency = code);
                  _amountFieldKey.currentState?.validate();
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: _amountFieldKey,
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                AmountInputFormatter(
                  decimalDigits: CurrencyCatalog.fractionDigitsFor(_currency),
                ),
              ],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '$_currency ',
                hintText: _amountHint(_currency),
              ),
              onChanged: (_) {
                if (_isPayout) {
                  setState(() {});
                }
              },
              validator: (value) =>
                  EntryValidation.amountError(value ?? '', currency: _currency),
            ),
            if (_exceedsBalance) ...[
              const SizedBox(height: 12),
              _BalanceWarning(
                message:
                    'This is more than the '
                    '${Money.format(_balanceMinor, currency: _currency)} '
                    'balance. The balance will go negative.',
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: _isPayout ? 'Paid to' : 'Contributor name',
              ),
              validator: (value) => _isPayout
                  ? EntryValidation.payeeError(value ?? '')
                  : EntryValidation.contributorError(value ?? ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: _isPayout ? 'Reason (required)' : 'Note (optional)',
              ),
              validator: _isPayout
                  ? (value) => EntryValidation.payoutReasonError(value ?? '')
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_isPayout) ...[
              const SizedBox(height: 8),
              Text(
                'The payout is recorded as approved, like a reversal.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isPayout ? 'Record payout' : 'Save entry'),
            ),
          ],
        ),
      ),
    );
  }

  int get _balanceMinor => widget.controller.summary.balanceMinorFor(_currency);

  /// True when the typed payout is larger than the recorded balance.
  bool get _exceedsBalance {
    if (!_isPayout) {
      return false;
    }
    final amountMinor = Money.tryParseToMinor(
      _amountController.text,
      currency: _currency,
    );
    return amountMinor != null && amountMinor > _balanceMinor;
  }

  String _amountHint(String currency) {
    final digits = CurrencyCatalog.fractionDigitsFor(currency);
    return digits == 0 ? '0' : '0.${'0' * digits}';
  }
}

class _BalanceWarning extends StatelessWidget {
  const _BalanceWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
