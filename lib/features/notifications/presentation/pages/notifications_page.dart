import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
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
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final bandeja = ref.watch(notificationsProvider);
    final sinLeer = ref.watch(unreadNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.notificationsTitle),
        actions: [
          if (sinLeer > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: Text(t.notificationsMarkAllRead),
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
          data: (b) => b.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: context.screenSize.height * 0.15),
                    EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: t.notificationsEmptyTitle,
                      message: t.notificationsEmptyBody,
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  itemCount: b.items.length,
                  separatorBuilder: (_, _) =>
                      const AppDivider(indent: AppSpacing.screenH),
                  itemBuilder: (context, i) => _Fila(
                    notification: b.items[i],
                    onTap: () => openNotification(context, ref, b.items[i]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

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

    return Material(
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
                child: Icon(notificationIcon(notification), color: colores.fg),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(AppSpacing.screenH),
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
  );
}
