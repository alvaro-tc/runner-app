import 'dart:async';

import 'package:camrun/core/network/network_providers.dart';
import 'package:camrun/core/services/foreground_poller.dart';
import 'package:camrun/features/home/presentation/providers/home_provider.dart';
import 'package:camrun/features/home/presentation/providers/marathon_providers.dart';
import 'package:camrun/features/races/presentation/providers/races_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cada cuanto se vuelve a pedir "mis carreras" con la app delante.
///
/// **Es la red, no el camino.** Lo inmediato lo trae el socket —el estado de la
/// carrera por su sala, el pago validado por la sala personal del corredor—; el
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
  ForegroundPoller? _poller;
  AppLifecycleListener? _ciclo;
  StreamSubscription<void>? _avisos;
  VoidCallback? _releasePersonal;

  @override
  void initState() {
    super.initState();
    _poller = ForegroundPoller(interval: _cadencia, onPoll: _refrescar);
    // Volver del fondo no espera al siguiente tic: el telefono estuvo en el
    // bolsillo y lo que se perdio mientras tanto es justo lo que hay que ver.
    ref.listenManual(awaitingValidationProvider, (_, next) {
      if (next.value?.isNotEmpty ?? false) {
        _releasePersonal ??= ref.read(liveSocketProvider).watchPersonal();
      } else if (next.hasValue) {
        _releasePersonal?.call();
        _releasePersonal = null;
      }
    }, fireImmediately: true);
    _ciclo = AppLifecycleListener(onResume: _alVolver);
    _avisos = ref
        .read(liveSocketProvider)
        .registrations
        .listen((_) => _refrescar());
  }

  @override
  void dispose() {
    _releasePersonal?.call();
    _poller?.dispose();
    _ciclo?.dispose();
    unawaited(_avisos?.cancel());
    super.dispose();
  }

  void _refrescar() {
    if (mounted && !ref.read(racesProvider).isLoading) {
      ref.invalidate(racesProvider);
    }
  }

  /// El catalogo —y con el los afiches— tambien vive en providers que no se
  /// liberan: sin esto, una portada subida con la app del corredor en segundo
  /// plano no aparecia hasta tirar para recargar o matar la app. Solo al volver
  /// y no en cada tic: el catalogo lo cambia un organizador, no el reloj.
  void _alVolver() {
    _refrescar();
    ref
      ..invalidate(homeProvider)
      ..invalidate(upcomingMarathonsProvider)
      ..invalidate(marathonProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
