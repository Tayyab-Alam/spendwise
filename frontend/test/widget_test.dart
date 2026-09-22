// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spendwise/main.dart';
import 'package:spendwise/providers/auth_provider.dart';
import 'package:spendwise/providers/theme_provider.dart';

void main() {
  testWidgets('SpendWiseApp initial route renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const SpendWiseApp(),
      ),
    );
    // Drain the post-frame callback that triggers auth check
    await tester.pump();
    // Advance past the 800ms minimum splash display timer
    await tester.pump(const Duration(milliseconds: 900));
    // Settle remaining async work
    await tester.pump();

    expect(find.text('SpendWise'), findsOneWidget);
    expect(find.text('Know where your money goes.'), findsOneWidget);
  });
}
