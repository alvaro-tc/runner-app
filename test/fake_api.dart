import 'package:dio/dio.dart';

import 'core/fake_http.dart';

/// Backend de mentira para los tests de widget: acepta cualquier credencial y
/// sirve un Home fijo.
///
/// Las fechas van **sin zona** a proposito (`2026-08-15`, no `...Z`): se
/// interpretan en la del equipo, asi que la tira Mon-Sun cae en los mismos
/// siete dias se ejecute donde se ejecute. Con instantes UTC, un golden pasaria
/// en La Paz y fallaria en Berlin.
Future<ResponseBody> fakeBackend(RequestOptions req) async {
  final path = req.path;
  if (path.startsWith('/marathons/')) return envelope(marathonDetail);
  if (path.startsWith('/registrations/') && path.endsWith('/payments')) {
    return envelope([_pago]);
  }
  // `/races/me` y su resumen caen en el switch; esto es el detalle de UNA
  // carrera, cuya clave es el id de la inscripcion.
  if (path.startsWith('/races/') && !path.startsWith('/races/me')) {
    final id = path.substring('/races/'.length);
    final carrera = misCarreras.firstWhere(
      (c) => c['registrationId'] == id,
      orElse: () => misCarreras.first,
    );
    return envelope({...carrera, ...raceDetailExtras});
  }
  return switch (path) {
    '/auth/login' || '/auth/register' => envelope({
      'accessToken': 'access-1',
      'refreshToken': 'refresh-1',
      'expiresIn': 900,
      'user': _usuario,
    }),
    '/auth/me' => envelope(_usuario),
    '/home/summary' => envelope(homeSummary),
    '/marathons' => envelope([_maraton]),
    '/races/me' => envelope(misCarreras),
    '/races/me/summary' => envelope(racesSummary),
    _ => envelope(<String, Object?>{}),
  };
}

const _usuario = {
  'id': 'u1',
  'email': 'pandu@paceup.app',
  'name': 'Pandu',
  'role': 'runner',
};

const _maraton = {
  'id': 'm1',
  'slug': 'media-maraton-santa-cruz',
  'name': 'Media Maraton Santa Cruz',
  'startsAt': '2026-09-12T10:00:00',
  'timezone': 'America/La_Paz',
  'city': 'Santa Cruz de la Sierra',
  'country': 'BO',
  'distanceMeters': 21097,
  'priceCents': 18000,
  'currency': 'BOB',
  'coverUrl': null,
  'registrationStatus': 'open',
  'capacity': 1500,
  'slotsTaken': 830,
  'slotsAvailable': 670,
  'registrationClosesAt': null,
};

/// El detalle tal como lo sirve `GET /marathons/:slug`.
const marathonDetail = {
  ..._maraton,
  'description': '21K planos por el segundo anillo.',
  'lat': -17.7833,
  'lng': -63.1821,
  'routeGeoJson': {
    'type': 'LineString',
    'coordinates': [
      [-63.1821, -17.7833],
      [-63.1801, -17.7813],
    ],
  },
  'schedule': [
    {'time': '05:00', 'title': 'Acreditacion'},
    {'time': '06:00', 'title': 'Largada 21K'},
  ],
  'includes': ['remera tecnica', 'medalla finisher'],
  'kitPickup': null,
  'categories': [
    {
      'id': 'c1',
      'name': 'General',
      'minAge': null,
      'maxAge': null,
      'gender': null,
      'extraPriceCents': 0,
    },
  ],
  'extras': [
    {
      'id': 'e1',
      'name': 'Foto profesional',
      'priceCents': 7000,
      'stock': null,
      'available': true,
    },
  ],
};

/// Lo que la lista de carreras necesita de la maraton: la API la manda
/// recortada, sin precio ni cupos.
const _maratonDeCarrera = {
  'id': 'm1',
  'slug': 'media-maraton-santa-cruz',
  'name': 'Media Maraton Santa Cruz',
  'city': 'Santa Cruz de la Sierra',
  'startsAt': '2026-09-12T10:00:00',
  'timezone': 'America/La_Paz',
  'distanceMeters': 21097,
  'coverUrl': null,
  'kitPickup': null,
};

const _maratonCorrida = {
  'id': 'm0',
  'slug': 'maraton-la-paz-3600',
  'name': 'Maraton La Paz 3600',
  'city': 'La Paz',
  'startsAt': '2026-05-10T11:00:00',
  'timezone': 'America/La_Paz',
  'distanceMeters': 42195,
  'coverUrl': null,
  'kitPickup': null,
};

/// `GET /registrations/:id/payments`. Un solo cobro, con tarjeta y cobrado.
const _pago = {
  'id': 'pay1',
  'registrationId': 'r1',
  'method': 'card',
  'status': 'paid',
  'amountCents': 22500,
  'currency': 'BOB',
  'methodDetails': {'brand': 'visa', 'last4': '4242'},
  'failureReason': null,
  'expiresAt': null,
  'paidAt': '2026-07-01T12:00:00',
  'refundedAt': null,
  'createdAt': '2026-07-01T12:00:00',
};

/// `GET /races/me`: una carrera por delante y una ya corrida.
const misCarreras = [
  {
    'registrationId': 'r1',
    'marathon': _maratonDeCarrera,
    'bibNumber': 'MSC-0042',
    'categoryName': 'General',
    'status': 'upcoming',
    'paymentStatus': 'paid',
    'registeredAt': '2026-07-01T12:00:00',
    'result': null,
  },
  {
    'registrationId': 'r0',
    'marathon': _maratonCorrida,
    'bibNumber': 'MLP-0117',
    'categoryName': 'General',
    'status': 'completed',
    'paymentStatus': 'paid',
    'registeredAt': '2026-03-02T12:00:00',
    'result': {
      'finishTimeSeconds': 14760,
      'chipTimeSeconds': 14700,
      'distanceMeters': 42195,
      'avgPaceSecPerKm': 349,
      'avgSpeedMps': 2.86,
      'elevationGainMeters': 520,
      'bestKmIndex': 12,
      'overallRank': 214,
      'categoryRank': 31,
      'finishers': 1180,
      'finishedAt': '2026-05-10T15:06:00',
      'shareCardUrl': null,
      'workoutId': 'w0',
    },
  },
];

/// Lo que el detalle agrega sobre el resumen: recorrido y parciales.
const raceDetailExtras = {
  'splits': [
    {
      'index': 0,
      'distanceMeters': 1000,
      'durationSeconds': 345,
      'paceSecPerKm': 345,
      'elevationGainMeters': 12,
    },
    {
      'index': 1,
      'distanceMeters': 1000,
      'durationSeconds': 352,
      'paceSecPerKm': 352,
      'elevationGainMeters': 18,
    },
  ],
  'checkpoints': <Object?>[],
  'routeGeoJson': {
    'type': 'LineString',
    'coordinates': [
      [-63.1821, -17.7833],
      [-63.1801, -17.7813],
    ],
  },
};

const racesSummary = {
  'racesCompleted': 1,
  'racesUpcoming': 1,
  'totalDistanceMeters': 42195,
  'totalSpentCents': 22500,
  'currency': 'BOB',
  'nextRace': null,
};

/// Semana del 10 al 16 de agosto de 2026 — la que contiene el reloj congelado
/// de `pumpApp` (sabado 15).
final homeSummary = {
  'featuredMarathon': {
    ..._maraton,
    'registrationId': 'r1',
    'bibNumber': 'MSC-0042',
    'isRegistered': true,
  },
  'prediction': {
    'finishTimeSeconds': 7020,
    'paceSecPerKm': 333,
    'confidence': 'medium',
    'basedOn': null,
    'reason': null,
  },
  'plan': {
    'id': 'p1',
    'name': 'Media maraton en 12 semanas',
    'templateId': 't1',
    'marathonId': 'm1',
    'marathonName': 'Media Maraton Santa Cruz',
    'totalWeeks': 12,
    'startDate': '2026-07-20',
    'endDate': '2026-10-11',
    'paceBasisSecPerKm': 330,
    'status': 'active',
    'isActive': true,
    'currentWeek': 4,
    'totalSessions': 48,
    'completedSessions': 14,
  },
  'planWeek': {'week': 4, 'sessions': _sesiones},
  'todaySession': _sesiones[3],
  'week': {
    'weekStartsAt': '2026-08-10T00:00:00',
    'weekEndsAt': '2026-08-17T00:00:00',
    'timezone': 'America/La_Paz',
    'distanceMeters': 24000,
    'movingSeconds': 8100,
    'durationSeconds': 8400,
    'workouts': 3,
    'avgPaceSecPerKm': 337,
    'days': [
      for (var i = 0; i < 7; i++)
        {
          'weekday': i + 1,
          'startsAt': '2026-08-${10 + i}T00:00:00',
          'distanceMeters': _corrido[i],
          'movingSeconds': (_corrido[i] * 0.34).round(),
          'workouts': _corrido[i] > 0 ? 1 : 0,
          'plannedDistanceMeters': _planificado[i],
          'sessionId': _ids[i],
          'sessionType': _tipos[i],
          'sessionStatus': _corrido[i] > 0 ? 'completed' : 'pending',
        },
    ],
  },
};

const _ids = ['s1', null, 's3', 's4', null, 's6', null];
const _corrido = [6000, 0, 8000, 10000, 0, 0, 0];
const _planificado = [6000, null, 8000, 16000, null, 5000, null];
const _tipos = ['easy', null, 'tempo', 'long', null, 'intervals', null];

const _sesiones = [
  {
    'id': 's1',
    'week': 4,
    'weekday': 1,
    'scheduledDate': '2026-08-10',
    'type': 'easy',
    'targetDistanceMeters': 6000,
    'targetDurationSeconds': 2100,
    'paceMinSecPerKm': 340,
    'paceMaxSecPerKm': 370,
    'description': 'Rodaje suave',
    'isKeySession': false,
    'status': 'completed',
    'rescheduledFromDate': null,
    'workoutId': 'w1',
  },
  {
    'id': 's3',
    'week': 4,
    'weekday': 3,
    'scheduledDate': '2026-08-12',
    'type': 'tempo',
    'targetDistanceMeters': 8000,
    'targetDurationSeconds': 2400,
    'paceMinSecPerKm': 300,
    'paceMaxSecPerKm': 320,
    'description': 'Tempo continuo',
    'isKeySession': true,
    'status': 'completed',
    'rescheduledFromDate': null,
    'workoutId': 'w2',
  },
  {
    'id': 's4',
    'week': 4,
    'weekday': 4,
    'scheduledDate': '2026-08-13',
    'type': 'long',
    'targetDistanceMeters': 16000,
    'targetDurationSeconds': 5400,
    'paceMinSecPerKm': 360,
    'paceMaxSecPerKm': 390,
    'description': 'Fondo',
    'isKeySession': true,
    'status': 'pending',
    'rescheduledFromDate': null,
    'workoutId': null,
  },
  {
    'id': 's6',
    'week': 4,
    'weekday': 6,
    'scheduledDate': '2026-08-15',
    'type': 'intervals',
    'targetDistanceMeters': 5000,
    'targetDurationSeconds': 1800,
    'paceMinSecPerKm': 280,
    'paceMaxSecPerKm': 300,
    'description': '8 x 400',
    'isKeySession': true,
    'status': 'pending',
    'rescheduledFromDate': null,
    'workoutId': null,
  },
];
