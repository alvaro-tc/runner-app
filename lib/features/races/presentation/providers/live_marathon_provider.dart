import 'dart:async';

import 'package:camrun/core/network/live_socket.dart';
import 'package:camrun/core/network/network_providers.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/features/races/presentation/providers/races_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// En que estado deja la app la maraton del usuario.
///
/// Es una puerta, no un aviso: mientras haya algo distinto de [GateOpen], el
/// corredor no ve la app —ni su perfil, ni sus entrenamientos, ni el catalogo—.
/// Una maraton en preparacion o en marcha es un evento presencial con una
/// persona con megafono delante, y la app tiene que decir una sola cosa.
///
/// **Solo afecta a los inscritos.** Todo esto sale de *mis carreras*, que es
/// una lista de inscripciones confirmadas propias: quien no corre esta maraton
/// no tiene ninguna entrada de la que sacar el bloqueo.
@immutable
sealed class MarathonGate {
  const MarathonGate();
}

/// Nada que bloquear: la app funciona entera.
class GateOpen extends MarathonGate {
  const GateOpen();
}

/// La maraton esta a punto. Solo se ve el aviso del organizador.
class GatePreparing extends MarathonGate {
  const GatePreparing({required this.entry, this.message});

  final RaceEntry entry;

  /// Lo que escribio el organizador. `null` = el texto por defecto de la app,
  /// que sale del ARB y por tanto en el idioma del corredor.
  final String? message;
}

/// Se esta corriendo y esta persona todavia no llego.
class GateRunning extends MarathonGate {
  const GateRunning({required this.entry, required this.startedAt});

  final RaceEntry entry;
  final DateTime startedAt;
}

/// Ya cruzo la meta, pero la maraton sigue en marcha: solo sus estadisticas.
class GateFinished extends MarathonGate {
  const GateFinished({required this.entry});

  final RaceEntry entry;
}

/// La maraton del usuario que se esta corriendo ahora mismo, o `null`.
///
/// Es la vista de [GateRunning] para quien solo necesita eso: el vigia que
/// abre la pantalla de carrera.
@immutable
class LiveMarathon {
  const LiveMarathon({required this.entry, required this.startedAt});

  /// La inscripcion. Es lo que la sesion manda al servidor: sin ella los puntos
  /// son un entrenamiento suelto y no salen en el mapa del organizador.
  final RaceEntry entry;

  final DateTime startedAt;
}

/// Cuanto antes y despues de la hora programada se escucha la largada.
const _ventana = Duration(hours: 12);

/// **Dos fuentes, a proposito.** El socket avisa en el instante en que el
/// organizador toca el boton, que es lo que hace que la pantalla cambie sola
/// sin que nadie recargue nada. Y la lista de carreras trae las mismas fechas,
/// que es lo que salva a quien abrio la app con la carrera ya en marcha
/// —telefono sin bateria, app cerrada, sin cobertura en la largada—: ese
/// corredor no recibio ningun aviso y aun asi tiene que acabar en la misma
/// pantalla.
class MarathonGateNotifier extends Notifier<MarathonGate> {
  /// Lo que dijo el socket, por maraton. Manda sobre lo que trajo la lista:
  /// llego despues.
  final _avisos = <String, MarathonLiveState>{};

  /// Dorsales que el servidor dio por llegados en esta sesion de app.
  ///
  /// El resultado oficial tarda unos segundos en existir —el servidor cierra
  /// la sesion y consolida las metricas despues de anunciar la llegada— y sin
  /// esto el corredor volveria un momento a la pantalla de carrera justo
  /// despues de cruzar la meta.
  final _llegados = <String>{};

  final _bajas = <String, VoidCallback>{};

  @override
  MarathonGate build() {
    final socket = ref.watch(liveSocketProvider);
    final carreras = ref.watch(racesProvider).value ?? const <RaceEntry>[];

    final suscripcion = socket.states.listen((estado) {
      _avisos[estado.marathonId] = estado;
      state = _resolver(ref.read(racesProvider).value ?? const []);
    });

    final llegadas = socket.finishes.listen(_onLlegada);

    // Solo las carreras de **hoy**, y solo las de este usuario.
    //
    // Una inscripcion se compra con meses de antelacion: abrir el socket por
    // ella significaria tener a todo el mundo con una conexion viva durante
    // semanas para un aviso que llega un domingo por la manana. La ventana es
    // ancha en los dos sentidos a proposito —una largada se retrasa, y a veces
    // se adelanta— y lo que se pierde por quedarse corto lo recogen igual las
    // fechas la proxima vez que la app pida sus carreras.
    final ahora = DateTime.now();
    final vivas = {
      for (final entrada in carreras)
        if (entrada.isEnrolled &&
            (entrada.marathon.phase != MarathonPhase.notStarted ||
                entrada.marathon.date.difference(ahora).abs() < _ventana))
          entrada.marathon.id,
    };
    _sincronizarSalas(socket, vivas);

    ref.onDispose(() {
      unawaited(suscripcion.cancel());
      unawaited(llegadas.cancel());
      for (final baja in _bajas.values) {
        baja();
      }
      _bajas.clear();
    });

    return _resolver(carreras);
  }

  /// Alguien cruzo la meta. Si es este corredor, se pasa a sus estadisticas.
  ///
  /// La lista se recarga dos veces a proposito: la primera casi siempre llega
  /// antes de que el resultado oficial exista —el servidor lo consolida
  /// despues de anunciar—, y la segunda es la que lo trae. Mientras tanto el
  /// dorsal recordado ya mantiene la pantalla correcta.
  void _onLlegada(RunnerFinish llegada) {
    final bib = llegada.bib;
    if (bib == null || bib.isEmpty) return;

    final carreras = ref.read(racesProvider).value ?? const <RaceEntry>[];
    if (!carreras.any((e) => e.isEnrolled && e.bibNumber == bib)) return;

    _llegados.add(bib);
    state = _resolver(carreras);

    ref.invalidate(racesProvider);
    Timer(const Duration(seconds: 6), () {
      if (ref.mounted) ref.invalidate(racesProvider);
    });
  }

  void _sincronizarSalas(LiveSocket socket, Set<String> vivas) {
    for (final id in _bajas.keys.toList()) {
      if (vivas.contains(id)) continue;
      _bajas.remove(id)?.call();
    }

    for (final id in vivas) {
      if (_bajas.containsKey(id)) continue;
      // Reserva el sitio antes del await: sin ella, dos reconstrucciones
      // seguidas piden la misma sala dos veces y solo se suelta una.
      _bajas[id] = () {};
      unawaited(
        socket.watch(id).then((baja) {
          if (_bajas.containsKey(id)) {
            _bajas[id] = baja;
          } else {
            baja();
          }
        }),
      );
    }
  }

  MarathonGate _resolver(List<RaceEntry> carreras) =>
      resolverPuerta(carreras, avisos: _avisos, llegados: _llegados);
}

/// Quien esta bloqueado y por que, dadas las inscripciones y lo que dijo el
/// socket.
///
/// Funcion suelta y no metodo: es toda la regla del bloqueo —la parte que hay
/// que poder equivocarse en una prueba y no el dia de la carrera— y aqui no
/// depende de sockets, de red ni de que haya una app montada.
MarathonGate resolverPuerta(
  List<RaceEntry> carreras, {
  Map<String, MarathonLiveState> avisos = const {},
  Set<String> llegados = const {},
}) {
  for (final entrada in carreras) {
    // La puerta es solo para inscritos. Quien no corre esta maraton no tiene
    // ninguna entrada de la que sacar el bloqueo, y por eso no lo ve nunca.
    if (!entrada.isEnrolled) continue;

    final aviso = avisos[entrada.marathon.id];
    final fase = aviso?.phase ?? entrada.marathon.phase;

    switch (fase) {
      case MarathonPhase.notStarted:
      case MarathonPhase.finished:
        // Terminada o sin empezar, la app es la app. Es tambien lo que pasa
        // cuando el organizador corta la carrera: todo el mundo se suelta.
        continue;

      case MarathonPhase.preparing:
        return GatePreparing(
          entry: entrada,
          message: aviso?.preparingMessage ?? entrada.marathon.preparingMessage,
        );

      case MarathonPhase.inProgress:
        // Ya llego: sus estadisticas, y solo eso, hasta que la maraton se de
        // por terminada. El dorsal recordado cubre los segundos que el
        // servidor tarda en consolidar el resultado oficial.
        if (entrada.hasResult || llegados.contains(entrada.bibNumber)) {
          return GateFinished(entry: entrada);
        }
        final arranco = aviso?.startedAt ?? entrada.marathon.liveStartedAt;
        if (arranco == null) continue;
        return GateRunning(entry: entrada, startedAt: arranco);
    }
  }

  return const GateOpen();
}

final marathonGateProvider =
    NotifierProvider<MarathonGateNotifier, MarathonGate>(
      MarathonGateNotifier.new,
    );

/// La carrera que hay que largar ahora mismo, o `null`.
final liveMarathonProvider = Provider<LiveMarathon?>((ref) {
  final puerta = ref.watch(marathonGateProvider);
  return puerta is GateRunning
      ? LiveMarathon(entry: puerta.entry, startedAt: puerta.startedAt)
      : null;
});
