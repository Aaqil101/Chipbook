import 'package:flutter_test/flutter_test.dart';

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
}
