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
    this.coverUrl,
    this.paymentQrPayload,
    this.paymentQrInstructions,
    this.route = const [],
    this.schedule = const [],
    this.includes = const [],
    this.categories = const [],
    this.extras = const [],
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
    coverUrl: json['coverUrl'] as String?,
    published: json['published'] as bool? ?? false,
    // La lista manda `intent`/`resolved` y el detalle `registrationStatus`. Lo
    // que le importa al panel es el interruptor: si el admin las cerro a mano.
    registrationsOpen:
        (json['intent'] ?? json['registrationStatus']) != 'closed',
    registrations: (json['registrations'] as num?)?.toInt() ?? 0,
    paymentQrPayload: json['paymentQrPayload'] as String?,
    paymentQrInstructions: json['paymentQrInstructions'] as String?,
    route: routeFromGeoJson(json['routeGeoJson']),
    schedule: [
      for (final fila in json['schedule'] as List? ?? const [])
        if (fila is Map) AdminScheduleItem.fromJson(fila),
    ],
    includes: [
      for (final linea in json['includes'] as List? ?? const []) '$linea',
    ],
    categories: [
      for (final fila in json['categories'] as List? ?? const [])
        if (fila is Map) AdminCategory.fromJson(fila),
    ],
    extras: [
      for (final fila in json['extras'] as List? ?? const [])
        if (fila is Map) AdminExtra.fromJson(fila),
    ],
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

  /// El afiche. Siempre una URL del servidor: desde que se sube en vez de
  /// pegarse, no hay forma de que apunte a otro sitio.
  final String? coverUrl;

  /// El **contenido** del QR de cobro, no su imagen: el movil lo redibuja
  /// desde este texto. Lo que el organizador sube es una foto, y de ella solo
  /// se guarda lo que lleva escrito dentro.
  final String? paymentQrPayload;

  final String? paymentQrInstructions;

  /// El trazado oficial. Solo llega en el detalle: la lista no lo trae porque
  /// son miles de coordenadas por carrera y ahi no se pinta ningun mapa.
  final List<GeoPoint> route;

  /// El programa del dia y lo que la inscripcion incluye. Van como `jsonb` en
  /// la maraton, asi que se guardan con el resto del formulario.
  final List<AdminScheduleItem> schedule;
  final List<String> includes;

  /// Categorias y adicionales. Son tablas aparte con su propio CRUD: se
  /// guardan al momento, no con el boton de guardar. Solo llegan en el detalle.
  final List<AdminCategory> categories;
  final List<AdminExtra> extras;

  /// Cuando el admin dio la largada de verdad, no la hora programada.
  final DateTime? liveStartedAt;
  final DateTime? liveFinishedAt;

  double get distanceKm => distanceMeters / 1000;

  /// Se esta corriendo ahora mismo.
  bool get running => liveStartedAt != null && liveFinishedAt == null;

  bool get finished => liveFinishedAt != null;

  /// Se le puede dar la largada: existe, no termino y todavia no arranco.
  bool get canStart => liveStartedAt == null && liveFinishedAt == null;

  bool get hasCover => (coverUrl ?? '').isNotEmpty;

  bool get hasPaymentQr => (paymentQrPayload ?? '').isNotEmpty;

  /// Ya paso su fecha. Separa las dos mitades de la lista del panel: lo que
  /// queda por organizar arriba, el archivo abajo.
  bool get past => startsAt.isBefore(DateTime.now());

  /// Copia con el estado cambiado, para pintar el interruptor de la lista
  /// antes de que el servidor conteste.
  AdminMarathon copyWith({bool? published, bool? registrationsOpen}) =>
      AdminMarathon(
        id: id,
        slug: slug,
        name: name,
        city: city,
        country: country,
        description: description,
        startsAt: startsAt,
        distanceMeters: distanceMeters,
        capacity: capacity,
        slotsTaken: slotsTaken,
        priceCents: priceCents,
        currency: currency,
        published: published ?? this.published,
        registrationsOpen: registrationsOpen ?? this.registrationsOpen,
        registrations: registrations,
        coverUrl: coverUrl,
        paymentQrPayload: paymentQrPayload,
        paymentQrInstructions: paymentQrInstructions,
        route: route,
        schedule: schedule,
        includes: includes,
        categories: categories,
        extras: extras,
        liveStartedAt: liveStartedAt,
        liveFinishedAt: liveFinishedAt,
      );
}

/// Una linea del programa del dia.
@immutable
class AdminScheduleItem {
  const AdminScheduleItem({
    required this.time,
    required this.title,
    this.detail = '',
  });

  factory AdminScheduleItem.fromJson(Map<dynamic, dynamic> json) =>
      AdminScheduleItem(
        time: json['time'] as String? ?? '',
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
      );

  final String time;
  final String title;
  final String detail;

  Map<String, Object?> toJson() => {
    'time': time,
    'title': title,
    if (detail.isNotEmpty) 'detail': detail,
  };
}

/// Una categoria: el mismo recorrido, distinto publico y —a veces— distinto
/// precio. El recargo se suma al precio base al inscribirse.
@immutable
class AdminCategory {
  const AdminCategory({
    required this.id,
    required this.name,
    this.extraPriceCents = 0,
  });

  factory AdminCategory.fromJson(Map<dynamic, dynamic> json) => AdminCategory(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    extraPriceCents: (json['extraPriceCents'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String name;
  final int extraPriceCents;
}

/// Un adicional comprable: remera, bolsa, foto. `stock` nulo = sin limite.
@immutable
class AdminExtra {
  const AdminExtra({
    required this.id,
    required this.name,
    this.priceCents = 0,
    this.stock,
  });

  factory AdminExtra.fromJson(Map<dynamic, dynamic> json) => AdminExtra(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
    stock: (json['stock'] as num?)?.toInt(),
  );

  final String id;
  final String name;
  final int priceCents;
  final int? stock;
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
    role: normalizeRole(json['role'] as String?),
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

/// Lo que el panel pide al listar usuarios. Todo viaja al servidor: la lista
/// llega por paginas, asi que filtrar o cortar en el cliente esconderia a quien
/// no cayera en la primera.
typedef AdminUsersQuery = ({
  String busqueda,
  String? rol,
  int pagina,
  int porPagina,
});

/// Una pagina de usuarios y cuantos hay en total con ese filtro, que es lo que
/// deja saber si hay pagina siguiente.
typedef AdminUsersPage = ({List<AdminUser> usuarios, int total});

/// Los tamanos de pagina que ofrece el selector.
const adminPageSizes = <int>[20, 50, 100];

/// Los roles que el panel sabe asignar. En el mismo orden en que se ofrecen.
const adminRoles = <String>['admin', 'organizer', 'runner'];

/// El rol tal cual lo entiende el panel. El servidor lo ha mandado en ingles y
/// en castellano segun por donde se creo la cuenta, y sin esto un
/// 'organizador' se pintaba y filtraba como corredor.
String normalizeRole(String? raw) => switch (raw?.trim().toLowerCase()) {
  'admin' || 'administrador' => 'admin',
  'organizer' || 'organizador' => 'organizer',
  _ => 'runner',
};
