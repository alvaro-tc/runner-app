import 'package:camrun/features/profile/domain/entities/user_profile.dart';

/// El servidor devuelve la cuenta arriba (`id`, `name`, `email`) y los datos de
/// atleta en `profile`. Se aplanan: quedarse solo con `profile` perderia el
/// nombre y el correo, que es justo lo que la pantalla enseña primero.
Map<String, dynamic> _flatten(Map<String, dynamic> json) {
  final profile = json['profile'];
  if (profile is Map) return {...json, ...profile.cast<String, dynamic>()};
  final user = json['user'];
  if (user is Map) return {...json, ...user.cast<String, dynamic>()};
  return json;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : const {};

double _km(Object? meters) => ((meters as num?) ?? 0).toDouble() / 1000;

List<ShoeInfo> _shoes(Object? raw) => [
  if (raw is List)
    for (final s in raw.cast<Map<String, dynamic>>())
      ShoeInfo(
        id: s['id'] as String? ?? '',
        model: [s['brand'], s['model']].whereType<String>().join(' ').trim(),
        distanceKm: _km(s['distanceMeters']),
        // Sin umbral no hay barra de desgaste posible: 700 km es el que la app
        // ya usaba por defecto.
        retireAtKm: s['alertThresholdMeters'] == null
            ? 700
            : _km(s['alertThresholdMeters']),
        isPrimary: s['isPrimary'] == true,
      ),
];

List<Injury> _injuries(Object? raw) => [
  if (raw is List)
    for (final i in raw.map(_map))
      if (i['zone'] is String)
        Injury(
          zone: i['zone'] as String,
          notes: i['notes'] as String?,
          since: i['since'] as String?,
        ),
];

/// El cuerpo de `PATCH /users/me/health`. La lista viaja entera: el servidor
/// la reescribe, no la fusiona.
Map<String, Object?> healthPatch({
  required List<Injury> injuries,
  required Duration sleep,
  required HydrationHabit hydration,
}) => {
  'injuryFlags': [
    for (final i in injuries)
      {
        'zone': i.zone,
        if (i.notes != null) 'notes': i.notes,
        if (i.since != null) 'since': i.since,
      },
  ],
  'avgSleepMinutes': sleep.inMinutes,
  'hydrationHabit': hydration.name,
};

/// El cuerpo de `POST /users/me/shoes`. El servidor parte marca y modelo, la
/// app los junta en una sola linea al leerlos.
Map<String, Object?> shoePost({
  required String brand,
  required String model,
  required double retireAtKm,
}) => {
  'brand': brand,
  'model': model,
  'alertThresholdMeters': (retireAtKm * 1000).round(),
};

UserProfile profileFromApi(Map<String, dynamic> json) {
  final source = _flatten(json);
  final highlights = _map(source['highlights']);
  final health = _map(source['health']);

  final rawBirthDate = source['birthDate'];
  final birthDate = switch (rawBirthDate) {
    final int ms => DateTime.fromMillisecondsSinceEpoch(ms),
    final String s => DateTime.tryParse(s),
    _ => null,
  };

  final rawWeight = source['weightGrams'] ?? source['weightKg'];
  final weightKg = source['weightGrams'] != null
      ? ((rawWeight as num?) ?? 0).toDouble() / 1000
      : ((rawWeight as num?) ?? 0).toDouble();

  return UserProfile(
    id: source['id'] as String,
    fullName: (source['name'] ?? source['fullName']) as String? ?? '',
    email: source['email'] as String? ?? '',
    city: source['city'] as String? ?? '',
    country: source['country'] as String? ?? 'BO',
    avatarUrl: source['avatarUrl'] as String? ?? '',
    birthDate: birthDate,
    gender: Gender.values.asNameMap()[source['gender']] ?? Gender.undisclosed,
    weightKg: weightKg,
    heightCm: ((source['heightCm'] as num?) ?? 0).toDouble(),
    highlights: RunningHighlights(
      weeklyMileageKm: _km(highlights['weekDistanceMeters']),
      longestRunKm: _km(_map(highlights['longestWorkout'])['distanceMeters']),
    ),
    shoes: _shoes(source['shoes']),
    injuries: _injuries(health['injuryFlags'] ?? source['injuryFlags']),
    sleep: SleepStats(
      Duration(
        minutes:
            ((health['avgSleepMinutes'] ?? source['avgSleepMinutes']) as num? ??
                    0)
                .toInt(),
      ),
    ),
    hydration:
        HydrationHabit.values.asNameMap()[health['hydrationHabit'] ??
            source['hydration']] ??
        HydrationHabit.moderate,
    bibNumber:
        (source['defaultBibNumber'] ?? source['bibNumber']) as String? ??
        '0666',
  );
}

ProfilePreferences preferencesFromApi(Map<String, dynamic> json) {
  final notifications = _map(json['notifications']);
  final privacy = _map(json['privacy']);
  // Los que el servidor todavia no conoce se estrenan encendidos, que es como
  // los pintaba la pantalla antes de guardarse en ningun sitio.
  bool on(Map<String, dynamic> from, String key, {bool fallback = true}) =>
      from[key] as bool? ?? fallback;
  return ProfilePreferences(
    planReminders: on(notifications, 'planReminders'),
    raceUpdates: on(notifications, 'raceReminders'),
    weeklyReport: on(notifications, 'weeklyReport', fallback: false),
    shareActivity: on(privacy, 'shareActivity', fallback: false),
    theme: json['theme'] as String? ?? 'system',
    units: json['units'] as String? ?? 'metric',
    locale: json['locale'] as String? ?? 'es',
  );
}

Map<String, Object?> preferencesPatch(ProfilePreferences prefs) => {
  'notifications': {
    'planReminders': prefs.planReminders,
    'raceReminders': prefs.raceUpdates,
    'weeklyReport': prefs.weeklyReport,
  },
  'privacy': {'shareActivity': prefs.shareActivity},
  'theme': prefs.theme,
  'units': prefs.units,
  'locale': prefs.locale,
};

/// El PATCH manda **todos** los campos del perfil, no solo los que cambiaron:
/// el servidor reescribe el bloque entero y omitir uno lo deja a null.
Map<String, Object?> profilePatch(UserProfile profile) => {
  'name': profile.fullName,
  'email': profile.email,
  'city': profile.city,
  'country': profile.country,
  'birthDate': profile.birthDate?.toUtc().toIso8601String(),
  'gender': profile.gender.name,
  'weightGrams': (profile.weightKg * 1000).round(),
  'heightCm': profile.heightCm,
};
