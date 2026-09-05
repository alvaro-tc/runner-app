import 'dart:async';
import 'dart:developer' as developer;

import 'package:camrun/core/db/app_database.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/services/location_service.dart';
import 'package:camrun/core/sync/sync_service.dart';
import 'package:camrun/core/utils/uuid.dart';
import 'package:camrun/features/tracking/data/live_uploader.dart';
import 'package:camrun/features/tracking/data/models/tracking_models.dart';
import 'package:camrun/features/tracking/data/tracking_api.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';

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
    this.liveUploader,
    this.flushEvery = const Duration(seconds: 20),
    this.preferences,
  });

  static const _activeRunKey = 'tracking.activeRun';

  /// Lotes de 15-30 s, nunca punto por punto: una peticion por segundo se come
  /// la bateria y no adelanta nada.
  final Duration flushEvery;

  final AppDatabase _db;
  final TrackingApi _api;
  final LocationService _location;
  final SyncService _sync;
  final SharedPreferences? preferences;

  /// Solo se usa en maraton oficial. Ver [LiveUploader].
  final LiveUploader? liveUploader;

  final _puntos = StreamController<GeoPoint>.broadcast();
  final _grabado = <GeoPoint>[];

  StreamSubscription<GeoPoint>? _gps;
  Timer? _reloj;
  StartedSession? _sesion;
  String? _clientUuid;
  DateTime? _startedAt;
  bool _pausado = false;

  /// Traccar se hizo cargo de subir: esta grabacion no encola ni un punto, o
  /// entrarian dos veces.
  bool _viaTraccar = false;

  /// Con que se llamo a [start]. Se guarda para poder **reintentar** la sesion
  /// remota de una carrera que no pudo abrirse: ver [flush].
  ({String type, String? planSessionId, String? registrationId, bool live})?
  _args;

  /// Los puntos segun van llegando, ya filtrados. Es lo que pinta el mapa.
  Stream<GeoPoint> get stream => _puntos.stream;

  List<GeoPoint> get recorded => List.unmodifiable(_grabado);

  String? get sessionId => _sesion?.sessionId;

  String? get clientUuid => _clientUuid;

  bool get isRecording => _gps != null || _pausado;

  /// Metadata needed to diagnose and recover points after the Dart process is
  /// recreated. The points themselves remain in Drift with their ingest token.
  Map<String, String>? get activeRun => _readActiveRun();

  /// Abre la sesion y empieza a grabar.
  ///
  /// Devuelve `null` cuando el servidor no contesto: no es un fallo, es correr
  /// sin cobertura. Los puntos se guardan igual y suben al terminar.
  Future<StartedSession?> start({
    String type = 'free_run',
    String? planSessionId,
    String? registrationId,
    String? clientUuid,
    bool live = false,
  }) async {
    if (isRecording) return _sesion;

    _grabado.clear();
    _args = (
      type: type,
      planSessionId: planSessionId,
      registrationId: registrationId,
      live: live,
    );

    // Una carrera que seguia abierta cuando la app murio se **retoma**, con su
    // mismo `clientUuid`: el servidor devuelve esa sesion en vez de rechazar la
    // nueva por `SESSION_ALREADY_ACTIVE`. Sin esto, quien reabre la app a mitad
    // de maraton —el sistema mata la app en dos horas de bolsillo— desaparece
    // del mapa del organizador y termina como un entrenamiento suelto.
    final anterior = registrationId == null ? null : _retomable(registrationId);
    _clientUuid = clientUuid ?? anterior?['clientUuid'] ?? uuidV4();
    _startedAt =
        DateTime.tryParse(anterior?['startedAt'] ?? '')?.toUtc() ??
        DateTime.now().toUtc();

    _sesion = await _abrirSesion();
    // Sin sesion remota no hay nada que Traccar pueda alimentar —el backend
    // resuelve el dispositivo a su sesion activa y aqui no la hay—, asi que el
    // entrenamiento se graba en local y sube entero al terminar.
    _viaTraccar =
        live && _sesion != null && (await liveUploader?.start() ?? false);

    _pausado = false;
    await _saveActiveRun();
    _gps = _location.track().listen(_onPoint);
    _reloj = Timer.periodic(flushEvery, (_) => unawaited(flush()));
    return _sesion;
  }

  /// La grabacion que quedo abierta para esta misma inscripcion, o `null`.
  ///
  /// Solo cuenta si llego a tener sesion en el servidor: sin `sessionId` no hay
  /// nada que retomar, y un uuid viejo solo serviria para heredar sus puntos.
  Map<String, String>? _retomable(String registrationId) {
    final activa = _readActiveRun();
    if (activa == null || (activa['sessionId'] ?? '').isEmpty) return null;
    return activa['registrationId'] == registrationId ? activa : null;
  }

  /// Abre la sesion remota con lo que se guardo en [_args], o `null` si el
  /// servidor no contesto.
  Future<StartedSession?> _abrirSesion() async {
    final args = _args!;
    Future<StartedSession> abrir() => _api.start(
      clientUuid: _clientUuid!,
      type: args.type,
      planSessionId: args.planSessionId,
      registrationId: args.registrationId,
      startedAt: _startedAt,
    );

    try {
      return await abrir();
    } on Failure catch (e) {
      // Una sesion vieja sin cerrar —un entrenamiento que se quedo a medias—
      // bloquea la nueva: el servidor solo admite una por usuario. En una
      // carrera eso significa correr fuera del mapa y terminar como
      // entrenamiento, asi que se cierra la vieja y se reintenta. En un
      // entrenamiento no se toca nada: no vale cerrarle al usuario algo a sus
      // espaldas por una salida que sube igual al terminar.
      final bloqueante =
          args.registrationId != null &&
              e is ApiFailure &&
              e.code == ApiErrorCode.sessionAlreadyActive
          ? (e.firstDetail?['sessionId'] as String?)
          : null;
      if (bloqueante == null) {
        developer.log(
          'sesion sin abrir, se graba en local: $e',
          name: 'tracking',
        );
        return null;
      }
      try {
        await _api.finish(bloqueante);
        return await abrir();
      } on Failure catch (otro) {
        developer.log('la sesion vieja no dejo sitio: $otro', name: 'tracking');
        return null;
      }
    }
  }

  /// Corta el GPS entero: en pausa no hay nada que muestrear, y el sensor
  /// apagado ahorra mas bateria que cualquier `distanceFilter`.
  Future<void> pause() async {
    if (_pausado || _gps == null) return;
    _pausado = true;
    await _gps?.cancel();
    _gps = null;
    if (_viaTraccar) await liveUploader?.stop();
    await flush();
    await _avisar('pause');
  }

  Future<void> resume() async {
    if (!_pausado) return;
    _pausado = false;
    _gps = _location.track().listen(_onPoint);
    if (_viaTraccar) await liveUploader?.start();
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
      // ponytail: una carrera que nunca abrio sesion sube por /workouts/sync,
      // que no tiene donde llevar la inscripcion, y queda como entrenamiento.
      // Antes que perderla, se guarda. Se arregla el dia que /workouts/sync
      // acepte registrationId; el reintento de [flush] hace que casi nunca
      // llegue aqui.
      await _queueWorkout(ended: DateTime.now().toUtc());
    } else {
      try {
        await _api.finish(sesion.sessionId, feeling: feeling, notes: notes);
      } on Failure catch (e) {
        // El servidor pudo cerrarla el: en la maraton oficial cierra la carrera
        // en cuanto el GPS dice que el corredor cruzo la meta, porque el
        // telefono puede estar en un bolsillo o sin bateria. Reintentar eso
        // seria pelearse con la outbox por algo que ya esta hecho.
        if (e is ApiFailure && e.code == ApiErrorCode.sessionNotActive) {
          developer.log('sesion ya cerrada en el servidor', name: 'tracking');
          _sesion = null;
          await _clearActiveRun();
          unawaited(_sync.drain());
          return;
        }
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
    await _clearActiveRun();
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
    await _clearActiveRun();
  }

  /// Manda lo pendiente ya, sin esperar al siguiente tic. La cola —y su
  /// backoff— la lleva [SyncService]: un solo sitio que sepa reintentar.
  Future<void> flush() async {
    // Una carrera sin sesion remota es un corredor invisible para el
    // organizador y un resultado oficial que se pierde, asi que se reintenta en
    // cada lote hasta que entre: un corte de red justo en la largada no puede
    // convertir la maraton en un entrenamiento. Una salida normal no lo
    // necesita, sube entera al terminar.
    if (_sesion == null && _args?.registrationId != null && isRecording) {
      _sesion = await _abrirSesion();
      if (_sesion != null) {
        // El borrador local ya no vale: sus puntos van ahora a la sesion, y
        // dejarlo encolado subiria la carrera **otra vez** como entrenamiento.
        await _db.deletePendingWorkout(_clientUuid!);
        await _saveActiveRun();
        await _encolar(_grabado);
        _viaTraccar = _args!.live && (await liveUploader?.start() ?? false);
      }
    }

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

  Map<String, String>? _readActiveRun() {
    final value = preferences?.getString(_activeRunKey);
    if (value == null) return null;
    final parts = value.split('|');
    if (parts.length < 3) return null;
    return {
      'clientUuid': parts[0],
      'startedAt': parts[1],
      'sessionId': parts[2],
      // Vacio en un entrenamiento. Es lo que decide si una grabacion se puede
      // retomar: ver [_retomable].
      'registrationId': parts.length > 3 ? parts[3] : '',
    };
  }

  Future<void> _saveActiveRun() async {
    final storedPreferences = preferences;
    if (storedPreferences == null) return;
    await storedPreferences.setString(
      _activeRunKey,
      '$_clientUuid|${_startedAt!.toIso8601String()}'
      '|${_sesion?.sessionId ?? ''}|${_args?.registrationId ?? ''}',
    );
  }

  Future<void> _clearActiveRun() async {
    await preferences?.remove(_activeRunKey);
  }

  // ─── Interno ─────────────────────────────────────────────────────────────

  void _apagarSensores() {
    if (_viaTraccar) unawaited(liveUploader?.stop());
    _viaTraccar = false;
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
    await _encolar([p]);
  }

  /// Deja los puntos listos para subir. Con Traccar subiendo no encola nada: el
  /// stream de aqui solo pinta el mapa y calcula el ritmo en pantalla, y los
  /// que van al servidor son los suyos.
  Future<void> _encolar(Iterable<GeoPoint> puntos) async {
    final sesion = _sesion;
    if (sesion == null || _viaTraccar || puntos.isEmpty) return;
    await _db.queuePositions([
      for (final p in puntos)
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
