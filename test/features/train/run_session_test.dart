import 'dart:async';
import 'dart:convert';

import 'package:camrun/core/db/app_database.dart';
import 'package:camrun/core/network/interceptors.dart';
import 'package:camrun/core/network/server_clock.dart';
import 'package:camrun/core/services/location_service.dart';
import 'package:camrun/core/storage/token_storage.dart';
import 'package:camrun/core/sync/sync_providers.dart';
import 'package:camrun/core/sync/sync_service.dart';
import 'package:camrun/features/home/domain/entities/training_plan.dart';
import 'package:camrun/features/tracking/data/tracking_api.dart';
import 'package:camrun/features/tracking/data/tracking_service.dart';
import 'package:camrun/features/tracking/tracking_providers.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:camrun/features/train/presentation/providers/run_session_provider.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/fake_http.dart';

/// GPS de mentira: los puntos los pone el test, cuando quiere.
class _FakeLocation implements LocationService {
  final _controller = StreamController<GeoPoint>.broadcast();

  /// Cuantas veces se abrio el sensor. Es el numero que delata una segunda
  /// suscripcion al GPS.
  int tracks = 0;

  void emit(GeoPoint p) => _controller.add(p);

  @override
  Future<LocationPermissionOutcome> ensurePermission() async =>
      LocationPermissionOutcome.granted;

  @override
  Future<void> openSettings({bool locationSettings = false}) async {}

  @override
  Stream<GeoPoint> track() {
    tracks++;
    return _controller.stream;
  }
}

GeoPoint _punto(int segundo, {double metros = 0}) => GeoPoint(
  lat: -16.5 + metros / 111_320,
  lng: -68.13,
  timestamp: DateTime.utc(2026, 8, 20, 12, 0, segundo),
  accuracy: 6,
  speed: 3.2,
);

/// La sesion en marcha: reloj y estadisticas en la UI, GPS y subida en
/// [TrackingService].
///
/// Lo que se prueba es la costura entre los dos, que es donde estaba el hueco:
/// antes el notifier abria su propio GPS y **nada de lo que se corria llegaba
/// al servidor**.
void main() {
  late AppDatabase db;
  late _FakeLocation gps;
  late List<RequestOptions> llamadas;
  late ProviderContainer container;

  /// Deja correr el bucle de eventos para que los puntos lleguen.
  Future<void> asentar() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  ProviderContainer armar({
    Future<ResponseBody> Function(RequestOptions)? handler,
  }) {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    gps = _FakeLocation();
    llamadas = [];

    final dio =
        Dio(
            BaseOptions(
              baseUrl: 'http://test',
              validateStatus: (s) => s != null && s < 400,
            ),
          )
          ..interceptors.addAll([
            EnvelopeInterceptor(ServerClock()),
            ErrorInterceptor(),
          ])
          ..httpClientAdapter = FakeAdapter((req) {
            llamadas.add(req);
            return (handler ?? _sesionAbierta)(req);
          });

    final service = TrackingService(
      db,
      TrackingApi(dio, _FakeStorage()),
      gps,
      SyncService(db, dio),
      // Un dia: el envio por lotes no es lo que se prueba aqui.
      flushEvery: const Duration(days: 1),
    );

    final c = ProviderContainer(
      overrides: [
        trackingServiceProvider.overrideWithValue(service),
        appDatabaseProvider.overrideWithValue(db),
        locationServiceProvider.overrideWithValue(gps),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await service.dispose();
      await db.close();
    });

    return c;
  }

  Map<String, dynamic> cuerpo(RequestOptions req) => req.data is String
      ? jsonDecode(req.data as String) as Map<String, dynamic>
      : (req.data as Map).cast<String, dynamic>();

  /// La cuenta atras son tres segundos reales. Se salta con `pump` falso: aqui
  /// no hay `WidgetTester`, asi que se espera de verdad.
  Future<void> arrancar(RunGoal goal) async {
    unawaited(container.read(runSessionProvider.notifier).start(goal));
    await Future<void>.delayed(const Duration(milliseconds: 3400));
  }

  setUp(() => container = armar());

  test('un entrenamiento suelto abre sesion en el servidor', () async {
    await arrancar(RunGoal.free);

    final arranque = llamadas.firstWhere((r) => r.path == '/workouts/sessions');
    expect(cuerpo(arranque)['type'], 'free_run');
    // Sin inscripcion: es un entrenamiento, no una carrera.
    expect(cuerpo(arranque).containsKey('registrationId'), isFalse);
  });

  test('una carrera manda el id de la inscripcion al arrancar', () async {
    await arrancar(
      RunGoal.race(
        registrationId: 'reg1',
        title: 'Maraton de prueba',
        distanceKm: 42.195,
      ),
    );

    final arranque = llamadas.firstWhere((r) => r.path == '/workouts/sessions');
    // Es lo unico que convierte la sesion en carrera del lado del servidor.
    expect(cuerpo(arranque)['registrationId'], 'reg1');
    expect(cuerpo(arranque)['type'], 'race');
  });

  test(
    'los puntos del GPS llegan a la UI y a la base, con una sola suscripcion',
    () async {
      await arrancar(RunGoal.free);

      gps
        ..emit(_punto(1))
        ..emit(_punto(2, metros: 100));
      await asentar();

      final state = container.read(runSessionProvider);
      expect(state.route, hasLength(2));
      expect(state.distanceKm, closeTo(0.1, 0.005));

      // Una sola: el notifier se cuelga del stream del servicio en vez de abrir
      // su propio `track()`. Dos suscripciones serian el doble de bateria y dos
      // series de puntos que no cuadran.
      expect(gps.tracks, 1);

      final pendientes = await db.duePositions(
        DateTime.now().add(const Duration(hours: 1)),
      );
      expect(pendientes, hasLength(2));
      expect(pendientes.first.sessionId, 'sesion-1');
    },
  );

  test('cerrar la sesion la cierra tambien en el servidor', () async {
    await arrancar(RunGoal.free);
    gps.emit(_punto(1));
    await asentar();

    final run = await container
        .read(runSessionProvider.notifier)
        .finish(feeling: 4);

    expect(run.type, SessionType.easy);
    expect(
      llamadas.any((r) => r.path == '/workouts/sessions/sesion-1/finish'),
      isTrue,
    );
  });

  test('una carrera se guarda como carrera en el historial', () async {
    await arrancar(
      RunGoal.race(
        registrationId: 'reg1',
        title: 'Maraton de prueba',
        distanceKm: 42.195,
      ),
    );
    gps.emit(_punto(1));
    await asentar();

    final run = await container.read(runSessionProvider.notifier).finish();

    expect(run.type, SessionType.race);
  });

  test('descartar borra los puntos y avisa al servidor', () async {
    await arrancar(RunGoal.free);
    gps.emit(_punto(1));
    await asentar();

    await container.read(runSessionProvider.notifier).discard();
    await asentar();

    // Los puntos de algo que el usuario tiro no se guardan en ningun sitio.
    final pendientes = await db.duePositions(
      DateTime.now().add(const Duration(hours: 1)),
    );
    expect(pendientes, isEmpty);
    expect(container.read(runSessionProvider).status, RunStatus.idle);
  });

  test('sin permiso de ubicacion no se abre ninguna sesion', () async {
    // El permiso se comprueba ANTES de tocar el GPS o la red: sin el, no se
    // abre sesion en el servidor ni se enciende el sensor.
    final c = ProviderContainer(
      overrides: [
        trackingServiceProvider.overrideWithValue(
          container.read(trackingServiceProvider),
        ),
        locationServiceProvider.overrideWithValue(_SinPermiso()),
      ],
    );
    addTearDown(c.dispose);

    await c.read(runSessionProvider.notifier).start(RunGoal.free);

    final state = c.read(runSessionProvider);
    expect(state.status, RunStatus.idle);
    expect(state.error, isNotNull);
    expect(llamadas, isEmpty);
    expect(gps.tracks, 0);
  });
}

class _SinPermiso extends _FakeLocation {
  @override
  Future<LocationPermissionOutcome> ensurePermission() async =>
      LocationPermissionOutcome.denied;
}

class _FakeStorage implements TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'access';

  @override
  Future<String?> readRefreshToken() async => 'refresh';

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<void> clearTokens() async {}

  @override
  Future<String> deviceId() async => 'device-1';
}

Future<ResponseBody> _sesionAbierta(RequestOptions req) async => envelope({
  'session': {'id': 'sesion-1', 'startedAt': '2026-08-20T12:00:00.000Z'},
  'workout': {'id': 'w-1'},
  'ingestToken': 'token-de-ingesta',
});
