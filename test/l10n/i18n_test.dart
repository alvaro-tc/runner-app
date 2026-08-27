import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceup/app/router/app_router.dart';
import 'package:paceup/app/router/app_routes.dart';
import 'package:paceup/core/services/settings_provider.dart';
import 'package:paceup/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

/// Guardia de la traduccion (PU-203).
///
/// El grep de `tool/i18n_guard.sh` comprueba que no queden literales en los
/// widgets. Esto comprueba lo otro: que los dos ARB digan lo mismo, y que el
/// selector de Ajustes traduzca la app en caliente.
void main() {
  group('ARB', () {
    final en = _arb('app_en.arb');
    final es = _arb('app_es.arb');

    test('el espanol cubre todas las claves del ingles', () {
      expect(es.keys.toSet(), containsAll(en.keys));
    });

    test('el espanol no inventa claves que el ingles no tenga', () {
      expect(en.keys.toSet(), containsAll(es.keys));
    });

    test('cada traduccion usa los mismos placeholders que su plantilla', () {
      for (final key in en.keys) {
        expect(
          _placeholders(es[key]!),
          _placeholders(en[key]!),
          reason:
              'Los placeholders de "$key" no coinciden entre ingles y '
              'espanol. Un `{nombre}` de mas o de menos revienta en runtime.',
        );
      }
    });

    test('ninguna traduccion se quedo vacia', () {
      for (final entry in es.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: entry.key);
      }
    });
  });

  group('locales', () {
    test('la app soporta espanol e ingles, con el espanol primero', () {
      expect(AppLocalizations.supportedLocales.map((l) => l.languageCode), [
        'es',
        'en',
      ]);
    });

    test('cada idioma del selector resuelve a un locale soportado', () {
      for (final language in AppLanguage.values) {
        if (language.locale == null) continue; // `system` lo resuelve Flutter.
        expect(
          AppLocalizations.supportedLocales,
          contains(language.locale),
          reason: language.name,
        );
      }
    });
  });

  group('selector de idioma', () {
    testWidgets('cambiar a espanol traduce la app sin reiniciar', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        prefs: {'settings.language': AppLanguage.english.name},
        signedIn: true,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // El mismo arbol, sin volver a montar nada: solo cambia el ajuste.
      await container
          .read(settingsProvider.notifier)
          .setLanguage(AppLanguage.spanish);
      await tester.pump();

      expect(find.text('Home'), findsNothing);
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);

      await drainHome(tester);
    });

    testWidgets('elegir un idioma lo deja escrito en disco', (tester) async {
      final container = await pumpApp(tester, signedIn: true);
      await tester.pump(const Duration(seconds: 1));

      await container
          .read(settingsProvider.notifier)
          .setLanguage(AppLanguage.english);
      await tester.pump();

      final guardado = await SharedPreferences.getInstance();
      expect(guardado.getString('settings.language'), AppLanguage.english.name);

      await drainHome(tester);
    });

    testWidgets('el arranque respeta el idioma guardado', (tester) async {
      await pumpApp(
        tester,
        prefs: {'settings.language': AppLanguage.english.name},
        signedIn: true,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Inicio'), findsNothing);

      await drainHome(tester);
    });

    testWidgets('la pantalla de Ajustes cambia el idioma de la app', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        prefs: {'settings.language': AppLanguage.english.name},
        signedIn: true,
      );
      await tester.pump(const Duration(seconds: 1));

      container.read(routerProvider).go(Routes.profileLanguage);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Language'), findsOneWidget);

      // El nombre de cada idioma va en su propio idioma, asi que «Español» se
      // lee igual con la app en ingles.
      await tester.tap(find.text('Español'));
      await tester.pump();

      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Language'), findsNothing);
      expect(container.read(languageProvider), AppLanguage.spanish);

      await drainHome(tester);
    });

    testWidgets('con el idioma en «sistema» se sigue al dispositivo', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await pumpApp(
        tester,
        prefs: {'settings.language': AppLanguage.system.name},
        signedIn: true,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Home'), findsOneWidget);
      await drainHome(tester);
    });
  });
}

Map<String, String> _arb(String name) {
  final raw =
      jsonDecode(File('lib/l10n/arb/$name').readAsStringSync())
          as Map<String, dynamic>;
  return {
    for (final entry in raw.entries)
      // `@@locale` y los `@clave` son metadatos, no mensajes.
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
  };
}

final _placeholder = RegExp(r'\{(\w+)\}');

Set<String> _placeholders(String message) =>
    _placeholder.allMatches(message).map((m) => m.group(1)!).toSet();
