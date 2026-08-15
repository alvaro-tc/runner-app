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
    required this.selectedWeekIndex,
  });

  final Marathon nextMarathon;
  final TrainingPlan plan;
  final int selectedWeekIndex;

  TrainingWeek get week => plan.weekAt(selectedWeekIndex);

  /// The card at the bottom of Home: today's session if the selected week
  /// contains today, otherwise the first real session of that week.
  PlannedSession get focusSession {
    final today = DateTime.now();
    final isToday = week.sessions.any(
      (s) =>
          s.date.year == today.year &&
          s.date.month == today.month &&
          s.date.day == today.day,
    );
    if (isToday) {
      return week.sessions.firstWhere(
        (s) =>
            s.date.year == today.year &&
            s.date.month == today.month &&
            s.date.day == today.day,
      );
    }
    return week.sessions.firstWhere(
      (s) => !s.type.isRest,
      orElse: () => week.sessions.first,
    );
  }

  HomeData copyWith({TrainingPlan? plan, int? selectedWeekIndex}) => HomeData(
    nextMarathon: nextMarathon,
    plan: plan ?? this.plan,
    selectedWeekIndex: selectedWeekIndex ?? this.selectedWeekIndex,
  );
}

class HomeNotifier extends AsyncNotifier<HomeData> {
  @override
  Future<HomeData> build() async {
    final marathon =
        (await ref.watch(marathonRepositoryProvider).fetchFeatured()).unwrap();
    final plan = (await ref.watch(trainingPlanRepositoryProvider).fetchPlan())
        .unwrap();
    return HomeData(
      nextMarathon: marathon,
      plan: plan,
      selectedWeekIndex: plan.activeWeekIndex,
    );
  }

  void selectWeek(int index) {
    final data = state.value;
    if (data == null) return;
    state = AsyncData(data.copyWith(selectedWeekIndex: index));
  }

  Future<void> toggleSession(
    String sessionId, {
    required bool completed,
  }) async {
    final data = state.value;
    if (data == null) return;
    final result = await ref
        .read(trainingPlanRepositoryProvider)
        .setSessionCompleted(sessionId: sessionId, completed: completed);
    result.fold((plan) => state = AsyncData(data.copyWith(plan: plan)), (_) {});
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
