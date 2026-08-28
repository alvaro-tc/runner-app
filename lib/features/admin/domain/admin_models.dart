import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:meta/meta.dart';

/// Una maraton vista por el panel.
///
/// No reusa `Marathon` del catalogo a proposito: aquella es lo que ve un
/// corredor —afiche, precio, cupos— y esta es lo que gestiona un admin, con
/// campos que el catalogo nunca expone (si esta publicada, cuantas
/// inscripciones lleva, si ya largo). Un solo modelo para las dos obligaria a
/// dejar la mitad de los campos nulos en cada lado.
@immutable
class AdminMarathon {
  const AdminMarathon({
    required this.id,
    required this.name,
    required this.city,
    required this.startsAt,
    required this.distanceMeters,
    required this.capacity,
    required this.slotsTaken,
    required this.priceCents,
    required this.published,
    required this.registrationsOpen,
    required this.registrations,
    this.slug = '',
    this.description,
    this.currency = 'BOB',
    this.country = 'BO',
    this.paymentQrInstructions,
    this.paymentQrPayload,
    this.route = const [],
    this.liveStartedAt,
    this.liveFinishedAt,
  });

  factory AdminMarathon.fromJson(Map<String, dynamic> json) => AdminMarathon(
    id: json['id'] as String,
    slug: json['slug'] as String? ?? '',
    name: json['name'] as String,
    city: json['city'] as String? ?? '',
    country: json['country'] as String? ?? 'BO',
    description: json['description'] as String?,
    startsAt:
        DateTime.tryParse(json['startsAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
    capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    slotsTaken: (json['slotsTaken'] as num?)?.toInt() ?? 0,
    priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
    currency: json['currency'] as String? ?? 'BOB',
    published: json['published'] as bool? ?? false,
    // La lista manda `intent`/`resolved` y el detalle `registrationStatus`. Lo
    // que le importa al panel es el interruptor: si el admin las cerro a mano.
    registrationsOpen:
        (json['intent'] ?? json['registrationStatus']) != 'closed',
    registrations: (json['registrations'] as num?)?.toInt() ?? 0,
    paymentQrInstructions: json['paymentQrInstructions'] as String?,
    paymentQrPayload: json['paymentQrPayload'] as String?,
    route: routeFromGeoJson(json['routeGeoJson']),
    liveStartedAt: DateTime.tryParse(json['liveStartedAt'] as String? ?? ''),
    liveFinishedAt: DateTime.tryParse(json['liveFinishedAt'] as String? ?? ''),
  );

  final String id;
  final String slug;
  final String name;
  final String city;
  final String country;
  final String? description;
  final DateTime startsAt;
  final int distanceMeters;
  final int capacity;
  final int slotsTaken;
  final int priceCents;
  final String currency;
  final bool published;
  final bool registrationsOpen;
  final int registrations;
  final String? paymentQrInstructions;

  /// El QR de cobro **como texto**. Vacio o `null` = esta carrera no admite el
  /// pago por QR: el checkout lo rechaza.
  final String? paymentQrPayload;

  /// El trazado oficial. Solo llega en el detalle: la lista no lo trae porque
  /// son miles de coordenadas por carrera y ahi no se pinta ningun mapa.
  final List<GeoPoint> route;

  /// Cuando el admin dio la largada de verdad, no la hora programada.
  final DateTime? liveStartedAt;
  final DateTime? liveFinishedAt;

  double get distanceKm => distanceMeters / 1000;

  /// Se esta corriendo ahora mismo.
  bool get running => liveStartedAt != null && liveFinishedAt == null;

  bool get finished => liveFinishedAt != null;

  /// Se le puede dar la largada: existe, no termino y todavia no arranco.
  bool get canStart => liveStartedAt == null && liveFinishedAt == null;
}

/// Un `LineString` GeoJSON a puntos. Las coordenadas vienen **`[lng, lat]`**,
/// que es el orden del estandar y el contrario al que uno espera leyendo.
List<GeoPoint> routeFromGeoJson(Object? geoJson) {
  if (geoJson is! Map) return const [];
  final coords = geoJson['coordinates'];
  if (coords is! List) return const [];

  final puntos = <GeoPoint>[];
  for (final par in coords) {
    if (par is! List || par.length < 2) continue;
    final lng = par[0];
    final lat = par[1];
    if (lng is! num || lat is! num) continue;
    puntos.add(
      GeoPoint(
        lat: lat.toDouble(),
        lng: lng.toDouble(),
        // El trazado oficial no tiene tiempo: es por donde hay que pasar, no
        // cuando. La fecha fija deja claro que no significa nada.
        timestamp: DateTime(2000),
      ),
    );
  }
  return puntos;
}

/// Y la vuelta: puntos a `LineString`, otra vez en `[lng, lat]`.
Map<String, dynamic> routeToGeoJson(List<GeoPoint> puntos) => {
  'type': 'LineString',
  'coordinates': [
    for (final p in puntos) [p.lng, p.lat],
  ],
};

/// Una cuenta vista por el panel.
@immutable
class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.ci,
    this.verified = false,
    this.mustChangePassword = false,
    this.registrations = 0,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    role: json['role'] as String? ?? 'runner',
    email: json['email'] as String?,
    ci: json['ci'] as String?,
    verified: json['verified'] as bool? ?? false,
    mustChangePassword: json['mustChangePassword'] as bool? ?? false,
    registrations: (json['registrations'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String name;
  final String role;
  final String? email;
  final String? ci;
  final bool verified;

  /// Entro por la web y todavia arrastra la CI como contrasena. El panel lo
  /// pinta porque es una cuenta que cualquiera con su carnet puede abrir.
  final bool mustChangePassword;

  final int registrations;
}

/// Los roles que el panel sabe asignar. En el mismo orden en que se ofrecen.
const adminRoles = <String>['admin', 'organizer', 'runner'];
