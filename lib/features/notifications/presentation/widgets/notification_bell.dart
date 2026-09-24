import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// La campana con el globo de no leidas. Abre el registro de notificaciones.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({this.style = AppIconButtonStyle.plain, super.key});

  final AppIconButtonStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sinLeer = ref.watch(unreadNotificationsProvider);
    final c = context.colors;

    return Badge(
      isLabelVisible: sinLeer > 0,
      label: Text(sinLeer > 99 ? '99+' : '$sinLeer'),
      backgroundColor: c.error,
      offset: const Offset(-6, 6),
      child: AppIconButton(
        icon: sinLeer > 0
            ? Icons.notifications_active_rounded
            : Icons.notifications_none_rounded,
        style: style,
        semanticsLabel: context.l10n.notificationsOpen(sinLeer),
        onPressed: () => context.push(Routes.notifications),
      ),
    );
  }
}
