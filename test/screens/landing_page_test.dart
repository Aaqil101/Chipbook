import 'package:chipbook/screens/landing_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('a visitor learns what Chipbook is before signing in', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LandingPage(onSignIn: () {})),
    );

    expect(find.text('A shared ledger for group fundraising.'), findsOneWidget);
    expect(find.textContaining('never holds or moves money'), findsWidgets);
    expect(find.text('Approvals you can trust'), findsOneWidget);
    expect(find.text('Corrections, not edits'), findsOneWidget);
    expect(find.text('Payouts and targets'), findsOneWidget);
    expect(find.text('Private by default'), findsOneWidget);
  });

  testWidgets('both calls to action open the sign-in flow', (tester) async {
    var opened = 0;

    await tester.pumpWidget(
      MaterialApp(home: LandingPage(onSignIn: () => opened++)),
    );

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(opened, 1);

    await tester.tap(find.text('Sign in to Chipbook'));
    await tester.pumpAndSettle();
    expect(opened, 2);
  });

  testWidgets('the feature grid collapses to one column on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: LandingPage(onSignIn: () {})),
    );

    final first = tester.getTopLeft(find.text('Approvals you can trust'));
    final second = tester.getTopLeft(find.text('Corrections, not edits'));

    expect(second.dy, greaterThan(first.dy));
  });
}
