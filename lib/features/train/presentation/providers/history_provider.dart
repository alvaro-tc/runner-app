import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/app/dependencies.dart';
import 'package:paceup/core/error/failure.dart';
import 'package:paceup/core/formatters/formatters.dart';
import 'package:paceup/features/home/domain/entities/training_plan.dart';
import 'package:paceup/features/train/domain/entities/training_run.dart';
import 'package:paceup/l10n/gen/app_localizations.dart';

class HistoryNotifier extends AsyncNotifier<List<TrainingRun>> {
  @override
  Future<List<TrainingRun>> build() async =>
      (await ref.watch(trainingRepositoryProvider).fetchHistory()).unwrap();

  /// Devuelve el fallo, no su mensaje: el texto se resuelve en la UI con el
  /// idioma activo.
  Future<Failure?> save(TrainingRun run) async {
    final result = await ref.read(trainingRepositoryProvider).save(run);
    return result.fold((_) {
      ref.invalidateSelf();
      return null;
    }, (failure) => failure);
  }

  Future<Failure?> delete(String id) async {
    final result = await ref.read(trainingRepositoryProvider).delete(id);
    return result.fold((_) {
      ref.invalidateSelf();
      return null;
    }, (failure) => failure);
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<TrainingRun>>(
      HistoryNotifier.new,
    );

final runProvider = Provider.family<TrainingRun?, String>((ref, id) {
  final runs = ref.watch(historyProvider).value ?? const [];
  for (final run in runs) {
    if (run.id == id) return run;
  }
  return null;
});

// ------------------------------------------------------------------ filters

/// Sin etiqueta: el nombre visible sale del ARB, via `DateRangeFilterL10n`.
enum DateRangeFilter {
  all,
  last30,
  last90;

  bool matches(DateTime date) => switch (this) {
    DateRangeFilter.all => true,
    DateRangeFilter.last30 => date.isAfter(
      DateTime.now().subtract(const Duration(days: 30)),
    ),
    DateRangeFilter.last90 => date.isAfter(
      DateTime.now().subtract(const Duration(days: 90)),
    ),
  };
}

@immutable
class HistoryFilter {
  const HistoryFilter({
    this.types = const {},
    this.range = DateRangeFilter.all,
  });

  final Set<SessionType> types;
  final DateRangeFilter range;

  bool get isEmpty => types.isEmpty && range == DateRangeFilter.all;

  HistoryFilter copyWith({Set<SessionType>? types, DateRangeFilter? range}) =>
      HistoryFilter(types: types ?? this.types, range: range ?? this.range);
}

class HistoryFilterNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() => const HistoryFilter();

  void toggleType(SessionType type) {
    final next = {...state.types};
    next.contains(type) ? next.remove(type) : next.add(type);
    state = state.copyWith(types: next);
  }

  void setRange(DateRangeFilter range) => state = state.copyWith(range: range);

  void clear() => state = const HistoryFilter();
}

final historyFilterProvider =
    NotifierProvider<HistoryFilterNotifier, HistoryFilter>(
      HistoryFilterNotifier.new,
    );

final filteredHistoryProvider = Provider<List<TrainingRun>>((ref) {
  final runs = ref.watch(historyProvider).value ?? const [];
  final filter = ref.watch(historyFilterProvider);
  return [
    for (final run in runs)
      if ((filter.types.isEmpty || filter.types.contains(run.type)) &&
          filter.range.matches(run.startedAt))
        run,
  ];
});

/// Cabeceras de la lista de historial: "esta semana", "semana pasada" y luego
/// el mes.
///
/// La seccion guarda **como** se titula, no el titulo: el mes se formatea con
/// el locale activo, asi que el texto se resuelve al pintar.
sealed class HistorySectionLabel {
  const HistorySectionLabel();

  String call(AppLocalizations t) => switch (this) {
    ThisWeekLabel() => t.trainThisWeek,
    LastWeekLabel() => t.trainLastWeek,
    MonthLabel(:final month) => Fmt.monthYear(month),
  };
}

class ThisWeekLabel extends HistorySectionLabel {
  const ThisWeekLabel();
}

class LastWeekLabel extends HistorySectionLabel {
  const LastWeekLabel();
}

class MonthLabel extends HistorySectionLabel {
  const MonthLabel(this.month);
  final DateTime month;

  @override
  bool operator ==(Object other) =>
      other is MonthLabel &&
      other.month.year == month.year &&
      other.month.month == month.month;

  @override
  int get hashCode => Object.hash(month.year, month.month);
}

@immutable
class HistorySection {
  const HistorySection({required this.label, required this.runs});
  final HistorySectionLabel label;
  final List<TrainingRun> runs;
}

final historySectionsProvider = Provider<List<HistorySection>>((ref) {
  final runs = ref.watch(filteredHistoryProvider);
  final now = DateTime.now();
  final thisWeekStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

  final buckets = <HistorySectionLabel, List<TrainingRun>>{};
  final order = <HistorySectionLabel>[];
  for (final run in runs) {
    final label = run.startedAt.isAfter(thisWeekStart)
        ? const ThisWeekLabel()
        : run.startedAt.isAfter(lastWeekStart)
        ? const LastWeekLabel()
        : MonthLabel(DateTime(run.startedAt.year, run.startedAt.month));
    if (!buckets.containsKey(label)) {
      buckets[label] = [];
      order.add(label);
    }
    buckets[label]!.add(run);
  }
  return [
    for (final label in order)
      HistorySection(label: label, runs: buckets[label]!),
  ];
});

/// Totals for the current week, shown at the top of the Train tab.
@immutable
class WeeklySummary {
  const WeeklySummary({
    required this.distanceKm,
    required this.duration,
    required this.avgPace,
    required this.sessions,
    required this.dailyDistanceKm,
  });

  final double distanceKm;
  final Duration duration;
  final Duration avgPace;
  final int sessions;

  /// Monday…Sunday, for the bar chart.
  final List<double> dailyDistanceKm;
}

final weeklySummaryProvider = Provider<WeeklySummary>((ref) {
  final runs = ref.watch(historyProvider).value ?? const [];
  final now = DateTime.now();
  final start = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));

  final week = [
    for (final r in runs)
      if (r.startedAt.isAfter(start)) r,
  ];
  final distance = week.fold<double>(0, (s, r) => s + r.distanceKm);
  final duration = week.fold(Duration.zero, (Duration s, r) => s + r.elapsed);
  final daily = List<double>.filled(7, 0);
  for (final run in week) {
    daily[run.startedAt.weekday - 1] += run.distanceKm;
  }

  return WeeklySummary(
    distanceKm: distance,
    duration: duration,
    avgPace: distance == 0
        ? Duration.zero
        : Duration(seconds: (duration.inSeconds / distance).round()),
    sessions: week.length,
    dailyDistanceKm: daily,
  );
});
