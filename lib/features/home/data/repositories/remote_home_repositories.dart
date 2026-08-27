import 'package:paceup/core/db/app_database.dart';
import 'package:paceup/core/error/failure.dart';
import 'package:paceup/core/sync/offline_first.dart';
import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/home/data/datasources/home_api.dart';
import 'package:paceup/features/home/data/home_mappers.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';
import 'package:paceup/features/home/domain/entities/training_plan.dart';
import 'package:paceup/features/home/domain/repositories/home_repositories.dart';

/// Lo ultimo que trajo la red, o lo ultimo que se cacheo si no la hay.
///
/// `readThrough` emite local y despues remoto; quedarse con el ultimo evento
/// es exactamente eso, y sin cache el fallo sube tal cual.
Future<T> _fresco<T>({
  required AppDatabase db,
  required String key,
  required Future<Map<String, dynamic>> Function() fetch,
  required T Function(Map<String, dynamic>) parse,
}) => readThrough(db: db, key: key, fetch: fetch, parse: parse).last;

class RemoteMarathonRepository implements MarathonRepository {
  RemoteMarathonRepository(this.api, this.db);

  final HomeApi api;
  final AppDatabase db;

  @override
  Future<Result<List<Marathon>>> fetchUpcoming({int limit = 8}) => guard(
    () => _fresco(
      db: db,
      key: 'marathons.upcoming',
      // La cache guarda documentos, no listas: la lista viaja dentro de uno.
      fetch: () async => {'items': await api.upcomingMarathons(limit: limit)},
      parse: (j) => [
        for (final m in (j['items'] as List).cast<Map<String, dynamic>>())
          marathonFrom(m),
      ],
    ),
  );

  @override
  Future<Result<Marathon>> fetchById(String idOrSlug) => guard(
    () => _fresco(
      db: db,
      key: 'marathon.$idOrSlug',
      fetch: () => api.marathon(idOrSlug),
      parse: marathonFrom,
    ),
  );
}

class RemoteHomeRepository implements HomeRepository {
  RemoteHomeRepository(this.api, this.db);

  final HomeApi api;
  final AppDatabase db;

  @override
  Future<Result<HomeSummary>> fetchSummary() => guard(
    () => _fresco(
      db: db,
      key: 'home.summary',
      fetch: api.summary,
      parse: summaryFrom,
    ),
  );

  /// La semana en curso ya viene en el resumen; las demas son una consulta a
  /// demanda y no se cachean: se piden al abrir el selector y punto.
  @override
  Future<Result<TrainingWeek>> fetchPlanWeek(int week) =>
      guard(() async => weekFrom(await api.planWeek(week)));

  @override
  Future<Result<void>> setSessionCompleted({
    required String sessionId,
    required bool completed,
  }) => guard(() async {
    if (!completed) {
      // La API no reabre una sesion cerrada. Se avisa en vez de fingir que se
      // guardo: el proximo `/home/summary` la devolveria completada igual.
      throw const ValidationFailure(
        'Una sesion marcada como hecha no se puede desmarcar.',
      );
    }
    await api.completeSession(sessionId);
  });
}
