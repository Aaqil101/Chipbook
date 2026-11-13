import 'package:material_ui/material_ui.dart';

import '../config.dart';
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
  final _currencyController = TextEditingController(
    text: AppConfig.defaultCurrency,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop<FundDraft>((
      name: _nameController.text.trim(),
      currency: _currencyController.text.trim().toUpperCase(),
    ));
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
            TextFormField(
              controller: _currencyController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 3,
              decoration: const InputDecoration(
                labelText: 'Currency',
                helperText: '3-letter ISO code, e.g. USD',
              ),
              validator: (value) => FundValidation.currencyError(value ?? ''),
              onFieldSubmitted: (_) => _submit(),
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
