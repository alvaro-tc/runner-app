import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceup/core/db/app_database.dart';
import 'package:paceup/core/network/interceptors.dart';
import 'package:paceup/core/network/server_clock.dart';
import 'package:paceup/core/services/location_service.dart';
import 'package:paceup/core/storage/token_storage.dart';
import 'package:paceup/core/sync/sync_service.dart';
import 'package:paceup/features/tracking/data/tracking_api.dart';
import 'package:paceup/features/tracking/data/tracking_service.dart';
import 'package:paceup/features/train/domain/entities/training_run.dart';

import '../fake_http.dart';

/// GPS de mentira: los puntos los pone el test, cuando quiere.
class _FakeLocation implements LocationService {
  final _controller = StreamController<GeoPoint>.broadcast();
  int tracks = 0;

  void emit(GeoPoint p) => _controller.add(p);

  @override
  Future<LocationPermissionOutcome> ensurePermission() async =>
      LocationPermissionOutcome.granted;

  @override
  Future<LocationPermissionOutcome> ensureBackgroundPermission() async =>
      LocationPermissionOutcome.granted;

  @override
  Future<void> openSettings({bool locationSettings = false}) async {}

  @override
  Stream<GeoPoint> track() {
    tracks++;
    return _controller.stream;
  }
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

Dio _dio(Future<ResponseBody> Function(RequestOptions) handler) =>
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
      ..httpClientAdapter = FakeAdapter(handler);

ResponseBody _sesionAbierta() => envelope({
  'session': {'id': 'sesion-1', 'startedAt': '2026-08-20T12:00:00.000Z'},
  'workout': {'id': 'w-1'},
  'ingestToken': 'token-de-ingesta',
});

GeoPoint _punto(int segundo) => GeoPoint(
  lat: -16.5 + segundo * 0.0001,
  lng: -68.13,
  timestamp: DateTime.utc(2026, 8, 20, 12, 0, segundo),
  accuracy: 6,
  speed: 3.2,
);

void main() {
  late AppDatabase db;
  late _FakeLocation gps;
  // Las filas se encolan con el reloj real, asi que las consultas miran al
  // futuro: fijar la hora aqui las dejaria fuera de plazo segun el dia.
  DateTime futuro() => DateTime.now().add(const Duration(hours: 1));

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    gps = _FakeLocation();
  });

  tearDown(() => db.close());

  TrackingService armar(
    Future<ResponseBody> Function(RequestOptions) handler, {
    Duration flushEvery = const Duration(days: 1),
  }) {
    final dio = _dio(handler);
    return TrackingService(
      db,
      TrackingApi(dio, _FakeStorage()),
      gps,
      SyncService(db, dio),
      flushEvery: flushEvery,
    );
  }

  /// Deja correr el bucle de eventos para que los puntos lleguen al servicio.
  Future<void> asentar() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  test('cada punto se guarda en local antes de intentar mandarlo', () async {
    final service = armar((o) async => _sesionAbierta());
    await service.start();
    gps
      ..emit(_punto(1))
      ..emit(_punto(2));
    await asentar();

    final pendientes = await db.duePositions(futuro());
    expect(pendientes.length, 2);
    expect(pendientes.first.sessionId, 'sesion-1');
    // El credencial viaja con la fila: la cola puede drenarse horas despues.
    expect(pendientes.first.ingestToken, 'token-de-ingesta');
    expect(pendientes.first.speed, 3.2);
  });

  test('el lote sube con el ingestToken, no con el JWT', () async {
    final autorizaciones = <String?>[];
    final service = armar((o) async {
      if (o.path.contains('/tracking/')) {
        autorizaciones.add(o.headers['Authorization'] as String?);
        return envelope({
          'accepted': 2,
          'duplicated': 0,
          'rejected': 0,
        }, status: 202);
      }
      return _sesionAbierta();
    });

    await service.start();
    gps
      ..emit(_punto(1))
      ..emit(_punto(2));
    await asentar();
    await service.flush();

    expect(autorizaciones, ['Bearer token-de-ingesta']);
    // Aceptados: ya estan en el servidor, no hace falta guardarlos dos veces.
    expect(await db.duePositions(futuro()), isEmpty);
  });

  test('sin red los puntos se quedan y esperan al backoff', () async {
    final service = armar((o) async {
      if (o.path.contains('/tracking/')) {
        throw DioException.connectionError(
          requestOptions: o,
          reason: 'sin red',
        );
      }
      return _sesionAbierta();
    });

    await service.start();
    gps.emit(_punto(1));
    await asentar();
    await service.flush();

    expect(await db.duePositions(DateTime.now()), isEmpty);
    final pendientes = await db.duePositions(
      DateTime.now().add(const Duration(hours: 1)),
    );
    expect(pendientes.single.attempts, 1);
  });

  test(
    'la sesion cerrada descarta el lote en vez de bloquear la cola',
    () async {
      final service = armar((o) async {
        if (o.path.contains('/tracking/')) {
          return errorBody('SESSION_NOT_ACTIVE', status: 409);
        }
        return _sesionAbierta();
      });

      await service.start();
      gps.emit(_punto(1));
      await asentar();
      await service.flush();

      expect(await db.duePositions(futuro()), isEmpty);
    },
  );

  test(
    'sin poder abrir sesion se graba igual y se encola el entrenamiento',
    () async {
      final service = armar(
        (o) async => throw DioException.connectionError(
          requestOptions: o,
          reason: 'nada',
        ),
      );

      expect(await service.start(), isNull);
      gps
        ..emit(_punto(1))
        ..emit(_punto(2));
      await asentar();
      await service.stop();
      await asentar();

      // No hay sesion a la que mandar puntos, pero el entrenamiento entero sube
      // por /workouts/sync en cuanto haya red.
      final pendientes = await db.dueWorkouts(futuro());
      expect(pendientes.single.payload, contains('clientPointId'));
      expect(await db.duePositions(futuro()), isEmpty);
    },
  );

  test('en pausa se apaga el GPS y no entran puntos', () async {
    final service = armar((o) async => _sesionAbierta());
    await service.start();
    await service.pause();
    gps.emit(_punto(1));
    await asentar();

    expect(await db.duePositions(futuro()), isEmpty);
    expect(gps.tracks, 1);

    await service.resume();
    expect(gps.tracks, 2);
  });

  test('descartar borra los puntos locales', () async {
    final service = armar((o) async => _sesionAbierta());
    await service.start();
    gps.emit(_punto(1));
    await asentar();
    await service.discard();

    expect(await db.duePositions(futuro()), isEmpty);
    expect(service.recorded, isEmpty);
  });

  test('el cierre sin red va a la outbox con su clave', () async {
    final service = armar((o) async {
      if (o.path.endsWith('/finish')) {
        throw DioException.connectionError(
          requestOptions: o,
          reason: 'sin red',
        );
      }
      return _sesionAbierta();
    });

    await service.start();
    gps.emit(_punto(1));
    await asentar();
    await service.stop(feeling: 4);
    await asentar();

    final encolado = (await db.dueOutbox(futuro())).single;
    expect(encolado.path, '/workouts/sessions/sesion-1/finish');
    expect(encolado.idempotencyKey, 'finish-sesion-1');
  });
}
