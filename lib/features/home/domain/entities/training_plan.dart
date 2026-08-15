import 'package:meta/meta.dart';

enum SessionType {
  easy('Run Easy'),
  tempo('Tempo'),
  intervals('Intervals'),
  long('Long Run'),
  rest('Rest'),
  race('Race Day');

  const SessionType(this.label);
  final String label;

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

  /// `5km Run Easy`
  String get title =>
      type.isRest ? 'Rest day' : '${targetDistanceKm.round()}km ${type.label}';

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

  String get label => 'Training Week $index';

  double get plannedDistanceKm =>
      sessions.fold(0, (sum, s) => sum + s.targetDistanceKm);
}

@immutable
class TrainingPlan {
  const TrainingPlan({
    required this.id,
    required this.name,
    required this.weeks,
    required this.activeWeekIndex,
  });

  final String id;
  final String name;
  final List<TrainingWeek> weeks;
  final int activeWeekIndex;

  TrainingWeek weekAt(int index) =>
      weeks.firstWhere((w) => w.index == index, orElse: () => weeks.first);
}
