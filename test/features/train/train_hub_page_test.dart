import 'package:camrun/app/dependencies.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_theme.dart';
import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/train/domain/entities/workout_log.dart';
import 'package:camrun/features/train/domain/repositories/workout_log_repository.dart';
import 'package:camrun/features/train/presentation/hub/pages/train_hub_page.dart';
import 'package:camrun/features/train/presentation/hub/widgets/run_card.dart';
import 'package:camrun/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Historial de mentira: devuelve lo que se le da, con cursor si se le pide
/// una segunda pagina.
class _FakeRepo implements WorkoutLogRepository {
  _FakeRepo({this.runs = const [], this.weeks = const []});

  final List<WorkoutLog> runs;
  final List<WeekStats> weeks;
  int historyCalls = 0;

  @override
  Future<Result<WorkoutPage>> history({
    WorkoutKind? kind,
    String? cursor,
    int limit = 20,
  }) async {
    historyCalls++;
    final filtered = [
      for (final run in runs)
        if (kind == null || run.kind == kind) run,
    ];
    return Result.success(WorkoutPage(items: filtered));
  }

  @override
  Future<Result<WorkoutDetail>> detail(String id) async =>
      Result.success(WorkoutDetail(log: runs.first, splits: const []));

  @override
  Future<Result<List<WeekStats>>> weeklyStats({int count = 8}) async =>
      Result.success(weeks);

  @override
  Future<Result<void>> delete(String id) async => const Result.success(null);
}

WorkoutLog _run(String id, {WorkoutKind kind = WorkoutKind.freeRun}) =>
    WorkoutLog(
      id: id,
      kind: kind,
      origin: WorkoutOrigin.app,
      startedAt: DateTime(2026, 10, 25, 7, 30),
      distanceKm: 10.2,
      duration: const Duration(minutes: 52),
      movingTime: const Duration(minutes: 50),
      elevationGainM: 120,
      avgPace: const Duration(minutes: 4, seconds: 54),
      mood: RunMood.good,
    );

WeekStats _week({double km = 21}) => WeekStats(
  startsAt: DateTime(2026, 10, 19),
  endsAt: DateTime(2026, 10, 26),
  distanceKm: km,
  movingTime: const Duration(hours: 2),
  duration: const Duration(hours: 2, minutes: 5),
  workouts: 2,
  avgPace: const Duration(minutes: 5, seconds: 42),
  days: [
    for (var weekday = 1; weekday <= 7; weekday++)
      DayStat(
        weekday: weekday,
        distanceKm: weekday == 3 ? km : 0,
        movingTime: weekday == 3 ? const Duration(hours: 2) : Duration.zero,
        workouts: weekday == 3 ? 2 : 0,
      ),
  ],
);

Widget _wrap(WorkoutLogRepository repo) {
  Intl.defaultLocale = 'en';
  return ProviderScope(
    overrides: [
      workoutLogRepositoryProvider.overrideWithValue(repo),
      // Sin SharedPreferences en la prueba: la unidad se fija a mano.
      useMilesProvider.overrideWithValue(false),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const TrainHubPage(),
    ),
  );
}

void main() {
  /// Una ventana alta: la pantalla mide mas de 600 px y en la de serie el
  /// historial se queda fuera del viewport, sin construir.
  void tallWindow(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1000, 2600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('pinta la semana y el historial que devuelve el servidor', (
    tester,
  ) async {
    tallWindow(tester);
    await tester.pumpWidget(
      _wrap(
        _FakeRepo(
          runs: [
            _run('a'),
            _run('b', kind: WorkoutKind.race),
          ],
          weeks: [_week()],
        ),
      ),
    );
    // No se usa `pumpAndSettle`: el boton de arrancar lleva un brillo que se
    // repite siempre, asi que la pantalla nunca "se asienta". Se avanza el
    // reloj lo que tarda la entrada mas el contador.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1800));

    expect(find.byType(RunCard), findsNWidgets(2));
    // El anillo cuenta hasta los 21 km de la semana.
    expect(find.text('21.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin salidas ensena el estado vacio, no una lista en blanco', (
    tester,
  ) async {
    tallWindow(tester);
    await tester.pumpWidget(_wrap(_FakeRepo(weeks: [_week(km: 0)])));
    // No se usa `pumpAndSettle`: el boton de arrancar lleva un brillo que se
    // repite siempre, asi que la pantalla nunca "se asienta". Se avanza el
    // reloj lo que tarda la entrada mas el contador.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1800));

    expect(find.byType(RunCard), findsNothing);
    expect(find.text('Nothing recorded yet'), findsOneWidget);
  });

  testWidgets('entra en una pantalla de telefono sin desbordar', (
    tester,
  ) async {
    // 390x844: un telefono de los estrechos. El panel de la semana lleva un
    // alto fijo, asi que un desborde ahi no se veria en una ventana grande.
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(_FakeRepo(runs: [_run('a'), _run('b')], weeks: [_week()])),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1800));
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(RunCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
