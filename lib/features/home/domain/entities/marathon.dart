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

/// En que punto de su dia esta una maraton.
///
/// Se deriva de las tres fechas, igual que en el servidor: guardar ademas un
/// campo con el estado seria un segundo sitio que puede discrepar del primero.
/// Sin etiqueta: el texto sale del ARB.
enum MarathonPhase {
  /// Todavia no paso nada. Es el estado de casi todas, casi siempre.
  notStarted,

  /// El organizador cerro el kiosko: los inscritos solo ven el aviso.
  preparing,

  /// Se esta corriendo.
  inProgress,

  /// El organizador corto la carrera.
  finished;

  /// Si un inscrito en esta maraton tiene la app bloqueada.
  bool get locksEntrants => this == preparing || this == inProgress;
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
    this.paymentQrPayload,
    this.paymentQrInstructions,
    this.preparingAt,
    this.preparingMessage,
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

  /// El QR de cobro **como texto**: lo dibuja la app. `null` o vacio = esta
  /// carrera no se puede pagar por QR, y el metodo no se ofrece. No hay
  /// version imagen: el QR es texto y nada mas.
  final String? paymentQrPayload;

  final String? paymentQrInstructions;

  /// Cuando el organizador puso la carrera "en preparacion". Ver
  /// [MarathonPhase.preparing].
  final DateTime? preparingAt;

  /// El aviso que el organizador escribio para esa espera. `null` = la app
  /// pone el suyo, traducido al idioma del corredor.
  final String? preparingMessage;

  /// Cuando el organizador dio la largada de verdad, no la hora programada.
  /// `null` = todavia no arranco. Es lo que pone en marcha la pantalla de
  /// carrera del inscrito.
  final DateTime? liveStartedAt;
  final DateTime? liveFinishedAt;

  /// Se esta corriendo ahora mismo.
  bool get isLive => liveStartedAt != null && liveFinishedAt == null;

  /// El orden de las comprobaciones es el orden real del dia: una vez cortada
  /// ya da igual que estuviera corriendo.
  MarathonPhase get phase {
    if (liveFinishedAt != null) return MarathonPhase.finished;
    if (liveStartedAt != null) return MarathonPhase.inProgress;
    if (preparingAt != null) return MarathonPhase.preparing;
    return MarathonPhase.notStarted;
  }

  bool get acceptsQrPayment => paymentQrPayload?.isNotEmpty ?? false;

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
