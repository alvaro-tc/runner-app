import 'package:paceup/features/profile/domain/entities/user_profile.dart';

Map<String, dynamic> _profileJson(Map<String, dynamic> json) {
  final profile = json['profile'];
  if (profile is Map) return profile.cast<String, dynamic>();
  final user = json['user'];
  if (user is Map) return {...json, ...user.cast<String, dynamic>()};
  return json;
}

UserProfile profileFromApi(Map<String, dynamic> json) {
  final source = _profileJson(json);
  final rawBirthDate = source['birthDate'];
  final birthDate = rawBirthDate is int
      ? DateTime.fromMillisecondsSinceEpoch(rawBirthDate)
      : DateTime.parse(rawBirthDate as String);
  final rawWeight = source['weightGrams'] ?? source['weightKg'];
  final weightKg = rawWeight is int || rawWeight is double
      ? (source['weightGrams'] == null
            ? (rawWeight as num).toDouble()
            : (rawWeight as num).toDouble() / 1000)
      : 0.0;
  final shoes = source['shoes'] is Map
      ? (source['shoes'] as Map).cast<String, dynamic>()
      : <String, dynamic>{
          'model': 'Unknown',
          'distanceKm': 0,
          'retireAtKm': 700,
        };
  final sleepMinutes = source['avgSleepMinutes'] ?? source['sleepMinutes'] ?? 0;
  final hydrationDays = source['hydrationDays'] ?? 0;

  return UserProfile(
    id: source['id'] as String,
    fullName: (source['name'] ?? source['fullName']) as String,
    email: source['email'] as String,
    city: source['city'] as String? ?? '',
    country: source['country'] as String? ?? 'BO',
    avatarUrl: source['avatarUrl'] as String? ?? '',
    birthDate: birthDate,
    gender: Gender.values.byName(source['gender'] as String),
    weightKg: weightKg,
    heightCm: (source['heightCm'] as num).toDouble(),
    highlights: RunningHighlights(
      weeklyMileageKm: (source['weeklyMileageKm'] as num?)?.toDouble() ?? 0,
      longestRunKm: (source['longestRunKm'] as num?)?.toDouble() ?? 0,
    ),
    primaryShoes: ShoeInfo.fromJson(shoes),
    injuryFlags: source['injuryFlags']?.toString() ?? '',
    sleep: SleepStats(Duration(minutes: (sleepMinutes as num).toInt())),
    hydration: HydrationStats(daysHitTarget: (hydrationDays as num).toInt()),
    bibNumber:
        (source['defaultBibNumber'] ?? source['bibNumber']) as String? ??
        '0666',
  );
}

Map<String, Object?> profilePatch(UserProfile profile) => {
  'name': profile.fullName,
  'email': profile.email,
  'city': profile.city,
  'country': profile.country,
  'birthDate': profile.birthDate.toUtc().toIso8601String(),
  'gender': profile.gender.name,
  'weightGrams': (profile.weightKg * 1000).round(),
  'heightCm': profile.heightCm,
};
