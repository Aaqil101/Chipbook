import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../domain/currency.dart';

/// A read-only currency field that opens a searchable picker.
class CurrencyPickerField extends StatelessWidget {
  const CurrencyPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Currency',
    this.helperText,
    this.validator,
  });

  /// Currently selected ISO 4217 code.
  final String value;

  /// Called with the newly picked code.
  final ValueChanged<String> onChanged;

  final String label;
  final String? helperText;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        final selected = CurrencyCatalog.byCode(field.value ?? value);
        return SizedBox(
          width: double.infinity,
          child: InkWell(
            onTap: () async {
              final picked = await showDialog<String>(
                context: context,
                builder: (_) =>
                    _CurrencyPickerDialog(initialValue: field.value ?? value),
              );
              if (picked != null) {
                field.didChange(picked);
                onChanged(picked);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                helperText: helperText,
                errorText: field.errorText,
                suffixIcon: const Icon(Icons.search),
              ),
              child: Text(selected?.label ?? 'Choose a currency'),
            ),
          ),
        );
      },
    );
  }
}

class _CurrencyPickerDialog extends StatefulWidget {
  const _CurrencyPickerDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<_CurrencyPickerDialog> {
  final _searchController = TextEditingController();
  late List<Currency> _results;

  @override
  void initState() {
    super.initState();
    _results = CurrencyCatalog.currencies;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() => _results = CurrencyCatalog.search(query));
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return AlertDialog(
      title: const Text('Choose a currency'),
      content: SizedBox(
        width: math.min(360, math.max(240, screen.width - 80)),
        height: math.min(400, math.max(200, screen.height - 200)),
        child: Column(
          children: [
            TextField(
              key: const Key('currency-search'),
              controller: _searchController,
              autofocus: true,
              onChanged: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by code or name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('No currencies match.'))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final currency = _results[index];
                        final selected = currency.code == widget.initialValue;
                        return ListTile(
                          selected: selected,
                          title: Text(currency.label),
                          trailing: selected ? const Icon(Icons.check) : null,
                          onTap: () => Navigator.of(context).pop(currency.code),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
