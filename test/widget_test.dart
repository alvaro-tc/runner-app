import 'package:camrun/features/auth/presentation/pages/sign_in_page.dart';
import 'package:camrun/features/auth/presentation/pages/welcome_page.dart';
import 'package:camrun/features/home/presentation/pages/home_page.dart';
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
    // La historia del CAM avanza sola: nunca "se asienta".
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(WelcomePage), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings.themeMode'), ThemeMode.dark.name);
  });

  testWidgets('a first launch lands on the CAM story', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    expect(find.byType(WelcomePage), findsOneWidget);
    // El CAM RUN abre la historia.
    expect(find.text('Corre por la vida.'), findsOneWidget);
  });

  testWidgets('from the story, sign in opens the form', (tester) async {
    await pumpApp(tester);
    await tester.pump();

    // Los botones de la historia entran subiendo durante el primer segundo.
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('tapping the story moves to the next chapter', (tester) async {
    await pumpApp(tester);
    await tester.pump();

    // El tercio izquierdo vuelve atras; el resto avanza.
    await tester.tapAt(const Offset(700, 200));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('No estás sola.'), findsOneWidget);
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
    // Los botones de la historia entran subiendo durante el primer segundo.
    await tester.pump(const Duration(seconds: 1));
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
    // Los botones de la historia entran subiendo durante el primer segundo.
    await tester.pump(const Duration(seconds: 1));
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
