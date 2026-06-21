// Smoke test for the AetherVest app.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stock_market_app/main.dart';

void main() {
  testWidgets('Sign-in screen renders and navigates into the app', (
    tester,
  ) async {
    await tester.pumpWidget(const AetherVestApp());

    // The sign-in screen shows the brand and call to action.
    expect(find.text('AetherVest'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Tapping Continue routes into the bottom-nav shell.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Trending Stocks'), findsOneWidget);
  });
}
