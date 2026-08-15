import 'package:meta/meta.dart';

@immutable
class Money {
  const Money(this.amount, [this.currency = 'USD']);

  final double amount;
  final String currency;

  Money operator +(Money other) => Money(amount + other.amount, currency);

  static const zero = Money(0);

  @override
  bool operator ==(Object other) =>
      other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);
}

enum RegistrationStatus {
  open('Registration open'),
  closingSoon('Closing soon'),
  full('Sold out'),
  closed('Registration closed');

  const RegistrationStatus(this.label);
  final String label;

  bool get acceptsEntries => this == open || this == closingSoon;
}

@immutable
class Marathon {
  const Marathon({
    required this.id,
    required this.name,
    required this.date,
    required this.city,
    required this.country,
    required this.heroImageUrl,
    required this.distanceKm,
    required this.entryFee,
    required this.slotsTotal,
    required this.slotsTaken,
    required this.status,
    required this.about,
    required this.schedule,
    required this.included,
    required this.routePreview,
    this.predictedFinishMin,
    this.predictedFinishMax,
    this.categories = const [],
    this.extras = const [],
  });

  final String id;
  final String name;
  final DateTime date;
  final String city;
  final String country;
  final String heroImageUrl;
  final double distanceKm;
  final Money entryFee;
  final int slotsTotal;
  final int slotsTaken;
  final RegistrationStatus status;
  final String about;
  final List<ScheduleItem> schedule;
  final List<String> included;

  /// Coarse official route, used for the preview map on the detail screen.
  final List<({double lat, double lng})> routePreview;

  final Duration? predictedFinishMin;
  final Duration? predictedFinishMax;

  /// Distances the event offers, when it runs more than one.
  final List<RaceCategory> categories;
  final List<RaceExtra> extras;

  String get location => '$city, $country';
  int get slotsLeft => slotsTotal - slotsTaken;
  Duration remainingFrom(DateTime now) => date.difference(now);
}

@immutable
class ScheduleItem {
  const ScheduleItem({
    required this.time,
    required this.title,
    required this.detail,
  });

  final String time;
  final String title;
  final String detail;
}

@immutable
class RaceCategory {
  const RaceCategory({
    required this.id,
    required this.label,
    required this.distanceKm,
    required this.surcharge,
  });

  final String id;
  final String label;
  final double distanceKm;
  final Money surcharge;
}

@immutable
class RaceExtra {
  const RaceExtra({
    required this.id,
    required this.label,
    required this.description,
    required this.price,
  });

  final String id;
  final String label;
  final String description;
  final Money price;
}
