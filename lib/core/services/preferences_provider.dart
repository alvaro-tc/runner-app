import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for key-value persistence (theme mode, onboarding
/// flag, session). Overridden in [bootstrap] with the resolved instance so the
/// rest of the app can read it synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError(
    'sharedPreferencesProvider must be overridden in bootstrap()',
  ),
);
