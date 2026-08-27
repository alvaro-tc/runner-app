import 'package:camrun/core/db/app_database.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/network/interceptors.dart';
import 'package:camrun/core/network/server_clock.dart';
import 'package:camrun/core/sync/offline_first.dart';
import 'package:camrun/core/sync/sync_service.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_http.dart';

/// Dio con el minimo para que los fallos lleguen como `Failure`: el sobre y el
/// mapeo de errores. Ni auth ni refresh, que aqui no pintan nada.
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

void main() {
  late AppDatabase db;
  final ahora = DateTime.utc(2026, 8, 20, 12);

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
  });

  tearDown(() => db.close());

  Future<void> encolar({String path = '/users/me', String key = 'k1'}) =>
      db.enqueue(
        method: 'PATCH',
        path: path,
        body: {'city': 'La Paz'},
        idempotencyKey: key,
        now: ahora,
      );

  group('outbox', () {
    test('lo enviado se borra de la cola', () async {
      await encolar();
      final report = await SyncService(
        db,
        _dio((_) async => envelope({'ok': true})),
      ).drain(now: ahora);

      expect(report.outboxSent, 1);
      expect(await db.dueOutbox(ahora), isEmpty);
    });

    test('sin red se conserva, con backoff y un intento mas', () async {
      await encolar();
      final report = await SyncService(
        db,
        _dio(
          (o) async => throw DioException.connectionError(
            requestOptions: o,
            reason: 'sin red',
          ),
        ),
      ).drain(now: ahora);

      expect(report.outboxSent, 0);
      expect(report.pendingLeft, isTrue);

      // Sigue en la cola pero ya no toca: el backoff vive en la fila y
      // sobrevive a que la app se cierre.
      expect(await db.dueOutbox(ahora), isEmpty);
      final pendiente = await db.dueOutbox(ahora.add(const Duration(hours: 1)));
      expect(pendiente.single.attempts, 1);
      expect(pendiente.single.nextAttemptAt.isAfter(ahora), isTrue);
    });

    test('un 4xx se descarta: no va a cambiar por reintentar', () async {
      await encolar();
      final report = await SyncService(
        db,
        _dio((_) async => errorBody('VALIDATION_ERROR')),
      ).drain(now: ahora);

      expect(report.outboxDropped, 1);
      // Dejarla ahi bloquearia para siempre todo lo encolado detras.
      expect(await db.dueOutbox(ahora.add(const Duration(days: 1))), isEmpty);
    });

    test('la Idempotency-Key persistida es la que viaja', () async {
      await encolar(key: 'clave-guardada');
      final claves = <String?>[];
      await SyncService(
        db,
        _dio((o) async {
          claves.add(o.headers['Idempotency-Key'] as String?);
          return envelope({'ok': true});
        }),
      ).drain(now: ahora);

      expect(claves, ['clave-guardada']);
    });
  });

  group('workouts', () {
    Future<void> encolarWorkout(String uuid) => db.queueWorkout(
      clientUuid: uuid,
      payload: {'clientUuid': uuid, 'type': 'free_run'},
      startedAt: ahora,
      idempotencyKey: 'lote-1',
      now: ahora,
    );

    test(
      'created y duplicated cierran la fila; rejected no se reintenta',
      () async {
        await encolarWorkout('a');
        await encolarWorkout('b');
        await encolarWorkout('c');

        final report = await SyncService(
          db,
          _dio((o) async {
            expect(o.path, '/workouts/sync');
            expect(o.headers['Idempotency-Key'], 'lote-1');
            expect(((o.data as Map)['workouts'] as List).length, 3);
            return envelope({
              'created': 1,
              'duplicated': 1,
              'rejected': 1,
              'results': [
                {'clientUuid': 'a', 'status': 'created', 'workoutId': 'w1'},
                {'clientUuid': 'b', 'status': 'duplicated', 'workoutId': 'w2'},
                {
                  'clientUuid': 'c',
                  'status': 'rejected',
                  'reason': 'plan_missing',
                },
              ],
            });
          }),
        ).drain(now: ahora);

        expect(report.workoutsSynced, 2);
        expect(report.workoutsRejected, 1);
        // Ninguno vuelve a la cola: el rechazado tampoco, su motivo no cambia.
        expect(
          await db.dueWorkouts(ahora.add(const Duration(days: 7))),
          isEmpty,
        );
      },
    );

    test('sin red el lote entero espera y no se pierde', () async {
      await encolarWorkout('a');
      final report = await SyncService(
        db,
        _dio(
          (o) async => throw DioException.connectionError(
            requestOptions: o,
            reason: 'sin red',
          ),
        ),
      ).drain(now: ahora);

      expect(report.workoutsSynced, 0);
      expect(report.pendingLeft, isTrue);
      final pendiente = await db.dueWorkouts(
        ahora.add(const Duration(hours: 1)),
      );
      expect(pendiente.single.clientUuid, 'a');
      expect(pendiente.single.attempts, 1);
    });
  });

  group('readThrough', () {
    test('emite la cache primero y despues lo fresco', () async {
      await db.writeDoc('home', {'v': 'viejo'});

      final emitido = await readThrough<String>(
        db: db,
        key: 'home',
        fetch: () async => {'v': 'nuevo'},
        parse: (j) => j['v'] as String,
      ).toList();

      expect(emitido, ['viejo', 'nuevo']);
      expect((await db.readDoc('home'))!['v'], 'nuevo');
    });

    test('sin red pero con cache, se ve lo viejo en vez de un error', () async {
      await db.writeDoc('home', {'v': 'viejo'});

      final emitido = await readThrough<String>(
        db: db,
        key: 'home',
        fetch: () async => throw const NetworkFailure(),
        parse: (j) => j['v'] as String,
      ).toList();

      expect(emitido, ['viejo']);
    });

    test('sin red y sin cache no hay nada que ensenar: sube el fallo', () {
      expect(
        readThrough<String>(
          db: db,
          key: 'home',
          fetch: () async => throw const NetworkFailure(),
          parse: (j) => j['v'] as String,
        ).toList(),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  test('el backoff se dobla y topa en media hora', () {
    expect(
      SyncService.backoffFrom(ahora, 0).difference(ahora),
      const Duration(seconds: 5),
    );
    expect(
      SyncService.backoffFrom(ahora, 3).difference(ahora),
      const Duration(seconds: 40),
    );
    expect(
      SyncService.backoffFrom(ahora, 20).difference(ahora),
      const Duration(minutes: 30),
    );
  });
}
