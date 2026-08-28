import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/admin/presentation/providers/admin_providers.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Todas las maratones, publicadas o no.
///
/// Esta es la pestana que en la app del corredor es "Entrenar": mismo sitio en
/// la barra, misma forma de lista. Un admin no entrena desde el panel.
class AdminMarathonsPage extends ConsumerWidget {
  const AdminMarathonsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final maratones = ref.watch(adminMarathonsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminMarathonsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.adminMarathonNew),
        icon: const Icon(Icons.add_rounded),
        label: Text(t.adminNewMarathon),
      ),
      body: maratones.when(
        loading: () => const Center(child: Skeleton(width: 180, height: 20)),
        error: (error, _) => ErrorStateView(
          message: error is Failure ? error.localized(t) : t.adminLoadFailed,
          onRetry: () => ref.invalidate(adminMarathonsProvider),
        ),
        data: (lista) => lista.isEmpty
            ? EmptyState(
                icon: Icons.emoji_events_outlined,
                title: t.adminNoMarathonsTitle,
                message: t.adminNoMarathonsBody,
                actionLabel: t.adminNewMarathon,
                onAction: () => context.push(Routes.adminMarathonNew),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminMarathonsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.md,
                    AppSpacing.screenH,
                    AppSpacing.xxl * 2,
                  ),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) => _Fila(marathon: lista[i]),
                ),
              ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.marathon});

  final AdminMarathon marathon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: () => context.push(Routes.adminMarathonEditOf(marathon.id)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(marathon.name, style: context.text.titleMd),
                ),
                Icon(Icons.chevron_right_rounded, color: c.textSecondary),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${Fmt.fullDate(marathon.startsAt)} · ${marathon.city}',
              style: context.text.bodySm.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (marathon.running)
                  AppBadge(
                    label: t.adminLive,
                    icon: Icons.circle,
                    tone: AppTone.success,
                  ),
                if (marathon.finished)
                  AppBadge(
                    label: t.adminFinished,
                    icon: Icons.sports_score_rounded,
                    tone: AppTone.neutral,
                  ),
                AppBadge(
                  tone: marathon.published ? AppTone.info : AppTone.neutral,
                  label: marathon.published
                      ? t.adminPublished
                      : t.adminDraft,
                  icon: marathon.published
                      ? Icons.visibility_outlined
                      : Icons.edit_note_rounded,
                ),
                AppBadge(
                  tone: marathon.registrationsOpen
                      ? AppTone.brand
                      : AppTone.warning,
                  label: marathon.registrationsOpen
                      ? t.adminRegistrationsOpen
                      : t.adminRegistrationsClosed,
                  icon: marathon.registrationsOpen
                      ? Icons.how_to_reg_rounded
                      : Icons.lock_outline_rounded,
                ),
                AppBadge(
                  tone: AppTone.neutral,
                  label: t.adminSlots(marathon.slotsTaken, marathon.capacity),
                  icon: Icons.groups_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
