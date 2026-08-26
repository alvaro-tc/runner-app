import 'package:meta/meta.dart';

/// Sin etiqueta: el nombre visible sale del ARB, via `GenderL10n`.
enum Gender { female, male, other, undisclosed }

@immutable
class ShoeInfo {
  const ShoeInfo({
    required this.model,
    required this.distanceKm,
    this.retireAtKm = 700,
  });

  factory ShoeInfo.fromJson(Map<String, dynamic> json) => ShoeInfo(
    model: json['model'] as String,
    distanceKm: (json['distanceKm'] as num).toDouble(),
    retireAtKm: (json['retireAtKm'] as num?)?.toDouble() ?? 700,
  );

  final String model;
  final double distanceKm;
  final double retireAtKm;

  double get wear => (distanceKm / retireAtKm).clamp(0.0, 1.0);
  bool get needsReplacing => distanceKm >= retireAtKm;

  Map<String, dynamic> toJson() => {
    'model': model,
    'distanceKm': distanceKm,
    'retireAtKm': retireAtKm,
  };
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
class HydrationStats {
  const HydrationStats({required this.daysHitTarget, this.window = 7});
  final int daysHitTarget;
  final int window;
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
    required this.primaryShoes,
    required this.injuryFlags,
    required this.sleep,
    required this.hydration,
    this.bibNumber = '0666',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    email: json['email'] as String,
    city: json['city'] as String,
    country: json['country'] as String,
    avatarUrl: json['avatarUrl'] as String,
    birthDate: DateTime.fromMillisecondsSinceEpoch(json['birthDate'] as int),
    gender: Gender.values.byName(json['gender'] as String),
    weightKg: (json['weightKg'] as num).toDouble(),
    heightCm: (json['heightCm'] as num).toDouble(),
    highlights: RunningHighlights(
      weeklyMileageKm: (json['weeklyMileageKm'] as num).toDouble(),
      longestRunKm: (json['longestRunKm'] as num).toDouble(),
    ),
    primaryShoes: ShoeInfo.fromJson(
      Map<String, dynamic>.from(json['shoes'] as Map),
    ),
    injuryFlags: json['injuryFlags'] as String,
    sleep: SleepStats(Duration(minutes: json['sleepMinutes'] as int)),
    hydration: HydrationStats(daysHitTarget: json['hydrationDays'] as int),
    bibNumber: json['bibNumber'] as String? ?? '0666',
  );

  final String id;
  final String fullName;
  final String email;
  final String city;
  final String country;
  final String avatarUrl;
  final DateTime birthDate;
  final Gender gender;
  final double weightKg;
  final double heightCm;
  final RunningHighlights highlights;
  final ShoeInfo primaryShoes;
  final String injuryFlags;
  final SleepStats sleep;
  final HydrationStats hydration;
  final String bibNumber;

  String get firstName => fullName.split(' ').first;
  String get location => '$city, $country';
  String get initials => fullName
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  int ageAt(DateTime now) {
    var age = now.year - birthDate.year;
    final hadBirthday =
        now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthday) age--;
    return age;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'city': city,
    'country': country,
    'avatarUrl': avatarUrl,
    'birthDate': birthDate.millisecondsSinceEpoch,
    'gender': gender.name,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'weeklyMileageKm': highlights.weeklyMileageKm,
    'longestRunKm': highlights.longestRunKm,
    'shoes': primaryShoes.toJson(),
    'injuryFlags': injuryFlags,
    'sleepMinutes': sleep.averageLast7Days.inMinutes,
    'hydrationDays': hydration.daysHitTarget,
    'bibNumber': bibNumber,
  };

  UserProfile copyWith({
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
    avatarUrl: avatarUrl,
    birthDate: birthDate ?? this.birthDate,
    gender: gender ?? this.gender,
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
    highlights: highlights,
    primaryShoes: primaryShoes,
    injuryFlags: injuryFlags,
    sleep: sleep,
    hydration: hydration,
    bibNumber: bibNumber,
  );
}
