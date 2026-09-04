import 'dart:async';

import 'package:camrun/core/network/network_providers.dart';
import 'package:camrun/features/races/presentation/providers/races_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cada cuanto se vuelve a pedir "mis carreras" con la app delante.
///
/// **Es la red, no el camino.** Lo inmediato lo trae el socket —el estado de la
/// maraton por su sala, el pago validado por la sala personal del corredor—; el
/// sondeo es para cuando ese aviso no llego: el telefono sin cobertura en el
/// momento exacto, el socket reconectando, el servidor que todavia no manda ese
/// evento. Por eso es corto: lo que hay al otro lado son decisiones de una
/// persona y el corredor esta mirando la pantalla cuando pasan.
const _cadencia = Duration(seconds: 20);

/// Mantiene "mis carreras" fresca sola mientras la app del corredor este
/// abierta: en el instante cuando el socket avisa, y cada [_cadencia] cuando no.
///
/// Sin esto, validar un pago, poner la carrera en preparacion, largarla o
/// cortarla solo se ve al cerrar y volver a abrir la app.
///
/// Todo cuelga de [racesProvider] —el aviso de preparacion, la pantalla de
/// carrera y el detalle de la inscripcion salen de ahi—, asi que refrescar esa
/// lista los arregla todos de una vez.
///
/// **Widget y no provider** por el reloj: montado en el arbol, el sondeo se
/// apaga con la app del corredor. Un `Timer.periodic` colgado de un provider
/// vivo para siempre sobrevive al arbol, que es una fuga.
class RacesAutoRefresh extends ConsumerStatefulWidget {
  const RacesAutoRefresh({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<RacesAutoRefresh> createState() => _RacesAutoRefreshState();
}

class _RacesAutoRefreshState extends ConsumerState<RacesAutoRefresh> {
  Timer? _reloj;
  AppLifecycleListener? _ciclo;
  StreamSubscription<void>? _avisos;

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(_cadencia, (_) => _refrescar());
    // Volver del fondo no espera al siguiente tic: el telefono estuvo en el
    // bolsillo y lo que se perdio mientras tanto es justo lo que hay que ver.
    _ciclo = AppLifecycleListener(onResume: _refrescar);
    _avisos = ref
        .read(liveSocketProvider)
        .registrations
        .listen((_) => _refrescar());
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _ciclo?.dispose();
    unawaited(_avisos?.cancel());
    super.dispose();
  }

  void _refrescar() => ref.invalidate(racesProvider);

  @override
  Widget build(BuildContext context) {
    // La conexion se abre **solo mientras hay un pago esperando**: es la unica
    // situacion en la que el corredor necesita el socket sin estar inscrito en
    // ninguna maraton, y dura lo que tarda un administrador en mirarlo, no las
    // semanas que hay hasta la carrera. Con la inscripcion ya confirmada el
    // socket lo abre la puerta, por la sala de la maraton.
    final esperando = ref.watch(awaitingValidationProvider).value;
    if (esperando != null && esperando.isNotEmpty) {
      unawaited(ref.read(liveSocketProvider).ensureConnected());
    }

    return widget.child;
  }
}

// ponytail: sondeo fijo. Si el servidor llega a mandar el pago validado por el
// socket —`registration:state` en la sala del corredor—, esto se queda solo
// como red de seguridad y la cadencia puede irse a minutos.
