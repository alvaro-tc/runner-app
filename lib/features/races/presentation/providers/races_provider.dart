import 'package:camrun/app/dependencies.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/features/races/domain/entities/registration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mis carreras. Solo lo confirmado: los borradores viven en el flujo de
/// inscripcion, no aqui.
class RacesNotifier extends AsyncNotifier<List<RaceEntry>> {
  @override
  Future<List<RaceEntry>> build() async =>
      (await ref.watch(raceRepositoryProvider).fetchEntries()).unwrap();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<Failure?> cancel(String entryId) async {
    final result = await ref.read(raceRepositoryProvider).cancel(entryId);

    return result.fold((_) {
      ref.invalidateSelf();
      return null;
    }, (failure) => failure);
  }
}

final racesProvider = AsyncNotifierProvider<RacesNotifier, List<RaceEntry>>(
  RacesNotifier.new,
);

/// Los totales de la cabecera, tal como los suma el servidor.
///
/// Mientras cargan se muestran los derivados de la lista: son correctos en
/// carreras y kilometros y solo se quedan cortos en el gasto, que la lista no
/// trae. Un hueco en la cabecera se ve peor que un numero que se afina solo.
final raceTotalsProvider = Provider<RaceTotals?>((ref) {
  final delServidor = ref.watch(racesSummaryProvider).value;
  if (delServidor != null) return delServidor;

  final entries = ref.watch(racesProvider).value;
  return entries == null ? null : RaceTotals.from(entries);
});

final racesSummaryProvider = FutureProvider<RaceTotals>((ref) async {
  // Se recalcula cuando cambia la lista: inscribirse o cancelar mueve el total.
  ref.watch(racesProvider);
  return (await ref.watch(raceRepositoryProvider).fetchTotals()).unwrap();
});

/// Las inscripciones con el comprobante subido, esperando a un administrador.
///
/// No son carreras: el servidor no las devuelve en "mis carreras" hasta que el
/// pago se valida. Se piden aparte para que quien subio su captura la siga
/// viendo, y para no dejarle empezar una segunda inscripcion a la misma
/// maraton mientras tanto.
final awaitingValidationProvider = FutureProvider<List<Registration>>(
  (ref) async {
    // Cuelga de la lista: refrescar "mis carreras" —o inscribirse, o cancelar—
    // tiene que refrescar tambien lo que esta esperando validacion.
    ref.watch(racesProvider);
    return (await ref.watch(raceRepositoryProvider).awaitingValidation())
        .unwrap();
  },
  // Sin reintento propio: la lista de la que cuelga se vuelve a pedir sola cada
  // pocos segundos y arrastra esta, asi que el reintento de riverpod solo
  // anadiria una segunda peticion con su propio reloj.
  retry: (_, _) => null,
);

/// El detalle **se pide aparte**: la lista no trae recorrido, parciales ni
/// pagos, y buscarla en la lista dejaria la pantalla de una carrera corrida
/// sin mapa ni splits.
final raceDetailProvider = FutureProvider.family<RaceEntry, String>((
  ref,
  registrationId,
) async {
  // Depende de la lista para que cancelar o inscribirse lo refresque tambien.
  ref.watch(racesProvider);
  return (await ref.watch(raceRepositoryProvider).fetchById(registrationId))
      .unwrap();
});
