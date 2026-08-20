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
