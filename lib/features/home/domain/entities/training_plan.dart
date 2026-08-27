import 'package:meta/meta.dart';

/// Sin etiqueta: el nombre visible sale del ARB, via `SessionTypeL10n`.
enum SessionType {
  easy,
  tempo,
  intervals,
  recovery,
  long,
  rest,
  race;

  bool get isRest => this == rest;
}

@immutable
class PaceRange {
  const PaceRange(this.min, this.max);

  final Duration min;
  final Duration max;

  bool contains(Duration pace) => pace >= min && pace <= max;
}

@immutable
class PlannedSession {
  const PlannedSession({
    required this.id,
    required this.date,
    required this.type,
    required this.targetDistanceKm,
    required this.targetDuration,
    required this.targetPace,
    required this.completionRatio,
    required this.isCompleted,
    this.routeName,
  });

  final String id;
  final DateTime date;
  final SessionType type;
  final double targetDistanceKm;
  final Duration targetDuration;
  final PaceRange targetPace;
  final String? routeName;

  /// 0..1 — drives the day ring on Home.
  final double completionRatio;
  final bool isCompleted;

  PlannedSession copyWith({double? completionRatio, bool? isCompleted}) =>
      PlannedSession(
        id: id,
        date: date,
        type: type,
        targetDistanceKm: targetDistanceKm,
        targetDuration: targetDuration,
        targetPace: targetPace,
        routeName: routeName,
        completionRatio: completionRatio ?? this.completionRatio,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

@immutable
class TrainingWeek {
  const TrainingWeek({
    required this.index,
    required this.startDate,
    required this.sessions,
  });

  /// 1-based week number inside the plan.
  final int index;
  final DateTime startDate;
  final List<PlannedSession> sessions;

  double get plannedDistanceKm =>
      sessions.fold(0, (sum, s) => sum + s.targetDistanceKm);
}

/// El plan activo **sin** sus semanas: la API las sirve de una en una
/// (`/training-plans/me/current?week=`) y traerse las dieciseis para pintar una
/// seria bajarse el plan entero en cada arranque.
@immutable
class PlanOverview {
  const PlanOverview({
    required this.id,
    required this.name,
    required this.totalWeeks,
    required this.currentWeek,
    required this.totalSessions,
    required this.completedSessions,
  });

  final String id;
  final String name;
  final int totalWeeks;

  /// `null` si el plan aun no empezo o ya termino.
  final int? currentWeek;

  final int totalSessions;
  final int completedSessions;
}
