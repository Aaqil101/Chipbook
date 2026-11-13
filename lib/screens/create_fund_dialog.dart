import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../domain/currency.dart';
import '../domain/fund_validation.dart';

/// Values collected by [CreateFundDialog].
typedef FundDraft = ({String name, String currency});

/// Asks for a fund name and its default currency.
class CreateFundDialog extends StatefulWidget {
  const CreateFundDialog({super.key});

  @override
  State<CreateFundDialog> createState() => _CreateFundDialogState();
}

class _CreateFundDialogState extends State<CreateFundDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late String _currency;

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
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(
      context,
    ).pop<FundDraft>((name: _nameController.text.trim(), currency: _currency));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create a fund'),
      content: Form(
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
            DropdownButtonFormField<String>(
              initialValue: _currency,
              isExpanded: true,
              menuMaxHeight: 420,
              decoration: const InputDecoration(
                labelText: 'Default currency',
                helperText: 'New entries start in this currency',
              ),
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
                }
              },
            ),
          ],
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
