import 'dart:async';
import 'dart:developer' as developer;

import 'package:drift/drift.dart' show Value;
import 'package:paceup/core/db/app_database.dart';
import 'package:paceup/core/error/failure.dart';
import 'package:paceup/core/services/location_service.dart';
import 'package:paceup/core/sync/sync_service.dart';
import 'package:paceup/core/utils/uuid.dart';
import 'package:paceup/features/tracking/data/models/tracking_models.dart';
import 'package:paceup/features/tracking/data/tracking_api.dart';
import 'package:paceup/features/train/domain/entities/training_run.dart';

/// Graba un entrenamiento: GPS dentro, puntos en la base local y lotes al
/// servidor.
///
/// **La red es opcional.** Cada punto se escribe en drift *antes* de intentar
/// mandarlo, y si la sesion remota ni siquiera pudo abrirse el entrenamiento se
/// graba igual y sube entero por `/workouts/sync` al terminar: un entrenamiento
/// perdido no se puede volver a correr.
class TrackingService {
  TrackingService(
    this._db,
    this._api,
    this._location,
    this._sync, {
    this.flushEvery = const Duration(seconds: 20),
  });

  /// Lotes de 15-30 s, nunca punto por punto: una peticion por segundo se come
  /// la bateria y no adelanta nada.
  final Duration flushEvery;

  final AppDatabase _db;
  final TrackingApi _api;
  final LocationService _location;
  final SyncService _sync;

  final _puntos = StreamController<GeoPoint>.broadcast();
  final _grabado = <GeoPoint>[];

  StreamSubscription<GeoPoint>? _gps;
  Timer? _reloj;
  StartedSession? _sesion;
  String? _clientUuid;
  DateTime? _startedAt;
  bool _pausado = false;

  /// Los puntos segun van llegando, ya filtrados. Es lo que pinta el mapa.
  Stream<GeoPoint> get stream => _puntos.stream;

  List<GeoPoint> get recorded => List.unmodifiable(_grabado);

  String? get sessionId => _sesion?.sessionId;

  bool get isRecording => _gps != null || _pausado;

  /// Abre la sesion y empieza a grabar.
  ///
  /// Devuelve `null` cuando el servidor no contesto: no es un fallo, es correr
  /// sin cobertura. Los puntos se guardan igual y suben al terminar.
  Future<StartedSession?> start({
    String type = 'free_run',
    String? planSessionId,
    String? registrationId,
    String? clientUuid,
  }) async {
    if (isRecording) return _sesion;

    _grabado.clear();
    _clientUuid = clientUuid ?? uuidV4();
    _startedAt = DateTime.now().toUtc();

    try {
      _sesion = await _api.start(
        clientUuid: _clientUuid!,
        type: type,
        planSessionId: planSessionId,
        registrationId: registrationId,
        startedAt: _startedAt,
      );
    } on Failure catch (e) {
      _sesion = null;
      developer.log(
        'sesion sin abrir, se graba en local: $e',
        name: 'tracking',
      );
    }

    _pausado = false;
    _gps = _location.track().listen(_onPoint);
    _reloj = Timer.periodic(flushEvery, (_) => unawaited(flush()));
    return _sesion;
  }

  /// Corta el GPS entero: en pausa no hay nada que muestrear, y el sensor
  /// apagado ahorra mas bateria que cualquier `distanceFilter`.
  Future<void> pause() async {
    if (_pausado || _gps == null) return;
    _pausado = true;
    await _gps?.cancel();
    _gps = null;
    await flush();
    await _avisar('pause');
  }

  Future<void> resume() async {
    if (!_pausado) return;
    _pausado = false;
    _gps = _location.track().listen(_onPoint);
    await _avisar('resume');
  }

  /// Cierra la grabacion. Con sesion remota, el servidor calcula las metricas
  /// desde los puntos que recibio; sin ella, el entrenamiento entero se encola
  /// para `/workouts/sync`.
  Future<void> stop({int? feeling, String? notes}) async {
    _apagarSensores();
    await flush();

    final sesion = _sesion;
    if (sesion == null) {
      await _queueWorkout(ended: DateTime.now().toUtc());
    } else {
      try {
        await _api.finish(sesion.sessionId, feeling: feeling, notes: notes);
      } on Failure catch (e) {
        // El cierre no puede perderse por un corte de red: a la outbox, que lo
        // reintenta con la misma clave hasta que entre.
        developer.log('cierre encolado: $e', name: 'tracking');
        await _db.enqueue(
          method: 'POST',
          path: '/workouts/sessions/${sesion.sessionId}/finish',
          body: {'feeling': ?feeling, 'notes': ?notes},
          idempotencyKey: 'finish-${sesion.sessionId}',
        );
      }
    }

    _sesion = null;
    unawaited(_sync.drain());
  }

  /// Tira la grabacion. Lo local se borra tambien: guardar los puntos de algo
  /// que el usuario descarto es guardar su ubicacion sin motivo.
  Future<void> discard() async {
    _apagarSensores();

    if (_sesion != null) {
      await _db.deletePositions(_grabado.map(_pointId));
      await _avisar('discard');
    }
    _grabado.clear();
    _sesion = null;
  }

  /// Manda lo pendiente ya, sin esperar al siguiente tic. La cola —y su
  /// backoff— la lleva [SyncService]: un solo sitio que sepa reintentar.
  Future<void> flush() async {
    // Sin sesion remota no hay a donde mandar puntos, pero el entrenamiento se
    // va guardando por si la app muere a mitad.
    if (_sesion == null) {
      if (_grabado.isNotEmpty) await _queueWorkout();
      return;
    }
    await _sync.drain();
  }

  Future<void> dispose() async {
    _reloj?.cancel();
    await _gps?.cancel();
    await _puntos.close();
  }

  // ─── Interno ─────────────────────────────────────────────────────────────

  void _apagarSensores() {
    _reloj?.cancel();
    _reloj = null;
    unawaited(_gps?.cancel());
    _gps = null;
    _pausado = false;
  }

  Future<void> _onPoint(GeoPoint p) async {
    if (_pausado) return;
    _grabado.add(p);
    _puntos.add(p);

    // Primero la base, despues la red. Siempre en ese orden.
    final sesion = _sesion;
    if (sesion == null) return;
    await _db.queuePositions([
      PendingPositionsCompanion.insert(
        clientPointId: _pointId(p),
        sessionId: sesion.sessionId,
        ingestToken: sesion.ingestToken,
        recordedAt: p.timestamp.toUtc(),
        lat: p.lat,
        lng: p.lng,
        altitude: Value(p.altitude),
        speed: Value(p.speed),
        accuracy: Value(p.accuracy),
        heading: Value(p.heading),
        nextAttemptAt: DateTime.now(),
      ),
    ]);
  }

  /// El id de un punto es el uuid de la grabacion y su milisegundo: no hace
  /// falta llevar un contador, y reenviar el mismo punto es inofensivo.
  String _pointId(GeoPoint p) =>
      '$_clientUuid-${p.timestamp.toUtc().millisecondsSinceEpoch}';

  Future<void> _queueWorkout({DateTime? ended}) => _db.queueWorkout(
    clientUuid: _clientUuid!,
    payload: {
      'clientUuid': _clientUuid,
      'startedAt': _startedAt!.toIso8601String(),
      'endedAt': (ended ?? _grabado.last.timestamp.toUtc()).toIso8601String(),
      'points': [for (final p in _grabado) _pointJson(p)],
    },
    startedAt: _startedAt!,
    idempotencyKey: _clientUuid!,
  );

  Map<String, Object?> _pointJson(GeoPoint p) => {
    'clientPointId': _pointId(p),
    'recordedAt': p.timestamp.toUtc().toIso8601String(),
    'lat': p.lat,
    'lng': p.lng,
    'altitude': p.altitude,
    'accuracy': p.accuracy,
    'speed': ?p.speed,
    'heading': ?p.heading,
  };

  /// Pausar, reanudar y descartar no valen un entrenamiento: si no hay red se
  /// encolan y ya llegaran, pero el error no sube a la UI.
  Future<void> _avisar(String que) async {
    final sesion = _sesion;
    if (sesion == null) return;
    final id = sesion.sessionId;
    try {
      await switch (que) {
        'pause' => _api.pause(id),
        'resume' => _api.resume(id),
        _ => _api.discard(id),
      };
    } on Failure catch (e) {
      developer.log('$que encolado: $e', name: 'tracking');
      await _db.enqueue(
        method: que == 'discard' ? 'DELETE' : 'PATCH',
        path: que == 'discard'
            ? '/workouts/sessions/$id'
            : '/workouts/sessions/$id/$que',
        idempotencyKey: '$que-$id',
      );
    }
  }
}
