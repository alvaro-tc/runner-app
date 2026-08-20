import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceup/features/auth/presentation/pages/sign_in_page.dart';
import 'package:paceup/features/auth/presentation/pages/welcome_page.dart';
import 'package:paceup/features/home/presentation/pages/home_page.dart';
import 'package:paceup/features/onboarding/presentation/pages/onboarding_page.dart';

import 'helpers.dart';

void main() {
  testWidgets('a first launch lands on onboarding', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('Train with a plan that adapts'), findsOneWidget);
  });

  testWidgets('skipping onboarding goes to the welcome screen', (tester) async {
    await pumpApp(tester);
    await tester.pump();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('walking the slides swaps Next for Get started', (tester) async {
    await pumpApp(tester);
    await tester.pump();

    expect(find.text('Next'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('an onboarded visitor is sent to welcome, not home', (
    tester,
  ) async {
    await pumpApp(tester, prefs: {'settings.onboardingSeen': true});
    await tester.pump();
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('a signed-in user goes straight to home', (tester) async {
    await pumpApp(
      tester,
      prefs: {'settings.onboardingSeen': true},
      signedIn: true,
    );
    // Home keeps a one-second countdown running, so it never "settles";
    // pump past the repository latency instead.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HomePage), findsOneWidget);
    await drainHome(tester);
  });

  testWidgets('signing in reaches home', (tester) async {
    await pumpApp(tester, prefs: {'settings.onboardingSeen': true});
    await tester.pump();

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'pandu@paceup.app');
    await tester.enterText(find.byType(TextField).last, 'runfast123');
    await tapSubmit(tester, 'Login');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomePage), findsOneWidget);
    await drainHome(tester);
  });

  testWidgets('a short password is rejected before any request', (
    tester,
  ) async {
    await pumpApp(tester, prefs: {'settings.onboardingSeen': true});
    await tester.pump();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'pandu');
    await tester.enterText(find.byType(TextField).last, 'short');
    await tapSubmit(tester, 'Login');
    await tester.pump();

    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });
}
