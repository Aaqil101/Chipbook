import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'app_info.dart';
import 'repositories/entry_repository.dart';
import 'screens/entries_page.dart';
import 'state/ledger_controller.dart';

void main() {
  final controller = LedgerController(InMemoryEntryRepository());
  unawaited(controller.load());
  runApp(ChipbookApp(controller: controller));
}

class ChipbookApp extends StatelessWidget {
  const ChipbookApp({super.key, required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.name,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: EntriesPage(controller: controller),
    );
  }
}
