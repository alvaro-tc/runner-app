import 'dart:async';

import 'package:camrun/core/network/api_config.dart';
import 'package:camrun/core/storage/token_storage.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Una posicion de un corredor en el mapa en vivo. Solo dorsal: el servidor no
/// manda el nombre ni el id de la persona, y aqui no hay donde ponerlos.
@immutable
class LivePosition {
  const LivePosition({
    required this.bib,
    required this.lat,
    required this.lng,
    required this.distanceMeters,
    required this.at,
  });

  factory LivePosition.fromJson(Map<String, dynamic> json) => LivePosition(
    bib: json['bib'] as String?,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
    at: DateTime.tryParse(json['t'] as String? ?? '') ?? DateTime.now(),
  );

  final String? bib;
  final double lat;
  final double lng;
  final double distanceMeters;
  final DateTime at;

  /// Con quien se agrupa en el mapa. Sin dorsal no hay forma de distinguir dos
  /// corredores, asi que caen todos en la misma casilla: es preferible a
  /// inventar una clave por punto y pintar un rastro de fantasmas.
  String get key => bib ?? '?';
}

/// Preparacion, largada y corte de una maraton, tal como llegan por el socket.
@immutable
class MarathonLiveState {
  const MarathonLiveState({
    required this.marathonId,
    this.preparingAt,
    this.preparingMessage,
    this.startedAt,
    this.finishedAt,
  });

  factory MarathonLiveState.fromJson(Map<String, dynamic> json) =>
      MarathonLiveState(
        marathonId: json['marathonId'] as String,
        preparingAt: DateTime.tryParse(json['preparingAt'] as String? ?? ''),
        preparingMessage: json['preparingMessage'] as String?,
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
        finishedAt: DateTime.tryParse(json['finishedAt'] as String? ?? ''),
      );

  final String marathonId;
  final DateTime? preparingAt;

  /// El aviso del organizador. `null` = la app pone el texto por defecto.
  final String? preparingMessage;

  final DateTime? startedAt;
  final DateTime? finishedAt;

  /// Se esta corriendo ahora mismo.
  bool get running => startedAt != null && finishedAt == null;

  /// El mismo orden que en el servidor: lo ultimo que paso manda.
  MarathonPhase get phase {
    if (finishedAt != null) return MarathonPhase.finished;
    if (startedAt != null) return MarathonPhase.inProgress;
    if (preparingAt != null) return MarathonPhase.preparing;
    return MarathonPhase.notStarted;
  }
}

/// Que alguien cruzo la meta.
///
/// Solo el dorsal, como las posiciones: el servidor no manda quien es. Al
/// corredor le sirve igual —se reconoce por el suyo— y al panel tambien, que es
/// lo unico que pinta.
@immutable
class RunnerFinish {
  const RunnerFinish({
    required this.bib,
    required this.distanceMeters,
    required this.at,
  });

  factory RunnerFinish.fromJson(Map<String, dynamic> json) => RunnerFinish(
    bib: json['bib'] as String?,
    distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
    at: DateTime.tryParse(json['t'] as String? ?? '') ?? DateTime.now(),
  );

  final String? bib;
  final double distanceMeters;
  final DateTime at;
}

/// Cliente del namespace `/live` del backend.
///
/// **Uno solo para toda la app.** Un socket por pantalla significa varios
/// handshakes, varias reconexiones y, en el movil del corredor, el aviso de
/// largada llegando por un socket que se cerro al cambiar de pestana. Las
/// pantallas se suscriben a las salas que les interesan y el contador de
/// interesados decide cuando salir de una.
class LiveSocket {
  LiveSocket(this._storage);

  final TokenStorage _storage;

  io.Socket? _socket;

  /// Cuantas pantallas miran cada maraton. Salir de la sala al cerrar una
  /// pantalla dejaria ciega a otra que siguiera abierta detras.
  final _salas = <String, int>{};

  final _posiciones = StreamController<LivePosition>.broadcast();
  final _estados = StreamController<MarathonLiveState>.broadcast();
  final _llegadas = StreamController<RunnerFinish>.broadcast();
  final _inscripciones = StreamController<void>.broadcast();

  Stream<LivePosition> get positions => _posiciones.stream;
  Stream<MarathonLiveState> get states => _estados.stream;

  /// Quien va cruzando la meta. Lo decide el servidor mirando el GPS contra el
  /// trazado oficial, no el propio telefono.
  Stream<RunnerFinish> get finishes => _llegadas.stream;

  /// Algo cambio en una inscripcion de este corredor: el administrador valido
  /// su pago, le asignaron dorsal, se la cancelaron.
  ///
  /// **Sin datos a proposito.** El aviso solo dice "reelee tus carreras": la
  /// lista la sirve la API, que es la fuente, y copiar aqui el estado nuevo
  /// seria un segundo sitio donde equivocarse.
  ///
  /// Llega por la sala personal del corredor, en la que el servidor lo mete al
  /// abrir el socket: antes de que el pago se valide esa persona no esta
  /// inscrita en ninguna maraton y no hay sala de la que colgar el aviso.
  Stream<void> get registrations => _inscripciones.stream;

  /// Abre la conexion sin mirar ninguna maraton.
  ///
  /// Hace falta para los avisos de la sala personal: quien espera a que le
  /// validen el pago todavia no tiene ninguna sala de maraton que pedir, y sin
  /// conexion no se entera de nada hasta el siguiente sondeo.
  Future<void> ensureConnected() => _conectar();

  /// Empieza a mirar una maraton. Devuelve la baja: llamarla es lo que la
  /// deja de mirar.
  Future<VoidCallback> watch(String marathonId) async {
    final socket = await _conectar();
    _salas.update(marathonId, (n) => n + 1, ifAbsent: () => 1);
    if (_salas[marathonId] == 1) {
      socket.emit('spectate', {'marathonId': marathonId});
    }

    var dado = false;
    return () {
      if (dado) return;
      dado = true;
      final quedan = (_salas[marathonId] ?? 1) - 1;
      if (quedan > 0) {
        _salas[marathonId] = quedan;
        return;
      }
      _salas.remove(marathonId);
      _socket?.emit('leave', {'marathonId': marathonId});
    };
  }

  Future<void> dispose() async {
    _socket?.dispose();
    _socket = null;
    _salas.clear();
    await _posiciones.close();
    await _estados.close();
    await _llegadas.close();
    await _inscripciones.close();
  }

  Future<io.Socket> _conectar() async {
    final actual = _socket;
    if (actual != null) return actual;

    // El token va en `auth` del handshake y no en la query: la query acaba en
    // los logs del proxy inverso.
    final token = await _storage.readAccessToken();
    final socket = io.io(
      _urlDelNamespace(),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token ?? ''})
          .enableReconnection()
          .build(),
    );

    socket
      ..on('runner:position', (data) {
        if (data is Map) {
          _posiciones.add(LivePosition.fromJson(data.cast<String, dynamic>()));
        }
      })
      ..on('runner:finish', (data) {
        if (data is Map) {
          _llegadas.add(RunnerFinish.fromJson(data.cast<String, dynamic>()));
        }
      })
      ..on('registration:state', (_) => _inscripciones.add(null))
      ..on('marathon:state', (data) {
        if (data is Map) {
          _estados.add(
            MarathonLiveState.fromJson(data.cast<String, dynamic>()),
          );
        }
      })
      // Al reconectar el servidor no recuerda las salas: hay que volver a
      // pedirlas o el mapa se queda mudo justo despues de recuperar la senal,
      // que es cuando mas se mira.
      ..onConnect((_) {
        for (final id in _salas.keys) {
          socket.emit('spectate', {'marathonId': id});
        }
      });

    _socket = socket;
    return socket;
  }

  /// `https://host/api/v1` → `https://host/live`. El namespace cuelga de la
  /// raiz del servidor, no del prefijo de la API REST.
  String _urlDelNamespace() {
    final base = Uri.parse(apiBaseUrl);
    return base.replace(path: '/live', query: '').toString();
  }
}
