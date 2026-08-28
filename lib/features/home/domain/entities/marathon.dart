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

/// Sin etiqueta: el nombre visible sale del ARB, via `RegistrationStatusL10n`.
enum RegistrationStatus {
  open,
  closingSoon,
  full,
  closed;

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
    this.paymentQrUrl,
    this.paymentQrPayload,
    this.paymentQrInstructions,
    this.liveStartedAt,
    this.liveFinishedAt,
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

  /// Organiser's payment QR. `null` means this race cannot be paid that way, so
  /// the method must not be offered: showing it would promise a payment the
  /// server will refuse. Temporary — see `docs/pago-qr-manual.md` in the API.
  final String? paymentQrUrl;

  /// El QR **como texto**: lo dibuja la app. `null` = esta carrera no se puede
  /// pagar por QR. Es esto y no [paymentQrUrl] lo que habilita el metodo: el
  /// servidor rechaza el checkout sin texto, aunque haya imagen cargada.
  final String? paymentQrPayload;

  final String? paymentQrInstructions;

  /// Cuando el organizador dio la largada de verdad, no la hora programada.
  /// `null` = todavia no arranco. Es lo que pone en marcha la pantalla de
  /// carrera del inscrito.
  final DateTime? liveStartedAt;
  final DateTime? liveFinishedAt;

  /// Se esta corriendo ahora mismo.
  bool get isLive => liveStartedAt != null && liveFinishedAt == null;

  bool get acceptsQrPayment =>
      paymentQrPayload != null && paymentQrPayload!.isNotEmpty;

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
