import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/home/domain/entities/training_plan.dart';
import 'package:camrun/features/home/domain/repositories/home_repositories.dart';

/// JSON de la API -> entidades del dominio.
///
/// Las unidades de la API son crudas —metros, segundos, centavos, ISO-8601
/// UTC— y aqui es donde dejan de serlo. Ningun `Map` cruza hacia arriba.

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;

int _i(Object? v) => (v as num?)?.toInt() ?? 0;

DateTime _fecha(Object? v) =>
    DateTime.tryParse(v as String? ?? '')?.toLocal() ?? DateTime.now();

/// Como [_fecha], pero `null` sigue siendo `null`: hay fechas que significan
/// "todavia no paso" y sustituirlas por la de hoy diria lo contrario.
DateTime? _fechaOpcional(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

Marathon marathonFrom(
  Map<String, dynamic> j, {
  Map<String, dynamic>? prediction,
}) {
  final moneda = j['currency'] as String? ?? 'BOB';
  final banda = _bandaDePronostico(prediction);
  return Marathon(
    id: j['id'] as String,
    name: j['name'] as String,
    date: _fecha(j['startsAt']),
    city: j['city'] as String? ?? '',
    country: j['country'] as String? ?? '',
    heroImageUrl: j['coverUrl'] as String? ?? '',
    paymentQrUrl: j['paymentQrUrl'] as String?,
    paymentQrInstructions: j['paymentQrInstructions'] as String?,
    distanceKm: _d(j['distanceMeters']) / 1000,
    entryFee: Money(_i(j['priceCents']) / 100, moneda),
    slotsTotal: _i(j['capacity']),
    slotsTaken: _i(j['slotsTaken']),
    status: _estado(j['registrationStatus'] as String?),
    about: j['description'] as String? ?? '',
    schedule: [
      for (final item
          in (j['schedule'] as List? ?? const []).cast<Map<String, dynamic>>())
        ScheduleItem(
          time: item['time'] as String? ?? '',
          title: item['title'] as String? ?? '',
          detail: item['detail'] as String? ?? '',
        ),
    ],
    included: [
      for (final linea in j['includes'] as List? ?? const []) '$linea',
    ],
    routePreview: _recorrido(j['routeGeoJson']),
    liveStartedAt: _fechaOpcional(j['liveStartedAt']),
    liveFinishedAt: _fechaOpcional(j['liveFinishedAt']),
    predictedFinishMin: banda?.$1,
    predictedFinishMax: banda?.$2,
    categories: [
      for (final c
          in (j['categories'] as List? ?? const []).cast<Map<String, dynamic>>())
        RaceCategory(
          id: c['id'] as String,
          label: c['name'] as String? ?? '',
          // La API no da distancia por categoria: la carrera es una sola y las
          // categorias reparten por edad y genero, no por recorrido.
          distanceKm: _d(j['distanceMeters']) / 1000,
          surcharge: Money(_i(c['extraPriceCents']) / 100, moneda),
        ),
    ],
    extras: [
      for (final e
          in (j['extras'] as List? ?? const []).cast<Map<String, dynamic>>())
        if (e['available'] as bool? ?? true)
          RaceExtra(
            id: e['id'] as String,
            label: e['name'] as String? ?? '',
            description: '',
            price: Money(_i(e['priceCents']) / 100, moneda),
          ),
    ],
  );
}

RegistrationStatus _estado(String? valor) => switch (valor) {
  'closing_soon' => RegistrationStatus.closingSoon,
  'full' => RegistrationStatus.full,
  'closed' => RegistrationStatus.closed,
  _ => RegistrationStatus.open,
};

/// GeoJSON `LineString` viene en `[lng, lat]`; el mapa los quiere al reves.
List<({double lat, double lng})> _recorrido(Object? geoJson) {
  if (geoJson is! Map) return const [];
  final coords = geoJson['coordinates'];
  if (coords is! List) return const [];
  return [
    for (final punto in coords)
      if (punto is List && punto.length >= 2)
        (lat: _d(punto[1]), lng: _d(punto[0])),
  ];
}

/// El servidor pronostica **un** numero; la tarjeta pinta un rango. El ancho
/// sale de la confianza que el propio servidor declara.
///
/// ponytail: banda fija por tramo. Si el backend acaba devolviendo su propio
/// intervalo, esto se borra y se lee tal cual.
(Duration, Duration)? _bandaDePronostico(Map<String, dynamic>? prediction) {
  final segundos = prediction?['finishTimeSeconds'] as num?;
  if (segundos == null) return null;
  final margen = switch (prediction?['confidence'] as String?) {
    'high' => 0.04,
    'low' => 0.12,
    _ => 0.08,
  };
  return (
    Duration(seconds: (segundos * (1 - margen)).round()),
    Duration(seconds: (segundos * (1 + margen)).round()),
  );
}

// ─── Plan ──────────────────────────────────────────────────────────────────

SessionType sessionTypeFrom(String? valor) => switch (valor) {
  'tempo' => SessionType.tempo,
  'intervals' => SessionType.intervals,
  'long' => SessionType.long,
  'recovery' => SessionType.recovery,
  'race' => SessionType.race,
  'rest' => SessionType.rest,
  _ => SessionType.easy,
};

PlanOverview planFrom(Map<String, dynamic> j) => PlanOverview(
  id: j['id'] as String,
  name: j['name'] as String? ?? 'Training Plan',
  totalWeeks: _i(j['totalWeeks']),
  currentWeek: (j['currentWeek'] as num?)?.toInt(),
  totalSessions: _i(j['totalSessions']),
  completedSessions: _i(j['completedSessions']),
);

/// Una sesion del plan. [progreso] solo lo sabe la tira de Home, que cruza lo
/// planificado con lo corrido; en el resto de semanas lo unico que hay es
/// hecha o no hecha.
PlannedSession sessionFrom(Map<String, dynamic> j, {double? progreso}) {
  final completada = j['status'] == 'completed';
  return PlannedSession(
    id: j['id'] as String,
    date: _fecha(j['scheduledDate']),
    type: sessionTypeFrom(j['type'] as String?),
    targetDistanceKm: _d(j['targetDistanceMeters']) / 1000,
    targetDuration: Duration(seconds: _i(j['targetDurationSeconds'])),
    targetPace: PaceRange(
      Duration(seconds: _i(j['paceMinSecPerKm'])),
      Duration(seconds: _i(j['paceMaxSecPerKm'])),
    ),
    routeName: j['description'] as String?,
    isCompleted: completada,
    completionRatio: progreso ?? (completada ? 1 : 0),
  );
}

/// Una semana cualquiera del plan, tal como la sirve
/// `/training-plans/me/current?week=`.
TrainingWeek weekFrom(Map<String, dynamic> j) {
  final sesiones = (j['sessions'] as List? ?? const [])
      .cast<Map<String, dynamic>>();
  return TrainingWeek(
    index: _i(j['week']),
    startDate: sesiones.isEmpty
        ? DateTime.now()
        : _fecha(sesiones.first['scheduledDate']),
    sessions: [for (final s in sesiones) sessionFrom(s)],
  );
}

// ─── Home ──────────────────────────────────────────────────────────────────

HomeSummary summaryFrom(Map<String, dynamic> j) {
  final maraton = j['featuredMarathon'] as Map<String, dynamic>?;
  final plan = j['plan'] as Map<String, dynamic>?;
  final planWeek = j['planWeek'] as Map<String, dynamic>?;
  final sesiones = {
    for (final s in (planWeek?['sessions'] as List? ?? const [])
        .cast<Map<String, dynamic>>())
      s['id'] as String: s,
  };

  return HomeSummary(
    featuredMarathon: maraton == null
        ? null
        : marathonFrom(
            maraton,
            prediction: j['prediction'] as Map<String, dynamic>?,
          ),
    plan: plan == null ? null : planFrom(plan),
    week: _tira(
      j['week'] as Map<String, dynamic>? ?? const {},
      _i(planWeek?['week']),
      sesiones,
    ),
    todaySession: j['todaySession'] == null
        ? null
        : sessionFrom(j['todaySession']! as Map<String, dynamic>),
  );
}

/// La tira Mon-Sun. Se construye desde `week.days` —que trae siempre las siete
/// casillas— y no desde las sesiones del plan: un dia sin sesion tambien ocupa
/// su hueco, y los kilometros corridos de verdad solo estan aqui.
TrainingWeek _tira(
  Map<String, dynamic> week,
  int indice,
  Map<String, Map<String, dynamic>> sesiones,
) {
  final dias = (week['days'] as List? ?? const []).cast<Map<String, dynamic>>();
  return TrainingWeek(
    index: indice,
    startDate: _fecha(week['weekStartsAt']),
    sessions: [
      for (final dia in dias) _casilla(dia, sesiones[dia['sessionId']]),
    ],
  );
}

PlannedSession _casilla(Map<String, dynamic> dia, Map<String, dynamic>? sesion) {
  final planificado = _d(dia['plannedDistanceMeters']);
  final corrido = _d(dia['distanceMeters']);
  final progreso = planificado > 0
      ? (corrido / planificado).clamp(0.0, 1.0)
      : (corrido > 0 ? 1.0 : 0.0);

  if (sesion != null) return sessionFrom(sesion, progreso: progreso);

  // Dia sin sesion del plan: la casilla existe igual, con lo que se corrio.
  return PlannedSession(
    id: dia['sessionId'] as String? ?? 'day-${dia['startsAt']}',
    date: _fecha(dia['startsAt']),
    type: dia['sessionType'] == null
        ? SessionType.rest
        : sessionTypeFrom(dia['sessionType'] as String?),
    targetDistanceKm: planificado / 1000,
    targetDuration: Duration.zero,
    targetPace: const PaceRange(Duration.zero, Duration.zero),
    isCompleted: dia['sessionStatus'] == 'completed',
    completionRatio: progreso,
  );
}
