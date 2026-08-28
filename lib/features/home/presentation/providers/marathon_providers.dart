import 'package:camrun/app/dependencies.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El catalogo de proximas carreras: el carrusel de Home y el fondo de la
/// pestana "Upcoming" de Carreras.
final upcomingMarathonsProvider = FutureProvider<List<Marathon>>(
  (ref) async =>
      (await ref.watch(marathonRepositoryProvider).fetchUpcoming()).unwrap(),
);

final marathonProvider = FutureProvider.family<Marathon, String>(
  (ref, id) async =>
      (await ref.watch(marathonRepositoryProvider).fetchById(id)).unwrap(),
);
