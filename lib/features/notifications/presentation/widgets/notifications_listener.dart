import 'dart:async';

import 'package:camrun/core/network/network_providers.dart';
import 'package:camrun/features/auth/presentation/providers/auth_provider.dart';
import 'package:camrun/features/notifications/domain/notifications.dart';
import 'package:camrun/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:camrun/features/notifications/presentation/widgets/notification_actions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Red de seguridad del socket: lo inmediato llega por `notification:new`.
const _cadencia = Duration(minutes: 1);

/// Mantiene la bandeja al dia mientras la app esta abierta y, cuando aparece
/// un pago validado o rechazado sin leer, le abre al corredor su ventana.
///
/// La ventana sale de la **bandeja**, no del evento del socket: asi tambien la
/// ve quien tenia el telefono apagado cuando lo validaron, y al abrirse queda
/// leida para no repetirse en el siguiente arranque.
///
/// Widget y no provider por el reloj, como `RacesAutoRefresh`: se apaga con el
/// arbol.
class NotificationsListener extends ConsumerStatefulWidget {
  const NotificationsListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationsListener> createState() =>
      _NotificationsListenerState();
}

class _NotificationsListenerState extends ConsumerState<NotificationsListener> {
  Timer? _reloj;
  AppLifecycleListener? _ciclo;
  StreamSubscription<void>? _avisos;
  bool _ventanaAbierta = false;

  @override
  void initState() {
    super.initState();
    final socket = ref.read(liveSocketProvider);
    _reloj = Timer.periodic(_cadencia, (_) => _refrescar());
    _ciclo = AppLifecycleListener(onResume: _refrescar);
    _avisos = socket.notifications.listen((_) => _refrescar());

    // El organizador necesita el socket siempre: los pagos le llegan sin que
    // este mirando ninguna maraton. Al corredor se lo abre `RacesAutoRefresh`
    // mientras espera validacion, que es cuando le puede llegar algo.
    if (ref.read(authProvider).isStaff) unawaited(socket.ensureConnected());

    ref.listenManual(
      notificationsProvider,
      (_, next) => _celebrar(next.value),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _ciclo?.dispose();
    unawaited(_avisos?.cancel());
    super.dispose();
  }

  void _refrescar() => ref.invalidate(notificationsProvider);

  void _celebrar(NotificationInbox? bandeja) {
    if (_ventanaAbierta || bandeja == null) return;
    final pendiente = bandeja.items
        .where((n) => n.unread && NotificationTypes.announced.contains(n.type))
        .firstOrNull;
    if (pendiente == null) return;

    _ventanaAbierta = true;
    // Despues del frame: puede dispararse en mitad de un build.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await openNotification(context, ref, pendiente);
      _ventanaAbierta = false;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
