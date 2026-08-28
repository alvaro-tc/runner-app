import 'dart:convert';

import 'package:camrun/core/services/settings_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/fake_http.dart';
import '../../fake_api.dart';
import '../../helpers.dart';

/// Tema, unidades e idioma viven en el servidor. Lo que se prueba aqui es el
/// puente: que lo del servidor gane, que lo local aguante hasta entonces, y que
/// un cambio del usuario vuelva al servidor.
void main() {
  RequestOptions? patch;

  Future<ResponseBody> backend(RequestOptions req) async {
    if (req.path == '/users/me/preferences') {
      if (req.method == 'PATCH') patch = req;
      return envelope({
        'units': 'imperial',
        'theme': 'dark',
        'locale': 'en',
        'notifications': {'planReminders': true},
        'privacy': {'shareActivity': true},
      });
    }
    return fakeBackend(req);
  }

  setUp(() => patch = null);

  testWidgets('lo del servidor pisa lo local al llegar', (tester) async {
    final container = await pumpApp(
      tester,
      // Lo guardado en el dispositivo: es lo que pinta el primer frame.
      prefs: {
        'settings.themeMode': ThemeMode.light.name,
        'settings.language': AppLanguage.spanish.name,
        'settings.distanceUnit': DistanceUnit.km.name,
      },
      signedIn: true,
      syncAppearance: true,
      api: backend,
    );

    expect(container.read(settingsProvider).themeMode, ThemeMode.light);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(container.read(settingsProvider).appearance, (
      themeMode: ThemeMode.dark,
      language: AppLanguage.english,
      unit: DistanceUnit.mi,
    ));
    // Solo baja: nada de devolverle al servidor lo que acaba de mandar.
    expect(patch, isNull);

    await drainHome(tester);
  });

  testWidgets('un cambio del usuario sube en el PATCH', (tester) async {
    final container = await pumpApp(
      tester,
      signedIn: true,
      syncAppearance: true,
      api: backend,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await container.read(settingsProvider.notifier).setUnit(DistanceUnit.km);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final body = jsonDecode(jsonEncode(patch!.data)) as Map<String, dynamic>;
    expect(body['units'], 'metric');
    // Los interruptores viajan enteros: el PATCH reescribe el bloque.
    expect((body['privacy'] as Map)['shareActivity'], true);

    await drainHome(tester);
  });
}
