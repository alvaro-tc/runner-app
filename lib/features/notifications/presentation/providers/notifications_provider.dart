import 'package:camrun/app/dependencies.dart';
import 'package:camrun/features/auth/presentation/providers/auth_provider.dart';
import 'package:camrun/features/notifications/domain/notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La bandeja de la campana. Se relee al llegar un aviso por el socket, al
/// volver del fondo y cada minuto; marcar como leida es optimista.
class NotificationsNotifier extends AsyncNotifier<NotificationInbox> {
  @override
  Future<NotificationInbox> build() async {
    // Cerrar sesion vacia la bandeja: la del siguiente usuario no es esta.
    final signedIn = ref.watch(authProvider.select((a) => a.ready));
    if (!signedIn) return (items: const <AppNotification>[], unreadCount: 0);
    return (await ref.watch(notificationRepositoryProvider).fetchInbox())
        .unwrap();
  }

  Future<void> markRead(String id) async {
    final actual = state.value;
    if (actual == null) return;
    final estaba = actual.items.any((n) => n.id == id && n.unread);
    if (!estaba) return;

    state = AsyncData((
      items: [for (final n in actual.items) n.id == id ? n.markedRead() : n],
      unreadCount: actual.unreadCount > 0 ? actual.unreadCount - 1 : 0,
    ));
    // Si falla, el siguiente sondeo la devuelve sin leer: no vale un error.
    await ref.read(notificationRepositoryProvider).markRead(id);
  }

  Future<void> markAllRead() async {
    final actual = state.value;
    if (actual == null || actual.unreadCount == 0) return;
    state = AsyncData((
      items: [for (final n in actual.items) n.markedRead()],
      unreadCount: 0,
    ));
    await ref.read(notificationRepositoryProvider).markAllRead();
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationInbox>(
      NotificationsNotifier.new,
      // El sondeo ya reintenta cada minuto; un segundo reloj no aporta.
      retry: (_, _) => null,
    );

/// El numero del globo de la campana.
final unreadNotificationsProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).value?.unreadCount ?? 0,
);
