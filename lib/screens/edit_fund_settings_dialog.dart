import 'package:material_ui/material_ui.dart';

import '../domain/currency.dart';
import '../domain/fund_validation.dart';
import '../domain/money.dart';
import '../models/fund.dart';
import '../models/fund_cadence.dart';
import '../widgets/amount_input_formatter.dart';

/// Values collected by [EditFundSettingsDialog].
typedef FundSettingsDraft = ({FundCadence cadence, int? targetMinor});

/// Changes a fund's collection timing and period target.
///
/// The fund's currency is fixed, so the target stays in that currency. An
/// empty target removes the goal.
class EditFundSettingsDialog extends StatefulWidget {
  const EditFundSettingsDialog({super.key, required this.fund});

  final Fund fund;

  @override
  State<EditFundSettingsDialog> createState() => _EditFundSettingsDialogState();
}

class _EditFundSettingsDialogState extends State<EditFundSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _targetController;
  late FundCadence _cadence;

  @override
  void initState() {
    super.initState();
    _cadence = widget.fund.cadence;
    final target = widget.fund.targetMinor;
    _targetController = TextEditingController(
      text: target == null
          ? ''
          : Money.toPlain(target, currency: widget.fund.defaultCurrency),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final target = _targetController.text.trim();
    Navigator.of(context).pop<FundSettingsDraft>((
      cadence: _cadence,
      targetMinor: target.isEmpty
          ? null
          : Money.tryParseToMinor(
              target,
              currency: widget.fund.defaultCurrency,
            ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Timing and target'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<FundCadence>(
                initialValue: _cadence,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Collection timing',
                  helperText: _cadence.rollover,
                ),
                items: [
                  for (final cadence in FundCadence.values)
                    DropdownMenuItem<FundCadence>(
                      value: cadence,
                      child: Text(cadence.label),
                    ),
                ],
                onChanged: (cadence) {
                  if (cadence != null) {
                    setState(() => _cadence = cadence);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  AmountInputFormatter(
                    decimalDigits: CurrencyCatalog.fractionDigitsFor(
                      widget.fund.defaultCurrency,
                    ),
                  ),
                ],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText:
                      'Target in ${widget.fund.defaultCurrency} '
                      '(optional)',
                  helperText: _cadence.targetScope,
                ),
                validator: (value) => FundValidation.targetError(
                  value ?? '',
                  currency: widget.fund.defaultCurrency,
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Text(
                'Entries are never changed. Changing the timing only changes '
                'how the current period is calculated.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
