import 'dart:async';

import 'package:camrun/core/services/location_service.dart';
import 'package:camrun/core/utils/route_generator.dart';
import 'package:camrun/features/home/domain/entities/training_plan.dart';
import 'package:camrun/features/tracking/tracking_providers.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RunStatus { idle, countdown, running, paused, finished }

/// What the session was started for. Free runs have no target.
@immutable
class RunGoal {
  const RunGoal({
    required this.type,
    this.distanceKm,
    this.duration,
    this.sessionId,
    this.registrationId,
    this.marathonId,
    this.officialRoute = const [],
    this.laps,
    this.lapPace,
    this.title = '',
  });

  static const free = RunGoal(type: RunGoalType.free);

  /// Correr una maraton en la que ya se esta inscrito.
  ///
  /// [registrationId] es lo que convierte la sesion en carrera del lado del
  /// servidor: sin el, los puntos son un entrenamiento cualquiera y no salen
  /// en el mapa en vivo ni dan resultado oficial.
  factory RunGoal.race({
    required String registrationId,
    required String title,
    required double distanceKm,
    List<GeoPoint> officialRoute = const [],
  }) => RunGoal(
    type: RunGoalType.race,
    registrationId: registrationId,
    title: title,
    distanceKm: distanceKm,
    officialRoute: officialRoute,
  );

  /// La maraton oficial, la que arranca el organizador desde el panel.
  ///
  /// Es una carrera con [marathonId] puesto, y ese id es lo que **cierra la
  /// pantalla**: mientras el evento este en marcha no hay atras, ni pausa, ni
  /// descartar. Quien corre una maraton no puede tirar su tiempo oficial por
  /// tocar un boton sin querer, y el final no lo decide el —lo decide el
  /// organizador cuando corta la carrera—.
  factory RunGoal.marathon({
    required String marathonId,
    required String registrationId,
    required String title,
    required double distanceKm,
    List<GeoPoint> officialRoute = const [],
  }) => RunGoal(
    type: RunGoalType.race,
    marathonId: marathonId,
    registrationId: registrationId,
    title: title,
    distanceKm: distanceKm,
    officialRoute: officialRoute,
  );

  final RunGoalType type;
  final double? distanceKm;
  final Duration? duration;
  final String? sessionId;

  /// Solo en carrera. Es lo que se manda al arrancar la sesion remota.
  final String? registrationId;

  /// Solo en maraton oficial. Ver [RunGoal.marathon].
  final String? marathonId;

  /// El trazado oficial, para dibujarlo debajo del recorrido real y que el
  /// corredor vea si se salio.
  final List<GeoPoint> officialRoute;

  /// Interval sessions show a lap tracker at the top of the map.
  final int? laps;
  final Duration? lapPace;
  final String title;

  bool get isRace => type == RunGoalType.race;

  /// Maraton oficial en marcha: la pantalla no se puede abandonar.
  bool get isLiveMarathon => marathonId != null;
}

enum RunGoalType { free, planSession, distance, time, race }

@immutable
class RunSessionState {
  const RunSessionState({
    required this.status,
    required this.goal,
    required this.route,
    required this.distanceKm,
    required this.elapsed,
    required this.movingTime,
    required this.splits,
    required this.countdownValue,
    this.currentPace = Duration.zero,
    this.lastKmPace = Duration.zero,
    this.error,
  });

  const RunSessionState.initial()
    : status = RunStatus.idle,
      goal = RunGoal.free,
      route = const [],
      distanceKm = 0,
      elapsed = Duration.zero,
      movingTime = Duration.zero,
      splits = const [],
      countdownValue = 3,
      currentPace = Duration.zero,
      lastKmPace = Duration.zero,
      error = null;

  final RunStatus status;
  final RunGoal goal;
  final List<GeoPoint> route;
  final double distanceKm;
  final Duration elapsed;
  final Duration movingTime;
  final List<KmSplit> splits;
  final int countdownValue;
  final Duration currentPace;
  final Duration lastKmPace;

  /// El motivo por el que el GPS no arranco, como enum: el texto sale del ARB
  /// al pintarlo. Ver `LocationPermissionOutcomeL10n`.
  final LocationPermissionOutcome? error;

  /// La cuenta atras cuenta como activa: si no, salir de la pantalla durante
  /// el 3-2-1 no descarta nada y la grabacion arranca sola, sin pantalla, con
  /// el GPS abierto hasta que se cierre la app.
  bool get isActive =>
      status == RunStatus.running ||
      status == RunStatus.paused ||
      status == RunStatus.countdown;

  /// Ritmo medio sobre el tiempo **en movimiento**, y solo a partir de 100 m.
  ///
  /// Antes de eso el numero no existe: cien metros de margen de error del GPS
  /// dividido por unos segundos da ritmos de 30 min/km que no corrio nadie.
  /// `Duration.zero` se pinta como `--:--`.
  Duration get avgPace {
    final base = movingTime.inSeconds > 0 ? movingTime : elapsed;
    return distanceKm < 0.1 || base.inSeconds == 0
        ? Duration.zero
        : Duration(seconds: (base.inSeconds / distanceKm).round());
  }

  double get avgSpeedKmh =>
      elapsed.inSeconds == 0 ? 0 : distanceKm / (elapsed.inSeconds / 3600);

  double get elevationGainM => RouteGenerator.elevationGainOf(route);

  int get calories => (distanceKm * 63).round();

  GeoPoint? get lastPoint => route.isEmpty ? null : route.last;

  /// 0..1 towards the goal, or null for a free run.
  double? get goalProgress => switch (goal.type) {
    RunGoalType.distance || RunGoalType.planSession || RunGoalType.race =>
      goal.distanceKm == null
          ? null
          : (distanceKm / goal.distanceKm!).clamp(0.0, 1.0),
    RunGoalType.time =>
      goal.duration == null
          ? null
          : (elapsed.inSeconds / goal.duration!.inSeconds).clamp(0.0, 1.0),
    RunGoalType.free => null,
  };

  int get completedLaps => splits.length;

  RunSessionState copyWith({
    RunStatus? status,
    RunGoal? goal,
    List<GeoPoint>? route,
    double? distanceKm,
    Duration? elapsed,
    Duration? movingTime,
    List<KmSplit>? splits,
    int? countdownValue,
    Duration? currentPace,
    Duration? lastKmPace,
    LocationPermissionOutcome? error,
    bool clearError = false,
  }) => RunSessionState(
    status: status ?? this.status,
    goal: goal ?? this.goal,
    route: route ?? this.route,
    distanceKm: distanceKm ?? this.distanceKm,
    elapsed: elapsed ?? this.elapsed,
    movingTime: movingTime ?? this.movingTime,
    splits: splits ?? this.splits,
    countdownValue: countdownValue ?? this.countdownValue,
    currentPace: currentPace ?? this.currentPace,
    lastKmPace: lastKmPace ?? this.lastKmPace,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Lleva la sesion en marcha: el reloj, la distancia acumulada y los parciales.
///
/// **El GPS y la subida no son suyos**: los lleva [TrackingService], que abre la
/// sesion en el servidor, escribe cada punto en la base local antes de
/// intentar mandarlo y sube por lotes. Este notifier se cuelga de su stream.
///
/// Estan separados a proposito. Una grabacion no puede depender de que una
/// pantalla siga montada, y un segundo `locationService.track()` aqui abriria
/// una segunda suscripcion al GPS: el doble de bateria y dos series de puntos
/// que no cuadran entre si.
class RunSessionNotifier extends Notifier<RunSessionState> {
  StreamSubscription<GeoPoint>? _gps;
  Timer? _ticker;
  DateTime? _startedAt;
  Duration _pausedTotal = Duration.zero;
  DateTime? _pausedAt;

  /// Suma de los huecos entre puntos aceptados: el tiempo que el telefono
  /// estuvo moviendose de verdad. Ver [_onPoint].
  Duration _moving = Duration.zero;

  @override
  RunSessionState build() {
    ref.onDispose(_teardown);
    return const RunSessionState.initial();
  }

  void _teardown() {
    _gps?.cancel();
    _ticker?.cancel();
    _gps = null;
    _ticker = null;
  }

  /// Runs the 3-2-1 countdown, then starts recording.
  Future<void> start(RunGoal goal) async {
    if (state.isActive) return;

    final outcome = await ref.read(locationServiceProvider).ensurePermission();
    if (!outcome.isGranted) {
      state = state.copyWith(goal: goal, error: outcome);
      return;
    }

    state = RunSessionState(
      status: RunStatus.countdown,
      goal: goal,
      route: const [],
      distanceKm: 0,
      elapsed: Duration.zero,
      movingTime: Duration.zero,
      splits: const [],
      countdownValue: 3,
    );

    for (var i = 3; i >= 1; i--) {
      state = state.copyWith(countdownValue: i);
      await Future<void>.delayed(const Duration(seconds: 1));
      if (state.status != RunStatus.countdown) return;
    }

    _startedAt = DateTime.now();
    _pausedTotal = Duration.zero;
    _pausedAt = null;
    _moving = Duration.zero;
    state = state.copyWith(status: RunStatus.running, countdownValue: 0);

    final tracking = ref.read(trackingServiceProvider);
    // Escuchar ANTES de arrancar: el primer punto puede llegar en el mismo
    // microtask en que se abre el GPS, y perderlo se nota en el mapa.
    _gps = tracking.stream.listen(_onPoint);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    // `start` no lanza si el servidor no contesta: devuelve `null` y graba en
    // local. Correr sin cobertura tiene que funcionar igual.
    await tracking.start(
      type: goal.isRace ? 'race' : 'free_run',
      planSessionId: goal.type == RunGoalType.planSession
          ? goal.sessionId
          : null,
      registrationId: goal.registrationId,
      // Traccar solo en la maraton oficial: es la unica salida donde el
      // seguimiento en vivo importa y donde el telefono pasa horas fuera de
      // pantalla. Ver [LiveUploader].
      live: goal.isLiveMarathon,
    );
  }

  void _tick() {
    if (state.status != RunStatus.running || _startedAt == null) return;
    final elapsed = DateTime.now().difference(_startedAt!) - _pausedTotal;
    // `movingTime` no sale del reloj: lo llevan los puntos del GPS.
    state = state.copyWith(elapsed: elapsed, movingTime: _moving);
  }

  void _onPoint(GeoPoint point) {
    if (state.status != RunStatus.running) return;

    final route = [...state.route, point];
    var distance = state.distanceKm;

    if (state.route.isNotEmpty) {
      final previous = state.route.last;
      final seconds =
          point.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
      distance += previous.distanceTo(point) / 1000;
      // Un hueco largo es el sensor sin senal —un tunel, el bolsillo—, no una
      // zancada de dos minutos: cuenta como 30 s y no infla el ritmo medio.
      if (seconds > 0) {
        _moving += Duration(
          milliseconds: (seconds.clamp(0, 30) * 1000).round(),
        );
      }
    }

    final splits = RouteGenerator.splitsOf(route);
    state = state.copyWith(
      route: route,
      distanceKm: distance,
      movingTime: _moving,
      currentPace: _ritmoReciente(route),
      splits: splits,
      lastKmPace: splits.isEmpty ? Duration.zero : splits.last.pace,
    );
  }

  /// Ritmo de los ultimos 30 s, no el del ultimo par de puntos.
  ///
  /// Dos lecturas seguidas del GPS se separan por metros que el sensor tiene de
  /// error, asi que el ritmo instantaneo salta entre 2:00 y 20:00 sin que nadie
  /// cambie el paso. Una ventana corta es lo que hace que el numero se pueda
  /// leer corriendo. Devuelve cero —`--:--`— mientras no haya recorrido
  /// suficiente para que el ritmo signifique algo.
  static const _ventanaRitmo = Duration(seconds: 30);

  Duration _ritmoReciente(List<GeoPoint> route) {
    if (route.length < 2) return Duration.zero;
    final desde = route.last.timestamp.subtract(_ventanaRitmo);
    var inicio = route.length - 1;
    while (inicio > 0 && route[inicio - 1].timestamp.isAfter(desde)) {
      inicio--;
    }

    var metros = 0.0;
    for (var i = inicio + 1; i < route.length; i++) {
      metros += route[i - 1].distanceTo(route[i]);
    }
    final segundos =
        route.last.timestamp
            .difference(route[inicio].timestamp)
            .inMilliseconds /
        1000;
    if (metros < 10 || segundos <= 0) return Duration.zero;
    return Duration(seconds: (segundos * 1000 / metros).round());
  }

  void pause() {
    if (state.status != RunStatus.running) return;
    _pausedAt = DateTime.now();
    state = state.copyWith(status: RunStatus.paused);
    unawaited(ref.read(trackingServiceProvider).pause());
  }

  void resume() {
    if (state.status != RunStatus.paused) return;
    if (_pausedAt != null) {
      _pausedTotal += DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
    }
    state = state.copyWith(status: RunStatus.running);
    unawaited(ref.read(trackingServiceProvider).resume());
  }

  /// Cierra la grabacion y devuelve el entrenamiento, listo para guardar.
  ///
  /// El cierre remoto va primero: es el que consolida las metricas oficiales
  /// desde los puntos que recibio el servidor. Lo que se devuelve aqui son los
  /// numeros del telefono, que es lo que se pinta al instante y lo que queda en
  /// el historial local si no hubo red.
  Future<TrainingRun> finish({int? feeling, String? notes}) async {
    _teardown();
    await ref
        .read(trackingServiceProvider)
        .stop(feeling: feeling, notes: notes);
    final clientUuid = ref.read(trackingServiceProvider).clientUuid;

    final started = _startedAt ?? DateTime.now();
    final elapsed = state.elapsed;
    state = state.copyWith(status: RunStatus.finished);

    return TrainingRun(
      id: 'run-${DateTime.now().millisecondsSinceEpoch}',
      startedAt: started,
      finishedAt: started.add(elapsed),
      distanceKm: state.distanceKm,
      elapsed: elapsed,
      movingTime: _moving == Duration.zero ? elapsed : _moving,
      avgPacePerKm: state.avgPace,
      elevationGainM: state.elevationGainM,
      avgSpeedKmh: state.avgSpeedKmh,
      route: state.route,
      splits: state.splits,
      type: switch (state.goal.type) {
        RunGoalType.race => SessionType.race,
        RunGoalType.time => SessionType.tempo,
        RunGoalType.planSession ||
        RunGoalType.distance ||
        RunGoalType.free => SessionType.easy,
      },
      title: _titleFor(started),
      calories: state.calories,
      clientUuid: clientUuid,
    );
  }

  /// Tira la grabacion, aqui y en el servidor. Los puntos de algo que el
  /// usuario descarto no se guardan en ningun sitio.
  Future<void> discard() async {
    _teardown();
    _startedAt = null;
    _moving = Duration.zero;
    state = const RunSessionState.initial();
    await ref.read(trackingServiceProvider).discard();
  }

  /// Devuelve la **clave**, no el texto: quien la pinta la traduce al idioma
  /// activo en ese momento. Ver `RunTitleL10n`.
  static String _titleFor(DateTime at) {
    if (at.hour < 11) return RunTitleKey.morning;
    if (at.hour < 15) return RunTitleKey.lunch;
    if (at.hour < 19) return RunTitleKey.afternoon;
    return RunTitleKey.evening;
  }
}

final runSessionProvider =
    NotifierProvider<RunSessionNotifier, RunSessionState>(
      RunSessionNotifier.new,
    );
