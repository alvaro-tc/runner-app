import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/layout/breakpoints.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/notifications/domain/notifications.dart';
import 'package:camrun/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:camrun/features/notifications/presentation/widgets/notification_actions.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El registro de notificaciones: lo que llego, del mas nuevo al mas viejo.
///
/// Cada fila se desliza para borrarla o abre su menu para marcarla leida sin
/// navegar; el filtro de arriba deja ver solo lo pendiente.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _soloNoLeidas = false;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final bandeja = ref.watch(notificationsProvider);
    final sinLeer = ref.watch(unreadNotificationsProvider);
    final hayLeidas = bandeja.value?.items.any((n) => !n.unread) ?? false;
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.notificationsTitle),
        actions: [
          if (sinLeer > 0 || hayLeidas)
            PopupMenuButton<VoidCallback>(
              tooltip: t.notificationsMoreActions,
              onSelected: (accion) => accion(),
              itemBuilder: (_) => [
                if (sinLeer > 0)
                  PopupMenuItem(
                    value: notifier.markAllRead,
                    child: Text(t.notificationsMarkAllRead),
                  ),
                if (hayLeidas)
                  PopupMenuItem(
                    value: notifier.deleteRead,
                    child: Text(t.notificationsDeleteRead),
                  ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () => ref.refresh(notificationsProvider.future),
        child: bandeja.when(
          skipLoadingOnReload: true,
          loading: () => const _Skeleton(),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: context.screenSize.height * 0.15),
              ErrorStateView(
                message: error.localized(t),
                onRetry: () => ref.invalidate(notificationsProvider),
              ),
            ],
          ),
          data: (b) {
            final items = _soloNoLeidas
                ? b.items.where((n) => n.unread).toList()
                : b.items;
            // Las filas van de borde a borde en telefono; en una tablet, en una
            // columna centrada: una notificacion de un metro no se lee.
            return LayoutBuilder(
              builder: (context, box) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppLayout.surplus(
                    box.maxWidth,
                    maxWidth: AppSizes.readableMaxWidth,
                  ),
                  0,
                  AppLayout.surplus(
                    box.maxWidth,
                    maxWidth: AppSizes.readableMaxWidth,
                  ),
                  AppSpacing.xxl,
                ),
                children: [
                  if (b.items.isNotEmpty) _filtro(context),
                  if (items.isEmpty) ...[
                    SizedBox(height: context.screenSize.height * 0.15),
                    if (b.items.isNotEmpty)
                      EmptyState(
                        icon: Icons.done_all_rounded,
                        title: t.notificationsUnreadEmptyTitle,
                        message: t.notificationsUnreadEmptyBody,
                      )
                    else
                      EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: t.notificationsEmptyTitle,
                        message: t.notificationsEmptyBody,
                      ),
                  ],
                  for (final (i, n) in items.indexed) ...[
                    if (i > 0) const AppDivider(indent: AppSpacing.screenH),
                    _Fila(
                      key: ValueKey(n.id),
                      notification: n,
                      onTap: () => openNotification(context, ref, n),
                      onMarkRead: () => notifier.markRead(n.id),
                      onDelete: () => notifier.delete(n.id),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _filtro(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenH,
        vertical: AppSpacing.sm,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final (solo, texto) in [
            (false, t.notificationsFilterAll),
            (true, t.notificationsFilterUnread),
          ])
            ChoiceChip(
              label: Text(texto),
              selected: _soloNoLeidas == solo,
              onSelected: (_) => setState(() => _soloNoLeidas = solo),
            ),
        ],
      ),
    );
  }
}

enum _Accion { markRead, delete }

class _Fila extends StatelessWidget {
  const _Fila({
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
    required this.onDelete,
    super.key,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final texto = notificationText(context, notification);
    final nueva = notification.unread;
    final tono = switch (notification.type) {
      NotificationTypes.paymentApproved => AppTone.success,
      NotificationTypes.paymentRejected => AppTone.error,
      _ => AppTone.brand,
    };
    final colores = tono.resolve(context);

    final t = context.l10n;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: ColoredBox(
        color: c.error,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.screenH),
            child: Icon(Icons.delete_outline_rounded, color: c.onPrimary),
          ),
        ),
      ),
      child: Material(
        // Las no leidas con fondo propio: se distinguen de un vistazo.
        color: nueva ? colores.bg.withValues(alpha: 0.35) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH,
              vertical: AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppSizes.minTapTarget,
                  height: AppSizes.minTapTarget,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colores.bg,
                  ),
                  child: Icon(
                    notificationIcon(notification),
                    color: colores.fg,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        texto.title,
                        style: context.text.titleMd.copyWith(
                          fontWeight: nueva ? FontWeight.w700 : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        texto.body,
                        style: context.text.bodySm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${Fmt.dayMonth(notification.createdAt.toLocal())} · '
                        '${Fmt.timeOfDay(notification.createdAt.toLocal())}',
                        style: context.text.labelSm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (nueva) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Container(
                      width: AppSpacing.sm,
                      height: AppSpacing.sm,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.primary,
                      ),
                    ),
                  ),
                ],
                PopupMenuButton<_Accion>(
                  tooltip: t.notificationsMoreActions,
                  icon: Icon(Icons.more_vert_rounded, color: c.textSecondary),
                  onSelected: (a) => switch (a) {
                    _Accion.markRead => onMarkRead(),
                    _Accion.delete => onDelete(),
                  },
                  itemBuilder: (_) => [
                    if (nueva)
                      PopupMenuItem(
                        value: _Accion.markRead,
                        child: Text(t.notificationsMarkRead),
                      ),
                    PopupMenuItem(
                      value: _Accion.delete,
                      child: Text(t.notificationsDelete),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.screenH).add(
        EdgeInsets.symmetric(
          horizontal: AppLayout.surplus(
            box.maxWidth,
            maxWidth: AppSizes.readableMaxWidth,
          ),
        ),
      ),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (_, _) => const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton.circle(size: AppSizes.minTapTarget),
          SizedBox(width: AppSpacing.md),
          Expanded(child: SkeletonLines()),
        ],
      ),
    ),
  );
}
