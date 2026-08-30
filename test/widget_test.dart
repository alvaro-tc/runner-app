import 'package:camrun/features/auth/presentation/pages/sign_in_page.dart';
import 'package:camrun/features/auth/presentation/pages/welcome_page.dart';
import 'package:camrun/features/home/presentation/pages/home_page.dart';
import 'package:camrun/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:camrun/features/onboarding/presentation/pages/theme_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  testWidgets('sin tema elegido la primera pantalla es el selector', (
    tester,
  ) async {
    await pumpApp(tester, themePicked: false);
    await tester.pump();
    expect(find.byType(ThemeSetupPage), findsOneWidget);

    await tester.tap(find.text('Oscuro'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingPage), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings.themeMode'), ThemeMode.dark.name);
  });

  testWidgets('a first launch lands on onboarding', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('Entrena con un plan que se adapta'), findsOneWidget);
  });

  testWidgets('skipping onboarding goes to the welcome screen', (tester) async {
    await pumpApp(tester);
    await tester.pump();

    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('walking the slides swaps Next for Get started', (tester) async {
    await pumpApp(tester);
    await tester.pump();

    expect(find.text('Siguiente'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Empezar'), findsOneWidget);
  });

  testWidgets('a signed-in user goes straight to home', (tester) async {
    // Con sesion viva los slides no se interponen: el guard los salta.
    await pumpApp(tester, signedIn: true);
    // Home keeps a one-second countdown running, so it never "settles";
    // pump past the repository latency instead.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HomePage), findsOneWidget);
    await drainHome(tester);
  });

  testWidgets('signing in reaches home', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'pandu@camrun.app');
    await tester.enterText(find.byType(TextField).last, 'runfast123');
    await tapSubmit(tester, 'Iniciar sesión');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomePage), findsOneWidget);
    await drainHome(tester);
  });

  testWidgets('a short password is rejected before any request', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.pump();
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'pandu');
    await tester.enterText(find.byType(TextField).last, 'short');
    await tapSubmit(tester, 'Iniciar sesión');
    await tester.pump();

    expect(find.text('Usa al menos 8 caracteres.'), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });
}
