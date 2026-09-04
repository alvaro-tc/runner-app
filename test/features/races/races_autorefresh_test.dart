import 'package:camrun/app/dependencies.dart';
import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/features/races/domain/repositories/race_repository.dart';
import 'package:camrun/features/races/presentation/providers/races_provider.dart';
import 'package:camrun/features/races/presentation/widgets/races_autorefresh.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Que "mis carreras" se refresca sola.
///
/// Es lo unico que separa a un corredor de ver su pago validado —o el aviso de
/// largada— sin cerrar la app: si el sondeo deja de pedir la lista, la pantalla
/// se queda con lo que trajo al abrir y nadie se entera.
void main() {
  testWidgets('vuelve a pedir la lista sola, y para al desmontarse', (
    tester,
  ) async {
    final repo = _RepoQueCuenta();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [raceRepositoryProvider.overrideWithValue(repo)],
        child: RacesAutoRefresh(
          child: Consumer(
            builder: (_, ref, _) {
              ref.watch(racesProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(repo.pedidas, 1);

    // Dos tics del sondeo, dos lecturas mas.
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();
    expect(repo.pedidas, 3);

    // Y el reloj se suelta con el arbol: si no, el test denuncia el timer.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _RepoQueCuenta implements RaceRepository {
  int pedidas = 0;

  @override
  Future<Result<List<RaceEntry>>> fetchEntries() async {
    pedidas++;
    return const Result.success(<RaceEntry>[]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
