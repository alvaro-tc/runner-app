import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:paceup/core/db/app_database.dart';
import 'package:paceup/core/error/failure.dart';

/// Cuantas cosas se movieron en un drenado. Lo devuelve [SyncService.drain]
/// para que los tests —y manana un indicador en la UI— sepan que paso.
typedef SyncReport = ({
  int positionsSent,
  int positionsDropped,
  int workoutsSynced,
  int workoutsRejected,
  int outboxSent,
  int outboxDropped,
  bool pendingLeft,
});

/// Drena la cola local contra la API.
///
/// La regla de la Fase 20 en una linea: **leer de local, refrescar desde red,
/// escribir en la outbox**. Esta clase es la tercera parte.
class SyncService {
  SyncService(this._db, this._dio);

  /// Primer reintento a los 5 s; de ahi se dobla hasta media hora. Sin tope,
  /// una cola vieja se pasaria el dia despertando la radio del telefono.
  static const _baseBackoff = Duration(seconds: 5);
  static const _maxBackoff = Duration(minutes: 30);

  final AppDatabase _db;
  final Dio _dio;

  bool _drenando = false;

  static DateTime backoffFrom(DateTime now, int attempts) {
    final segundos = math.min(
      _baseBackoff.inSeconds * (1 << math.min(attempts, 10)),
      _maxBackoff.inSeconds,
    );
    return now.add(Duration(seconds: segundos));
  }

  /// Idempotente y reentrante: si ya hay un drenado en curso, no arranca otro.
  Future<SyncReport> drain({DateTime? now}) async {
    if (_drenando) {
      return const (
        positionsSent: 0,
        positionsDropped: 0,
        workoutsSynced: 0,
        workoutsRejected: 0,
        outboxSent: 0,
        outboxDropped: 0,
        pendingLeft: true,
      );
    }
    _drenando = true;
    try {
      final ahora = now ?? DateTime.now();
      // Las posiciones primero: pueden ser de una carrera que se esta
      // corriendo ahora mismo, y ahi el retraso se ve.
      final posiciones = await _drainPositions(ahora);
      final workouts = await _drainWorkouts(ahora);
      final outbox = await _drainOutbox(ahora);
      return (
        positionsSent: posiciones.$1,
        positionsDropped: posiciones.$2,
        workoutsSynced: workouts.$1,
        workoutsRejected: workouts.$2,
        outboxSent: outbox.$1,
        outboxDropped: outbox.$2,
        pendingLeft: posiciones.$3 || workouts.$3 || outbox.$3,
      );
    } finally {
      _drenando = false;
    }
  }

  // ─── Posiciones ────────────────────────────────────────────────────────────

  /// Sube un lote de puntos de **una** sesion. Reenviar es seguro: el servidor
  /// deduplica por `clientPointId`, asi que un lote repetido cuenta como
  /// `duplicated` y no duplica nada.
  Future<(int, int, bool)> _drainPositions(DateTime now) async {
    final lote = await _db.duePositions(now);
    if (lote.isEmpty) return (0, 0, false);

    final ids = lote.map((p) => p.clientPointId);
    try {
      await _dio.post<dynamic>(
        '/tracking/sessions/${lote.first.sessionId}/positions',
        data: {
          'points': [
            for (final p in lote)
              {
                'clientPointId': p.clientPointId,
                'recordedAt': p.recordedAt.toUtc().toIso8601String(),
                'lat': p.lat,
                'lng': p.lng,
                if (p.altitude != null) 'altitude': p.altitude,
                if (p.speed != null) 'speed': p.speed,
                if (p.accuracy != null) 'accuracy': p.accuracy,
                if (p.heading != null) 'heading': p.heading,
              },
          ],
        },
        // El credencial es el de la sesion, no el JWT del usuario.
        options: Options(
          headers: {'Authorization': 'Bearer ${lote.first.ingestToken}'},
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (e.error is NetworkFailure || status >= 500) {
        await _db.retryPositionsLater(
          ids,
          backoffFrom(now, lote.first.attempts),
        );
        return (0, 0, true);
      }

      // Token invalido o sesion ya cerrada: estos puntos no van a entrar
      // nunca. Se borran, porque si no bloquean la cola de las sesiones
      // siguientes para siempre.
      await _db.deletePositions(ids);
      developer.log(
        'lote de ${lote.length} puntos descartado: ${e.error ?? e}',
        name: 'sync',
      );
      return (0, lote.length, false);
    }

    // Aceptado o duplicado da igual: ya estan en el servidor, que es la fuente
    // de verdad del recorrido.
    await _db.deletePositions(ids);
    final quedan = await _db.duePositions(now, limit: 1);
    return (lote.length, 0, quedan.isNotEmpty);
  }

  // ─── Entrenamientos ────────────────────────────────────────────────────────

  Future<(int, int, bool)> _drainWorkouts(DateTime now) async {
    final lote = await _db.dueWorkouts(now);
    if (lote.isEmpty) return (0, 0, false);

    // La clave viaja en la fila mas vieja del lote: reintentar el mismo lote
    // manda la misma clave. La proteccion de verdad la da `clientUuid`, que es
    // unico en la base del servidor.
    final clave = lote.first.idempotencyKey;

    late Map<String, dynamic> respuesta;
    try {
      final res = await _dio.post<dynamic>(
        '/workouts/sync',
        data: {
          'workouts': [
            for (final w in lote) jsonDecode(w.payload) as Map<String, dynamic>,
          ],
        },
        options: Options(headers: {'Idempotency-Key': clave}),
      );
      respuesta = res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final failure = e.error;
      if (failure is SessionExpiredFailure) return (0, 0, true);
      await _db.retryWorkoutsLater(
        lote.map((w) => w.clientUuid),
        backoffFrom(now, lote.first.attempts),
      );
      return (0, 0, true);
    }

    var sincronizados = 0;
    var rechazados = 0;

    // Un fallo no tumba el lote: cada item se resuelve por separado y la
    // respuesta dice, uno a uno, que paso.
    for (final r in (respuesta['results'] as List? ?? const [])) {
      final item = r as Map<String, dynamic>;
      final uuid = item['clientUuid'] as String;
      switch (item['status'] as String?) {
        // `duplicated` no es un error: ya estaba guardado. Se cierra igual.
        case 'created' || 'duplicated':
          await _db.markWorkoutSynced(uuid, item['workoutId'] as String?);
          sincronizados++;
        case 'rejected':
          // El motivo no va a cambiar por reintentar.
          await _db.markWorkoutRejected(uuid, item['reason'] as String?);
          rechazados++;
          developer.log(
            'workout $uuid rechazado: ${item['reason']}',
            name: 'sync',
          );
      }
    }

    // Quedan mas de 50: el proximo drenado sigue por donde este se quedo.
    final quedan = await _db.dueWorkouts(now, limit: 1);
    return (sincronizados, rechazados, quedan.isNotEmpty);
  }

  // ─── Outbox ────────────────────────────────────────────────────────────────

  Future<(int, int, bool)> _drainOutbox(DateTime now) async {
    final pendientes = await _db.dueOutbox(now);
    var enviados = 0;
    var descartados = 0;

    for (final entrada in pendientes) {
      try {
        await _dio.request<dynamic>(
          entrada.path,
          data: entrada.body == null ? null : jsonDecode(entrada.body!),
          options: Options(
            method: entrada.method,
            headers: {'Idempotency-Key': entrada.idempotencyKey},
          ),
        );
        await _db.deleteOutbox(entrada.id);
        enviados++;
      } on DioException catch (e) {
        final failure = e.error;

        // Sin red o con el servidor caido: la escritura sigue siendo valida,
        // se reintenta. Y se corta el drenado, que el resto fallara igual.
        if (failure is NetworkFailure || (e.response?.statusCode ?? 0) >= 500) {
          await _db.failOutbox(
            entrada.id,
            failure?.toString() ?? 'error de red',
            backoffFrom(now, entrada.attempts),
          );
          return (enviados, descartados, true);
        }

        // La sesion murio: reintentar ahora solo gasta bateria.
        if (failure is SessionExpiredFailure) {
          return (enviados, descartados, true);
        }

        // 4xx: el servidor dijo que no, y no va a cambiar de opinion. Se
        // descarta con log; dejarla en la cola bloquearia todo lo que venga
        // detras para siempre.
        await _db.deleteOutbox(entrada.id);
        descartados++;
        developer.log(
          '${entrada.method} ${entrada.path} descartado: ${failure ?? e}',
          name: 'sync',
        );
      }
    }

    return (enviados, descartados, false);
  }
}
