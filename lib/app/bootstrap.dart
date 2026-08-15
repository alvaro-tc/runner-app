import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:paceup/app/dependencies.dart';
import 'package:paceup/core/services/preferences_provider.dart';
import 'package:paceup/features/train/data/repositories/hive_training_repository.dart';
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

  await Hive.initFlutter();
  final prefs = await SharedPreferences.getInstance();
  final training = await HiveTrainingRepository.open();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        trainingRepositoryProvider.overrideWithValue(training),
      ],
      child: builder(),
    ),
  );
}
