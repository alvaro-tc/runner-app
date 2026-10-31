import 'package:camrun/app/dependencies.dart';
import 'package:camrun/features/train/domain/entities/workout_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cuantas semanas pide la tira de arriba. Ocho entran de sobra en el swipe y
/// son dos meses de contexto, que es lo que un corredor mira para saber si
/// esta subiendo o bajando el volumen.
const kHubWeeks = 8;

/// Tamano de pagina del historial. El tope del servidor es 50.
///
/// El historial no se filtra: `/workouts` acepta `?type=`, pero una barra de
/// seis chips encima de la lista pesaba mas que lo que resolvia. Si vuelve a
/// hacer falta, el sitio es [RunHistoryNotifier._fetch].
const kHubPageSize = 15;

// ───────────────────────────────────────────────────────────── semanas

final hubWeeksProvider = FutureProvider<List<WeekStats>>(
  (ref) async =>
      (await ref
              .watch(workoutLogRepositoryProvider)
              .weeklyStats(count: kHubWeeks))
          .unwrap(),
);

/// Que semana se esta mirando, como indice dentro de [hubWeeksProvider].
///
/// `null` = la ultima, o sea la semana en curso. Se guarda asi y no como un
/// numero fijo porque la lista se recarga: con un indice puesto a mano, un
/// refresco a media noche del domingo dejaria seleccionada la semana de antes.
class SelectedWeekNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int index) => state = index;
}

final selectedWeekIndexProvider = NotifierProvider<SelectedWeekNotifier, int?>(
  SelectedWeekNotifier.new,
);

final selectedWeekProvider = Provider<WeekStats?>((ref) {
  final weeks = ref.watch(hubWeeksProvider).value ?? const <WeekStats>[];
  if (weeks.isEmpty) return null;
  final index = ref.watch(selectedWeekIndexProvider) ?? weeks.length - 1;
  return weeks[index.clamp(0, weeks.length - 1)];
});

/// La meta de la semana, en kilometros.
///
/// Sale del propio historial —el mejor de los ultimos siete dias cerrados mas
/// un 10%— en vez de ser un numero que el usuario tenga que configurar: una
/// meta que nadie puso nunca se queda en cero y el anillo no dice nada. El
/// suelo de 5 km evita que la primera semana la meta sea medio kilometro.
///
/// ponytail: derivada, no configurable. Si se pide elegirla, el dia que haya
/// ajuste de usuario este provider lee de ahi y nada mas cambia.
final weeklyGoalKmProvider = Provider<double>((ref) {
  final weeks = ref.watch(hubWeeksProvider).value ?? const <WeekStats>[];
  final closed = [
    for (final week in weeks)
      if (!week.isCurrent) week.distanceKm,
  ];
  final best = closed.fold<double>(0, (max, km) => km > max ? km : max);
  return best <= 0 ? 20 : (best * 1.1).clamp(5, 200);
});

// ───────────────────────────────────────────────────────────── historial

@immutable
class RunHistoryState {
  const RunHistoryState({
    required this.runs,
    this.nextCursor,
    this.loadingMore = false,
  });

  final List<WorkoutLog> runs;
  final String? nextCursor;
  final bool loadingMore;

  bool get hasMore => nextCursor != null;

  RunHistoryState copyWith({
    List<WorkoutLog>? runs,
    String? nextCursor,
    bool clearCursor = false,
    bool? loadingMore,
  }) => RunHistoryState(
    runs: runs ?? this.runs,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// El historial del servidor, pagina a pagina.
///
/// Solo ensena lo que el servidor ya consolido. Una salida grabada sin red
/// aparece cuando la cola de sincronizacion la sube —tirar hacia abajo la
/// trae—; mientras tanto vive en la caja local, que es la que lee la pantalla
/// de recien terminar.
///
/// ponytail: no se mezclan las dos fuentes. Si hace falta ver la salida al
/// instante, el sitio es este provider: pegar delante los `pendingWorkout` de
/// la base local, sin tocar nada mas.
class RunHistoryNotifier extends AsyncNotifier<RunHistoryState> {
  @override
  Future<RunHistoryState> build() async {
    final page = await _fetch(cursor: null);
    return RunHistoryState(runs: page.items, nextCursor: page.nextCursor);
  }

  Future<WorkoutPage> _fetch({required String? cursor}) async =>
      (await ref
              .read(workoutLogRepositoryProvider)
              .history(cursor: cursor, limit: kHubPageSize))
          .unwrap();

  /// La pagina siguiente. No toca el estado a `loading`: la lista que ya se ve
  /// se queda donde esta y solo aparece el indicador del pie.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await _fetch(cursor: current.nextCursor);
      state = AsyncData(
        RunHistoryState(
          runs: [...current.runs, ...page.items],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (_) {
      // Un fallo al pedir mas no tira la lista: se suelta el indicador y el
      // siguiente scroll lo vuelve a intentar.
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  /// Borra en el servidor y, si sale bien, quita la fila sin recargar la lista
  /// entera: la pagina 4 del historial no tiene por que volver a bajar.
  /// Devuelve `true` cuando el borrado funciono.
  Future<bool> delete(String id) async {
    final current = state.value;
    final result = await ref.read(workoutLogRepositoryProvider).delete(id);
    return result.fold((_) {
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            runs: [
              for (final run in current.runs)
                if (run.id != id) run,
            ],
          ),
        );
      }
      // Los totales de la semana los suma el servidor: hay que volver a
      // preguntarlos.
      ref.invalidate(hubWeeksProvider);
      return true;
    }, (_) => false);
  }
}

final runHistoryProvider =
    AsyncNotifierProvider<RunHistoryNotifier, RunHistoryState>(
      RunHistoryNotifier.new,
    );

/// Las salidas de una semana, agrupadas por mes para las cabeceras de la lista.
@immutable
class MonthGroup {
  const MonthGroup({required this.month, required this.runs});

  final DateTime month;
  final List<WorkoutLog> runs;
}

final monthGroupsProvider = Provider<List<MonthGroup>>((ref) {
  final runs =
      ref.watch(runHistoryProvider).value?.runs ?? const <WorkoutLog>[];
  final groups = <MonthGroup>[];
  for (final run in runs) {
    final month = DateTime(run.startedAt.year, run.startedAt.month);
    if (groups.isNotEmpty && groups.last.month == month) {
      groups.last.runs.add(run);
    } else {
      groups.add(MonthGroup(month: month, runs: [run]));
    }
  }
  return groups;
});

/// El detalle de una salida, con sus parciales. `autoDispose`: al cerrar la
/// pantalla no hay por que guardar los splits de algo que ya se miro.
final runDetailProvider = FutureProvider.autoDispose
    .family<WorkoutDetail, String>(
      (ref, id) async =>
          (await ref.watch(workoutLogRepositoryProvider).detail(id)).unwrap(),
    );
