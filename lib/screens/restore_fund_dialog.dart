import 'package:material_ui/material_ui.dart';

import '../models/fund.dart';

/// Lists archived funds so the user can pick one to restore.
class RestoreFundDialog extends StatelessWidget {
  const RestoreFundDialog({super.key, required this.funds});

  final List<Fund> funds;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Archived funds'),
      children: [
        for (final fund in funds)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(fund),
            child: Row(
              children: [
                const Icon(Icons.unarchive_outlined, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(fund.name, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 12),
                const Text('Restore'),
              ],
            ),
          ),
      ],
    );
  }
}
