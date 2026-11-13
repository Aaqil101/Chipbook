import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:chipbook/screens/create_fund_dialog.dart';

void main() {
  testWidgets('default currency search filters the catalog', (tester) async {
    FundDraft? draft;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                draft = await showDialog<FundDraft>(
                  context: context,
                  builder: (_) => const CreateFundDialog(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Travel fund');
    await tester.tap(find.text('USD · US Dollar'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a currency'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('currency-search')), 'yen');
    await tester.pumpAndSettle();

    final results = find.byType(ListView);
    expect(
      find.descendant(of: results, matching: find.text('JPY · Japanese Yen')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: results, matching: find.text('USD · US Dollar')),
      findsNothing,
    );

    await tester.tap(
      find.descendant(of: results, matching: find.text('JPY · Japanese Yen')),
    );
    await tester.pumpAndSettle();

    expect(find.text('JPY · Japanese Yen'), findsOneWidget);

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(draft?.currency, 'JPY');
  });
}
