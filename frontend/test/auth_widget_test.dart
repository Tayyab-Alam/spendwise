import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spendwise/providers/auth_provider.dart';
import 'package:spendwise/providers/theme_provider.dart';
import 'package:spendwise/screens/auth/login_screen.dart';
import 'package:spendwise/screens/auth/register_screen.dart';
import 'package:spendwise/screens/splash/splash_screen.dart';

Widget _wrapWithProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  testWidgets('Splash Screen renders app branding and tagline', (WidgetTester tester) async {
    await tester.pumpWidget(_wrapWithProviders(const SplashScreen()));
    // Drain the post-frame callback that starts _checkAuthAndNavigate
    await tester.pump();
    // Advance past the 800ms minimum display timer
    await tester.pump(const Duration(milliseconds: 900));
    // Settle any remaining async work
    await tester.pump();

    expect(find.text('SpendWise'), findsOneWidget);
    expect(find.text('Know where your money goes.'), findsOneWidget);
  });

  testWidgets('Login Screen renders title, inputs, button, and navigation', (WidgetTester tester) async {
    await tester.pumpWidget(_wrapWithProviders(const LoginScreen()));

    // Verify header elements
    expect(find.text('SpendWise'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to continue managing your money.'), findsOneWidget);

    // Verify inputs & button
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Verify bottom navigation link
    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(find.text('Create one'), findsOneWidget);
  });

  testWidgets('Register Screen renders title, inputs, button, and back link', (WidgetTester tester) async {
    await tester.pumpWidget(_wrapWithProviders(const RegisterScreen()));

    // Verify header elements
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Start tracking your spending in seconds.'), findsOneWidget);

    // Verify inputs
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('At least 8 characters'), findsOneWidget);

    // Verify button & bottom navigation
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
