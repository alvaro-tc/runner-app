import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/core/services/location_service.dart';
import 'package:paceup/core/utils/route_generator.dart';
import 'package:paceup/features/home/domain/entities/training_plan.dart';
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
    this.laps,
    this.lapPace,
    this.title = 'Free run',
  });

  static const free = RunGoal(type: RunGoalType.free);

  final RunGoalType type;
  final double? distanceKm;
  final Duration? duration;
  final String? sessionId;

  /// Interval sessions show a lap tracker at the top of the map.
  final int? laps;
  final Duration? lapPace;
  final String title;
}

enum RunGoalType { free, planSession, distance, time }

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
  final String? error;

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
    RunGoalType.distance || RunGoalType.planSession =>
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
    String? error,
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

/// Owns the live run: GPS subscription, the clock, distance accumulation and
/// split generation. The UI only reads the state and calls the four verbs.
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
      state = state.copyWith(goal: goal, error: outcome.message);
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

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _gps = ref.read(locationServiceProvider).track().listen(_onPoint);
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
  }

  void resume() {
    if (state.status != RunStatus.paused) return;
    if (_pausedAt != null) {
      _pausedTotal += DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
    }
    state = state.copyWith(status: RunStatus.running);
  }

  /// Stops recording and returns the finished run, ready to be persisted.
  TrainingRun finish() {
    _teardown();
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
        RunGoalType.planSession => SessionType.easy,
        RunGoalType.distance => SessionType.easy,
        RunGoalType.time => SessionType.tempo,
        RunGoalType.free => SessionType.easy,
      },
      title: _titleFor(started),
      calories: state.calories,
    );
  }

  void discard() {
    _teardown();
    _startedAt = null;
    state = const RunSessionState.initial();
  }

  static String _titleFor(DateTime at) {
    if (at.hour < 11) return 'Morning Run';
    if (at.hour < 15) return 'Lunch Run';
    if (at.hour < 19) return 'Afternoon Run';
    return 'Evening Run';
  }
}

final runSessionProvider =
    NotifierProvider<RunSessionNotifier, RunSessionState>(
      RunSessionNotifier.new,
    );
