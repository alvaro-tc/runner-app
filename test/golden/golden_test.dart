import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceup/app/router/app_router.dart';
import 'package:paceup/app/router/app_routes.dart';

import '../helpers.dart';

/// Golden coverage for the four screens the design references define. The live
/// running session is excluded on purpose: its map layer fetches OSM tiles, so
/// it cannot render deterministically offline — it is covered by widget tests
/// and by the simulated-GPS run instead.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadPoppins();
    await _loadMaterialIcons();
  });

  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    final suffix = theme.name;

    testWidgets('home ($suffix)', (tester) async {
      await _phone(tester);
      await pumpApp(tester, prefs: _signedIn(theme));
      await _settleFakes(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_$suffix.png'),
      );
      await drainHome(tester);
    });

    testWidgets('races ($suffix)', (tester) async {
      await _phone(tester);
      final container = await pumpApp(tester, prefs: _signedIn(theme));
      await _settleFakes(tester);
      container.read(routerProvider).go(Routes.races);
      await _settleFakes(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/races_$suffix.png'),
      );
      await drainHome(tester);
    });

    testWidgets('profile ($suffix)', (tester) async {
      await _phone(tester);
      final container = await pumpApp(tester, prefs: _signedIn(theme));
      await _settleFakes(tester);
      container.read(routerProvider).go(Routes.profile);
      await _settleFakes(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/profile_$suffix.png'),
      );
      await drainHome(tester);
    });
  }
}

Map<String, Object> _signedIn(ThemeMode mode) => {
  'settings.onboardingSeen': true,
  'auth.signedIn': true,
  'settings.themeMode': mode.name,
};

/// iPhone 14 logical size.
Future<void> _phone(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(390 * 3, 844 * 3)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// The fake repositories delay between 180 ms and 900 ms; a couple of long
/// pumps clears them without waiting on the never-ending countdown timer.
Future<void> _settleFakes(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

/// Without this every icon renders as an empty box in a golden.
Future<void> _loadMaterialIcons() async {
  final loader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await loader.load();
}

Future<void> _loadPoppins() async {
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final file = File('assets/fonts/Poppins-$weight.ttf');
    if (!file.existsSync()) continue;
    final loader = FontLoader('Poppins')
      ..addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
    await loader.load();
  }
}
