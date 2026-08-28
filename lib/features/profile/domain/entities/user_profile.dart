import 'package:meta/meta.dart';

/// Lo que guarda `GET/PATCH /users/me/preferences`: los interruptores de la
/// pantalla de ajustes y la apariencia (tema, unidades, idioma).
///
/// `theme`, `units` y `locale` viajan como los strings del servidor
/// (`light|dark|system`, `metric|imperial`, un tag BCP-47). El dominio no
/// conoce `ThemeMode` ni `DistanceUnit`: son tipos de Flutter.
@immutable
class ProfilePreferences {
  const ProfilePreferences({
    required this.planReminders,
    required this.raceUpdates,
    required this.weeklyReport,
    required this.shareActivity,
    required this.theme,
    required this.units,
    required this.locale,
  });

  final bool planReminders;
  final bool raceUpdates;
  final bool weeklyReport;
  final bool shareActivity;
  final String theme;
  final String units;
  final String locale;

  ProfilePreferences copyWith({
    bool? planReminders,
    bool? raceUpdates,
    bool? weeklyReport,
    bool? shareActivity,
    String? theme,
    String? units,
    String? locale,
  }) => ProfilePreferences(
    planReminders: planReminders ?? this.planReminders,
    raceUpdates: raceUpdates ?? this.raceUpdates,
    weeklyReport: weeklyReport ?? this.weeklyReport,
    shareActivity: shareActivity ?? this.shareActivity,
    theme: theme ?? this.theme,
    units: units ?? this.units,
    locale: locale ?? this.locale,
  );
}

/// Sin etiqueta: el nombre visible sale del ARB, via `GenderL10n`.
/// Los nombres son los del enum `Gender` de la API: viajan tal cual en el PATCH.
enum Gender { female, male, other, unspecified }

/// Una lesion marcada en `GET/PATCH /users/me/health`. `notes` y `since` no se
/// editan en la app, pero se conservan: el PATCH reescribe la lista entera y
/// mandarla sin ellos los borraria.
@immutable
class Injury {
  const Injury({required this.zone, this.notes, this.since});

  final String zone;
  final String? notes;
  final String? since;
}

@immutable
class RunningHighlights {
  const RunningHighlights({
    required this.weeklyMileageKm,
    required this.longestRunKm,
  });

  final double weeklyMileageKm;
  final double longestRunKm;
}

@immutable
class SleepStats {
  const SleepStats(this.averageLast7Days);
  final Duration averageLast7Days;
}

@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.city,
    required this.country,
    required this.avatarUrl,
    required this.birthDate,
    required this.gender,
    required this.weightKg,
    required this.heightCm,
    required this.highlights,
    required this.injuries,
    required this.sleep,
    this.bibNumber = '0666',
  });

  final String id;
  final String fullName;
  final String email;
  final String city;
  final String country;
  final String avatarUrl;
  final DateTime? birthDate;
  final Gender gender;
  final double weightKg;
  final double heightCm;
  final RunningHighlights highlights;
  final List<Injury> injuries;
  final SleepStats sleep;
  final String bibNumber;

  /// La ficha enseña las zonas en una linea.
  String get injuryFlags => injuries.map((i) => i.zone).join(', ');

  String get firstName => fullName.split(' ').first;
  String get location => '$city, $country';
  String get initials => fullName
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  UserProfile copyWith({
    String? avatarUrl,
    String? fullName,
    String? email,
    String? city,
    String? country,
    DateTime? birthDate,
    Gender? gender,
    double? weightKg,
    double? heightCm,
  }) => UserProfile(
    id: id,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    city: city ?? this.city,
    country: country ?? this.country,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    birthDate: birthDate ?? this.birthDate,
    gender: gender ?? this.gender,
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
    highlights: highlights,
    injuries: injuries,
    sleep: sleep,
    bibNumber: bibNumber,
  );
}
