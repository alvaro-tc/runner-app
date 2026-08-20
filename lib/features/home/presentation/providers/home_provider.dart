import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/app/dependencies.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';
import 'package:paceup/features/home/domain/entities/training_plan.dart';

@immutable
class HomeData {
  const HomeData({
    required this.nextMarathon,
    required this.plan,
    required this.week,
    required this.selectedWeekIndex,
    required this.todaySession,
  });

  /// `null` cuando no hay ninguna carrera por delante en el catalogo.
  final Marathon? nextMarathon;

  /// `null` mientras el usuario no tenga un plan activo.
  final PlanOverview? plan;

  /// La semana que se esta mirando. Sin plan, la tira Mon-Sun sigue teniendo
  /// sus siete casillas con lo que se corrio.
  final TrainingWeek week;

  final int selectedWeekIndex;
  final PlannedSession? todaySession;

  /// La tarjeta de abajo: la sesion de hoy si la hay, y si no la primera de
  /// verdad de la semana que se esta mirando.
  PlannedSession? get focusSession {
    if (todaySession != null && selectedWeekIndex == week.index) {
      return todaySession;
    }
    final reales = week.sessions.where((s) => !s.type.isRest);
    return reales.isEmpty ? null : reales.first;
  }

  HomeData copyWith({TrainingWeek? week, int? selectedWeekIndex}) => HomeData(
    nextMarathon: nextMarathon,
    plan: plan,
    week: week ?? this.week,
    selectedWeekIndex: selectedWeekIndex ?? this.selectedWeekIndex,
    todaySession: todaySession,
  );
}

class HomeNotifier extends AsyncNotifier<HomeData> {
  @override
  Future<HomeData> build() async {
    final resumen = (await ref.watch(homeRepositoryProvider).fetchSummary())
        .unwrap();
    return HomeData(
      nextMarathon: resumen.featuredMarathon,
      plan: resumen.plan,
      week: resumen.week,
      selectedWeekIndex: resumen.week.index,
      todaySession: resumen.todaySession,
    );
  }

  /// Cada semana es una consulta: el plan puede tener dieciseis y traerlas
  /// todas para pintar una seria bajarse el plan entero en cada arranque.
  Future<void> selectWeek(int index) async {
    final data = state.value;
    if (data == null || index == data.selectedWeekIndex) return;

    final result = await ref.read(homeRepositoryProvider).fetchPlanWeek(index);
    result.fold(
      (week) => state = AsyncData(
        data.copyWith(week: week, selectedWeekIndex: index),
      ),
      (_) {},
    );
  }

  Future<void> toggleSession(
    String sessionId, {
    required bool completed,
  }) async {
    final result = await ref
        .read(homeRepositoryProvider)
        .setSessionCompleted(sessionId: sessionId, completed: completed);
    // El servidor recalcula progreso y contadores: se relee en vez de
    // adivinar como quedo la semana.
    result.fold((_) => unawaited(refresh()), (_) {});
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final homeProvider = AsyncNotifierProvider<HomeNotifier, HomeData>(
  HomeNotifier.new,
);

/// The wall clock, behind a provider so tests can freeze it.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Ticks once a second so the countdown pill stays live. It is scoped to the
/// provider, so it stops as soon as Home is disposed.
final countdownProvider = StreamProvider.autoDispose.family<Duration, DateTime>(
  (ref, target) async* {
    final now = ref.watch(nowProvider);
    yield target.difference(now());
    yield* Stream.periodic(
      const Duration(seconds: 1),
      (_) => target.difference(now()),
    );
  },
);
