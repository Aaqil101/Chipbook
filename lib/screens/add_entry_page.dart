import 'package:material_ui/material_ui.dart';

import '../state/ledger_controller.dart';

/// Records a new contribution.
///
/// The list screen links here; the form body is built in the next step.
class AddEntryPage extends StatelessWidget {
  const AddEntryPage({super.key, required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add entry')),
      body: const Center(child: Text('Entry form coming soon.')),
    );
  }
}
