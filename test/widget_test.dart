import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:chipbook/app_info.dart';
import 'package:chipbook/main.dart';
import 'package:chipbook/repositories/entry_repository.dart';
import 'package:chipbook/state/ledger_controller.dart';

void main() {
  testWidgets('shows the empty ledger state', (tester) async {
    final controller = LedgerController(InMemoryEntryRepository());
    await controller.load();

    await tester.pumpWidget(ChipbookApp(controller: controller));

    expect(find.text(AppInfo.name), findsOneWidget);
    expect(find.text('No entries yet'), findsOneWidget);
    expect(find.text('Add entry'), findsOneWidget);
  });

  testWidgets('pending entries show up without changing the total', (
    tester,
  ) async {
    final controller = LedgerController(InMemoryEntryRepository());
    await controller.load();
    await tester.pumpWidget(ChipbookApp(controller: controller));

    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '12.50');
    await tester.enterText(fields.at(1), 'Ada');
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('USD 12.50'), findsOneWidget);
    expect(find.text('USD 0.00'), findsOneWidget);
  });
}
