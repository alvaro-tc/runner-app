import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/home/domain/entities/training_plan.dart';
import 'package:meta/meta.dart';

/// Lo que `GET /home/summary` resuelve de una vez. Cinco cosas de cuatro
/// modulos: con un endpoint por cosa, arrancar la app son cinco peticiones en
/// serie sobre una red movil y cinco maneras de quedarse a medias.
@immutable
class HomeSummary {
  const HomeSummary({
    required this.featuredMarathon,
    required this.plan,
    required this.week,
    required this.todaySession,
  });

  /// La carrera que el usuario ya pago, o la proxima del catalogo. `null`
  /// cuando no hay ninguna por delante.
  final Marathon? featuredMarathon;

  final PlanOverview? plan;

  /// La tira Mon-Sun: siempre siete casillas, sin plan activo tambien.
  final TrainingWeek week;

  final PlannedSession? todaySession;
}

abstract interface class MarathonRepository {
  /// Las proximas del catalogo, de la mas cercana a la mas lejana.
  Future<Result<List<Marathon>>> fetchUpcoming({int limit});

  /// Acepta id o slug: la API resuelve los dos.
  Future<Result<Marathon>> fetchById(String idOrSlug);
}

abstract interface class HomeRepository {
  Future<Result<HomeSummary>> fetchSummary();

  /// Otra semana del plan activo, para el selector de Home.
  Future<Result<TrainingWeek>> fetchPlanWeek(int week);

  Future<Result<void>> setSessionCompleted({
    required String sessionId,
    required bool completed,
  });
}
