import 'dart:async';

import 'package:camrun/core/network/live_socket.dart';
import 'package:camrun/core/network/network_providers.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/features/races/presentation/providers/races_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La maraton del usuario que se esta corriendo ahora mismo, o `null`.
///
/// **Dos fuentes, a proposito.** El socket avisa en el instante en que el
/// organizador da la largada, que es lo que hace que la pantalla se abra sola
/// sin que nadie toque nada. Y la lista de carreras trae `liveStartedAt`, que
/// es lo que salva a quien abrio la app con la carrera ya empezada —telefono
/// sin bateria, app cerrada, sin cobertura en la largada—: ese corredor no
/// recibio ningun aviso y aun asi tiene que acabar en la misma pantalla.
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

class LiveMarathonNotifier extends Notifier<LiveMarathon?> {
  /// Lo que dijo el socket, por maraton. Manda sobre lo que trajo la lista:
  /// llego despues.
  final _avisos = <String, MarathonLiveState>{};

  final _bajas = <String, VoidCallback>{};

  @override
  LiveMarathon? build() {
    final socket = ref.watch(liveSocketProvider);
    final carreras = ref.watch(racesProvider).value ?? const <RaceEntry>[];

    final suscripcion = socket.states.listen((estado) {
      _avisos[estado.marathonId] = estado;
      state = _resolver(ref.read(racesProvider).value ?? const []);
    });

    // Solo las carreras de **hoy**, y solo las de este usuario.
    //
    // Una inscripcion se compra con meses de antelacion: abrir el socket por
    // ella significaria tener a todo el mundo con una conexion viva durante
    // semanas para un aviso que llega un domingo por la manana. La ventana es
    // ancha en los dos sentidos a proposito —una largada se retrasa, y a veces
    // se adelanta— y lo que se pierde por quedarse corto lo recoge igual
    // `liveStartedAt` la proxima vez que la app pida sus carreras.
    final ahora = DateTime.now();
    final vivas = {
      for (final entrada in carreras)
        if (entrada.canStart &&
            (entrada.marathon.isLive ||
                entrada.marathon.date.difference(ahora).abs() < _ventana))
          entrada.marathon.id,
    };
    _sincronizarSalas(socket, vivas);

    ref.onDispose(() {
      unawaited(suscripcion.cancel());
      for (final baja in _bajas.values) {
        baja();
      }
      _bajas.clear();
    });

    return _resolver(carreras);
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

  LiveMarathon? _resolver(List<RaceEntry> carreras) {
    for (final entrada in carreras) {
      final aviso = _avisos[entrada.marathon.id];
      final arranco = aviso?.startedAt ?? entrada.marathon.liveStartedAt;
      final termino = aviso?.finishedAt ?? entrada.marathon.liveFinishedAt;

      if (arranco == null || termino != null) continue;
      // Una carrera ya corrida no vuelve a arrancar aunque la maraton siga
      // abierta: quien ya tiene resultado termino.
      if (entrada.hasResult) continue;

      return LiveMarathon(entry: entrada, startedAt: arranco);
    }
    return null;
  }
}

final liveMarathonProvider =
    NotifierProvider<LiveMarathonNotifier, LiveMarathon?>(
      LiveMarathonNotifier.new,
    );
