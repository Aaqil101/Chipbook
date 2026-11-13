import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../domain/currency.dart';
import '../domain/fund_validation.dart';
import '../domain/money.dart';
import '../models/fund_cadence.dart';
import '../widgets/amount_input_formatter.dart';
import '../widgets/currency_picker_field.dart';

/// Values collected by [CreateFundDialog].
typedef FundDraft = ({
  String name,
  String currency,
  FundCadence cadence,
  int? targetMinor,
});

/// Asks for a fund name, its default currency, its timing, and a target.
class CreateFundDialog extends StatefulWidget {
  const CreateFundDialog({super.key});

  @override
  State<CreateFundDialog> createState() => _CreateFundDialogState();
}

class _CreateFundDialogState extends State<CreateFundDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  late String _currency;
  FundCadence _cadence = FundCadence.oneOff;

  @override
  void initState() {
    super.initState();
    _currency =
        CurrencyCatalog.byCode(AppConfig.defaultCurrency)?.code ??
        CurrencyCatalog.currencies.first.code;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final target = _targetController.text.trim();
    Navigator.of(context).pop<FundDraft>((
      name: _nameController.text.trim(),
      currency: _currency,
      cadence: _cadence,
      targetMinor: target.isEmpty
          ? null
          : Money.tryParseToMinor(target, currency: _currency),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create a fund'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Fund name'),
                validator: (value) => FundValidation.nameError(value ?? ''),
              ),
              const SizedBox(height: 16),
              CurrencyPickerField(
                value: _currency,
                label: 'Default currency',
                helperText: 'New entries start in this currency',
                validator: (code) => FundValidation.currencyError(code ?? ''),
                onChanged: (code) => setState(() => _currency = code),
              ),
              const SizedBox(height: 16),
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
                    decimalDigits: CurrencyCatalog.fractionDigitsFor(_currency),
                  ),
                ],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Target in $_currency (optional)',
                  helperText: _cadence.targetScope,
                ),
                validator: (value) => FundValidation.targetError(
                  value ?? '',
                  currency: _currency,
                ),
                onFieldSubmitted: (_) => _submit(),
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
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}
