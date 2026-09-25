import 'dart:async';

import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/network/live_socket.dart';
import 'package:camrun/core/network/network_providers.dart';
import 'package:camrun/features/admin/data/admin_api.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminApiProvider = Provider<AdminApi>(
  (ref) => AdminApi(ref.watch(dioProvider)),
);

/// Todas las maratones del panel, la mas proxima primero.
///
/// Es un `AsyncNotifier` y no un `FutureProvider` porque la lista no solo se
/// lee: publica, retira y abre inscripciones sin abrir el detalle, y eso pide
/// poder tocar el estado ya cargado. Con un `FutureProvider` cada interruptor
/// tendria que recargar las trece carreras para pintar un cambio de una.
class AdminMarathonsNotifier extends AsyncNotifier<List<AdminMarathon>> {
  @override
  Future<List<AdminMarathon>> build() async {
    final filas = await ref.watch(adminApiProvider).marathons();
    return ordenarParaElPanel([
      for (final fila in filas) AdminMarathon.fromJson(fila),
    ]);
  }

  /// Publica o retira del catalogo. Retirar **no** cancela inscripciones.
  Future<Failure?> setPublished(AdminMarathon maraton, {required bool value}) =>
      _cambiar(
        maraton.id,
        (m) => m.copyWith(published: value),
        (api) => api.setPublished(maraton.id, value),
      );

  Future<Failure?> setRegistrationsOpen(
    AdminMarathon maraton, {
    required bool value,
  }) => _cambiar(
    maraton.id,
    (m) => m.copyWith(registrationsOpen: value),
    (api) => api.setRegistrationsOpen(maraton.id, value),
  );

  /// Pinta primero y pregunta despues.
  ///
  /// El interruptor cambia en el acto y la peticion va detras; si el servidor
  /// dice que no, se vuelve a lo anterior y quien llamo se queda con el fallo
  /// para contarlo. Esperar la respuesta con el dedo encima seria medio segundo
  /// de nada en la oficina y varios en el arco de meta, que es justo donde se
  /// cierran las inscripciones.
  ///
  /// Se llama tambien desde el detalle, al que se puede entrar sin haber
  /// pasado por la lista: por eso la peticion no depende de que haya estado
  /// cargado que retocar, y lo optimista es lo unico opcional.
  Future<Failure?> _cambiar(
    String id,
    AdminMarathon Function(AdminMarathon) aplicar,
    Future<void> Function(AdminApi) enviar,
  ) async {
    final antes = state.value;
    if (antes != null) {
      final i = antes.indexWhere((m) => m.id == id);
      if (i >= 0) state = AsyncData([...antes]..[i] = aplicar(antes[i]));
    }

    try {
      await enviar(ref.read(adminApiProvider));
      // El detalle guarda su propia copia del mismo estado: sin esto, entrar a
      // la carrera recien publicada la mostraria todavia como borrador.
      ref.invalidate(adminMarathonProvider(id));
      return null;
    } on Failure catch (f) {
      if (antes != null) state = AsyncData(antes);
      return f;
    }
  }
}

final adminMarathonsProvider =
    AsyncNotifierProvider<AdminMarathonsNotifier, List<AdminMarathon>>(
      AdminMarathonsNotifier.new,
    );

/// Proximas primero y, detras, las que ya pasaron de la mas reciente a la mas
/// vieja.
///
/// El servidor las manda de la mas lejana a la mas cercana, que es el orden
/// contrario al que se trabaja: lo que un admin abre el panel a mirar es la
/// carrera que viene, no la del ano que viene ni la del ano pasado.
List<AdminMarathon> ordenarParaElPanel(List<AdminMarathon> maratones) {
  final ahora = DateTime.now();
  final proximas = <AdminMarathon>[];
  final pasadas = <AdminMarathon>[];

  for (final m in maratones) {
    (m.startsAt.isBefore(ahora) ? pasadas : proximas).add(m);
  }

  proximas.sort((a, b) => a.startsAt.compareTo(b.startsAt));
  pasadas.sort((a, b) => b.startsAt.compareTo(a.startsAt));

  return [...proximas, ...pasadas];
}

/// El detalle, que es lo unico que trae el trazado.
final adminMarathonProvider = FutureProvider.family<AdminMarathon, String>((
  ref,
  id,
) async {
  final fila = await ref.watch(adminApiProvider).marathon(id);
  return AdminMarathon.fromJson(fila);
});

/// Una pagina de usuarios. Busqueda, rol y paginacion se resuelven en el
/// servidor: la lista viene por partes y filtrarla aqui dejaba fuera a los
/// admins y organizadores, que son pocos y de los primeros creados.
final adminUsersProvider =
    FutureProvider.family<AdminUsersPage, AdminUsersQuery>((ref, filtro) async {
      final pagina = await ref
          .watch(adminApiProvider)
          .users(
            search: filtro.busqueda,
            role: filtro.rol,
            page: filtro.pagina,
            pageSize: filtro.porPagina,
          );
      return (
        usuarios: [for (final fila in pagina.filas) AdminUser.fromJson(fila)],
        total: pagina.total,
      );
    });

/// Una pagina de tickets. Mismo reparto que los usuarios: el filtro y la
/// pagina los resuelve el servidor.
final adminTicketsProvider =
    FutureProvider.family<AdminTicketsPage, AdminTicketsQuery>((
      ref,
      filtro,
    ) async {
      final pagina = await ref
          .watch(adminApiProvider)
          .payments(
            marathonId: filtro.marathonId,
            status: filtro.estado,
            search: filtro.busqueda,
            page: filtro.pagina,
            pageSize: filtro.porPagina,
          );
      return (
        tickets: [for (final fila in pagina.filas) AdminTicket.fromJson(fila)],
        total: pagina.total,
      );
    });

/// Un ticket suelto: el que abre un aviso de pago.
final adminTicketProvider = FutureProvider.family<AdminTicket, String>(
  (ref, id) async =>
      AdminTicket.fromJson(await ref.watch(adminApiProvider).payment(id)),
);

/// Cual maraton mira el mapa de Home. La elige el selector de arriba; se queda
/// puesta al navegar a otra pestana y volver.
class SelectedMarathonNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedMarathonProvider =
    NotifierProvider<SelectedMarathonNotifier, String?>(
      SelectedMarathonNotifier.new,
    );

/// Resuelve la maraton visible sin borrar la eleccion al cambiar de pestana.
/// Si la elegida ya no existe, prioriza la carrera activa y luego la que esta
/// en preparacion antes de caer en la primera del panel.
AdminMarathon selectMarathonForLivePanel(
  List<AdminMarathon> marathons,
  String? selectedId,
) {
  if (selectedId != null) {
    for (final marathon in marathons) {
      if (marathon.id == selectedId) return marathon;
    }
  }
  for (final marathon in marathons) {
    if (marathon.running) return marathon;
  }
  for (final marathon in marathons) {
    if (marathon.preparing) return marathon;
  }
  return marathons.first;
}

enum AdminLiveControl { start, finish, finished }

/// Un solo control principal por fase: antes se inicia, durante se finaliza y
/// despues solo queda el estado terminado.
AdminLiveControl adminLiveControlFor(AdminMarathon marathon, LiveBoard board) {
  if (board.finishedAt != null || marathon.finished) {
    return AdminLiveControl.finished;
  }
  if (board.running || marathon.running) return AdminLiveControl.finish;
  return AdminLiveControl.start;
}

/// Proyecta un estado confirmado por el servidor sobre el mapa actual.
/// Finalizar elimina todos los marcadores de inmediato.
LiveBoard liveBoardAfterServerState({
  required LiveBoard current,
  required String marathonId,
  required MarathonLiveState next,
}) {
  if (next.marathonId != marathonId) return current;
  final finished = next.finishedAt != null;
  return LiveBoard(
    runners: finished ? const {} : current.runners,
    finishedBibs: finished ? const {} : current.finishedBibs,
    preparingAt: next.preparingAt,
    preparingMessage: next.preparingMessage,
    startedAt: next.startedAt,
    finishedAt: next.finishedAt,
    loading: false,
  );
}

/// Lo que pinta el mapa en vivo: quien va por donde, ahora mismo.
@immutable
class LiveBoard {
  const LiveBoard({
    this.runners = const {},
    this.finishedBibs = const {},
    this.preparingAt,
    this.preparingMessage,
    this.startedAt,
    this.finishedAt,
    this.loading = true,
    this.failure,
  });

  /// Por dorsal: una posicion nueva del mismo corredor **reemplaza** a la
  /// anterior. Guardar el historico haria crecer el mapa sin limite durante una
  /// carrera de cuatro horas para pintar siempre solo el ultimo punto.
  final Map<String, LivePosition> runners;

  /// Dorsales que ya cruzaron la meta, segun el GPS. El mapa los pinta
  /// distinto: siguen en la lista pero ya no estan corriendo.
  final Set<String> finishedBibs;

  final DateTime? preparingAt;
  final String? preparingMessage;

  final DateTime? startedAt;
  final DateTime? finishedAt;
  final bool loading;
  final Failure? failure;

  bool get running => startedAt != null && finishedAt == null;

  /// El mismo orden que en el servidor: lo ultimo que paso manda.
  MarathonPhase get phase {
    if (finishedAt != null) return MarathonPhase.finished;
    if (startedAt != null) return MarathonPhase.inProgress;
    if (preparingAt != null) return MarathonPhase.preparing;
    return MarathonPhase.notStarted;
  }

  LiveBoard copyWith({
    Map<String, LivePosition>? runners,
    Set<String>? finishedBibs,
    DateTime? preparingAt,
    String? preparingMessage,
    DateTime? startedAt,
    DateTime? finishedAt,
    bool? loading,
    bool clearFinished = false,
    Failure? failure,
    bool clearFailure = false,
  }) => LiveBoard(
    runners: runners ?? this.runners,
    finishedBibs: finishedBibs ?? this.finishedBibs,
    preparingAt: preparingAt ?? this.preparingAt,
    preparingMessage: preparingMessage ?? this.preparingMessage,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: clearFinished ? null : (finishedAt ?? this.finishedAt),
    loading: loading ?? this.loading,
    failure: clearFailure ? null : (failure ?? this.failure),
  );
}

/// El mapa en vivo de una maraton.
///
/// **Foto primero, socket despues.** Al abrirse pide la foto por REST: sin ella
/// el mapa estaria vacio hasta que a cada corredor le tocara su siguiente
/// emision, que son cinco segundos con buena senal y minutos con mala. A partir
/// de ahi todo llega por el socket y no se vuelve a preguntar.
class LiveBoardNotifier extends Notifier<LiveBoard> {
  LiveBoardNotifier(this.marathonId);

  final String marathonId;

  @override
  LiveBoard build() {
    final socket = ref.watch(liveSocketProvider);

    final posiciones = socket.positions.listen(_onPosicion);
    final estados = socket.states.listen(_onEstado);
    final llegadas = socket.finishes.listen(_onLlegada);

    // La baja de la sala llega despues del primer await; si la pantalla se
    // cerro antes, hay que soltarla igual o quedaria mirando para siempre.
    var vivo = true;
    VoidCallback? salir;
    unawaited(
      socket.watch(marathonId).then((baja) {
        if (vivo) {
          salir = baja;
        } else {
          baja();
        }
      }),
    );

    ref.onDispose(() {
      vivo = false;
      salir?.call();
      unawaited(posiciones.cancel());
      unawaited(estados.cancel());
      unawaited(llegadas.cancel());
    });

    unawaited(_cargarFoto(marathonId));
    return const LiveBoard();
  }

  Future<void> _cargarFoto(String marathonId) async {
    try {
      final json = await ref.read(adminApiProvider).live(marathonId);
      final corredores = <String, LivePosition>{};
      for (final fila in (json['runners'] as List? ?? const [])) {
        final p = LivePosition.fromJson((fila as Map).cast<String, dynamic>());
        corredores[p.key] = p;
      }
      state = LiveBoard(
        runners: corredores,
        finishedBibs: state.finishedBibs,
        preparingAt: DateTime.tryParse(json['preparingAt'] as String? ?? ''),
        preparingMessage: json['preparingMessage'] as String?,
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
        finishedAt: DateTime.tryParse(json['finishedAt'] as String? ?? ''),
        loading: false,
      );
    } catch (error) {
      // El fallo queda visible y, sobre todo, se apaga `loading`: una red caida
      // no puede dejar el mapa girando para siempre.
      state = state.copyWith(
        loading: false,
        failure: error is Failure ? error : const UnexpectedFailure(),
      );
    }
  }

  Future<void> reload() async {
    state = state.copyWith(loading: true, clearFailure: true);
    await _cargarFoto(marathonId);
  }

  void _onPosicion(LivePosition p) {
    state = state.copyWith(
      runners: {...state.runners, p.key: p},
      clearFailure: true,
    );
  }

  void _onEstado(MarathonLiveState estado) {
    _applyState(estado);
  }

  /// Aplica la respuesta de iniciar/finalizar sin esperar a que el socket haga
  /// eco de la orden en el mismo dispositivo. Las horas siguen siendo las del
  /// servidor: este metodo solo refleja ese payload ya confirmado.
  void applyServerState(Map<String, dynamic> json) {
    _applyState(MarathonLiveState.fromJson(json));
  }

  void _applyState(MarathonLiveState estado) {
    state = liveBoardAfterServerState(
      current: state,
      marathonId: marathonId,
      next: estado,
    );
  }

  /// Alguien cruzo la meta. Se queda en el mapa —el organizador quiere ver
  /// donde esta cada uno, tambien los que ya llegaron— pero marcado.
  void _onLlegada(RunnerFinish llegada) {
    final bib = llegada.bib;
    if (bib == null || bib.isEmpty) return;
    state = state.copyWith(finishedBibs: {...state.finishedBibs, bib});
  }
}

final liveBoardProvider = NotifierProvider.autoDispose
    .family<LiveBoardNotifier, LiveBoard, String>(LiveBoardNotifier.new);
