import 'dart:async';

import 'package:camrun/app/dependencies.dart';
import 'package:camrun/core/network/network_providers.dart';
import 'package:camrun/core/services/preferences_provider.dart';
import 'package:camrun/core/storage/token_storage.dart';
import 'package:camrun/core/sync/sync_providers.dart';
import 'package:camrun/features/auth/presentation/providers/auth_provider.dart';
import 'package:camrun/features/train/data/repositories/hive_training_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initialises every service the widget tree expects to already be available,
/// then boots the app with the resulting provider overrides.
Future<void> bootstrap(Widget Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Los simbolos de fecha de `es` (meses, dias) no vienen cargados: sin esto,
  // `DateFormat('MMMM y')` en espanol lanza en el primer render.
  await initializeDateFormatting();

  await Hive.initFlutter();
  final prefs = await SharedPreferences.getInstance();
  final training = await HiveTrainingRepository.open();

  // Con refresh token guardado hay sesion: dura 60 dias y rota sola, asi que
  // el arranque no necesita red para saber a que pantalla ir. Si resultara
  // estar revocado, lo dira el primer 401 y el router mandara a Welcome.
  final tokens = SecureTokenStorage();
  final huboSesion = (await tokens.readRefreshToken())?.isNotEmpty ?? false;

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tokenStorageProvider.overrideWithValue(tokens),
      initialSessionProvider.overrideWithValue(huboSesion),
      trainingRepositoryProvider.overrideWithValue(training),
    ],
  );

  // La cola se drena al arrancar y cada vez que la app vuelve al frente: es
  // cuando hay mas probabilidad de que haya vuelto la cobertura. Sin escuchar
  // la conectividad —una dependencia mas para adivinar lo que el primer
  // reintento averigua solo.
  // ponytail: si hiciera falta drenar en cuanto vuelve la red, connectivity_plus.
  void drenar() => unawaited(container.read(syncServiceProvider).drain());

  drenar();

  // Vive lo que vive el proceso: no hay a quien devolverselo.
  AppLifecycleListener(onResume: drenar);

  runApp(UncontrolledProviderScope(container: container, child: builder()));
}
