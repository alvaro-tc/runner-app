import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/core/services/location_service.dart';
import 'package:paceup/core/utils/route_generator.dart';
import 'package:paceup/features/home/domain/entities/training_plan.dart';
import 'package:paceup/features/tracking/tracking_providers.dart';
import 'package:paceup/features/train/domain/entities/training_run.dart';

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

  final RunGoalType type;
  final double? distanceKm;
  final Duration? duration;
  final String? sessionId;

  /// Solo en carrera. Es lo que se manda al arrancar la sesion remota.
  final String? registrationId;

  /// El trazado oficial, para dibujarlo debajo del recorrido real y que el
  /// corredor vea si se salio.
  final List<GeoPoint> officialRoute;

  /// Interval sessions show a lap tracker at the top of the map.
  final int? laps;
  final Duration? lapPace;
  final String title;

  bool get isRace => type == RunGoalType.race;
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

  bool get isActive =>
      status == RunStatus.running || status == RunStatus.paused;

  Duration get avgPace => distanceKm < 0.01
      ? Duration.zero
      : Duration(seconds: (elapsed.inSeconds / distanceKm).round());

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

  /// Auto-pause trips after 20 s under 0.5 m/s.
  DateTime? _slowSince;

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
    );
  }

  void _tick() {
    if (state.status != RunStatus.running || _startedAt == null) return;
    final elapsed = DateTime.now().difference(_startedAt!) - _pausedTotal;
    state = state.copyWith(elapsed: elapsed, movingTime: elapsed);
  }

  void _onPoint(GeoPoint point) {
    if (state.status != RunStatus.running) return;

    final route = [...state.route, point];
    var distance = state.distanceKm;
    var pace = state.currentPace;

    if (state.route.isNotEmpty) {
      final previous = state.route.last;
      final metres = previous.distanceTo(point);
      final seconds = point.timestamp.difference(previous.timestamp).inSeconds;
      distance += metres / 1000;

      if (seconds > 0) {
        final speed = metres / seconds;
        pace = speed < 0.1
            ? Duration.zero
            : Duration(seconds: (1000 / speed).round());
        _checkAutoPause(speed);
      }
    }

    final splits = RouteGenerator.splitsOf(route);
    state = state.copyWith(
      route: route,
      distanceKm: distance,
      currentPace: pace,
      splits: splits,
      lastKmPace: splits.isEmpty ? Duration.zero : splits.last.pace,
    );
  }

  void _checkAutoPause(double speedMs) {
    if (speedMs >= 0.5) {
      _slowSince = null;
      return;
    }
    _slowSince ??= DateTime.now();
    if (DateTime.now().difference(_slowSince!) >= const Duration(seconds: 20)) {
      _slowSince = null;
      pause();
    }
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

    final started = _startedAt ?? DateTime.now();
    final elapsed = state.elapsed;
    state = state.copyWith(status: RunStatus.finished);

    return TrainingRun(
      id: 'run-${DateTime.now().millisecondsSinceEpoch}',
      startedAt: started,
      finishedAt: started.add(elapsed),
      distanceKm: state.distanceKm,
      elapsed: elapsed,
      movingTime: state.movingTime,
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
    );
  }

  /// Tira la grabacion, aqui y en el servidor. Los puntos de algo que el
  /// usuario descarto no se guardan en ningun sitio.
  Future<void> discard() async {
    _teardown();
    _startedAt = null;
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
