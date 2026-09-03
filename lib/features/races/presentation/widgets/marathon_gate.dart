import 'package:camrun/features/races/presentation/pages/marathon_preparing_page.dart';
import 'package:camrun/features/races/presentation/pages/race_detail_page.dart';
import 'package:camrun/features/races/presentation/providers/live_marathon_provider.dart';
import 'package:camrun/features/races/presentation/widgets/marathon_start_watcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La puerta de la app del corredor el dia de su maraton.
///
/// Envuelve la app entera y no una pantalla concreta porque el estado de la
/// carrera puede cambiar con el corredor mirando cualquier cosa, y porque lo
/// que hace es justamente **quitar** la app: en preparacion solo existe el
/// aviso del organizador, y despues de cruzar la meta solo existen sus
/// estadisticas, hasta que la maraton se de por terminada.
///
/// Solo lo ve quien esta inscrito: el estado sale de *mis carreras*. Ver
/// [marathonGateProvider].
class MarathonGateView extends ConsumerWidget {
  const MarathonGateView({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puerta = ref.watch(marathonGateProvider);

    return switch (puerta) {
      GatePreparing(:final entry, :final message) => MarathonPreparingPage(
        entry: entry,
        message: message,
      ),
      // Ya llego. La pantalla de la carrera corrida es exactamente lo que hay
      // que ensenarle —su tiempo, sus parciales, su recorrido—, asi que se
      // reusa entera; lo unico que cambia es que de aqui no se sale.
      GateFinished(:final entry) => RaceDetailPage(
        entryId: entry.id,
        locked: true,
      ),
      // Corriendo o sin nada que bloquear, la app es la app. El vigia se queda
      // detras en los dos casos: es quien abre la pantalla de carrera cuando el
      // organizador da la largada.
      GateRunning() || GateOpen() => MarathonStartWatcher(child: child),
    };
  }
}
