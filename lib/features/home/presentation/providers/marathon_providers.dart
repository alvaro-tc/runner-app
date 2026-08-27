import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/app/dependencies.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';

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
