import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/home/presentation/providers/marathon_providers.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/features/races/presentation/providers/races_provider.dart';
import 'package:camrun/features/races/presentation/widgets/race_card.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/event_image.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:camrun/shared/widgets/molecules/tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RacesPage extends ConsumerStatefulWidget {
  const RacesPage({super.key});

  @override
  ConsumerState<RacesPage> createState() => _RacesPageState();
}

class _RacesPageState extends ConsumerState<RacesPage> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(racesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.colors.primary,
          onRefresh: () async => ref.invalidate(racesProvider),
          child: entries.when(
            loading: () => const _RacesSkeleton(),
            error: (error, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: context.screenSize.height * 0.2),
                ErrorStateView(
                  message: error.localized(context.l10n),
                  onRetry: () => ref.invalidate(racesProvider),
                ),
              ],
            ),
            data: _body,
          ),
        ),
      ),
    );
  }

  Widget _body(List<RaceEntry> all) {
    final t = context.l10n;
    // El corte lo pone la fecha de largada, igual que en la API. Con el
    // resultado como criterio, una carrera de ayer sin tiempos cargados seguia
    // saliendo en "Upcoming" y una futura no salia en ninguna de las dos.
    final shown = [
      for (final entry in all)
        if (entry.isUpcoming != _showCompleted) entry,
    ];
    // Solo cuelga de "Upcoming": en "Completed" un catalogo de carreras
    // futuras no responde a nada.
    final catalogo = _showCompleted
        ? const <Marathon>[]
        : ref.watch(upcomingMarathonsProvider).value ?? const <Marathon>[];

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.base,
        AppSpacing.screenH,
        AppSpacing.xxl,
      ),
      children: [
        Text(t.racesTitle, style: context.text.headingLg),
        const SizedBox(height: AppSpacing.lg),
        const _TotalsCard(),
        const SizedBox(height: AppSpacing.lg),
        _Segmented(
          showCompleted: _showCompleted,
          onChanged: (v) => setState(() => _showCompleted = v),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Con el catalogo debajo, el cartel de vacio sobra: ya hay algo que
        // mirar y donde tocar.
        if (shown.isEmpty && catalogo.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: EmptyState(
              icon: Icons.emoji_events_outlined,
              title: _showCompleted
                  ? t.racesNoFinishesTitle
                  : t.racesNoRacesTitle,
              message: _showCompleted
                  ? t.racesNoFinishesMessage
                  : t.racesNoRacesMessage,
              actionLabel: t.racesBrowseEvents,
              onAction: () => context.go(Routes.home),
            ),
          )
        else if (shown.isNotEmpty)
          for (final entry in shown)
            RaceCard(
              entry: entry,
              onTap: () => context.push(Routes.raceDetailOf(entry.id)),
            ),
        // Sin dorsal todavia, la pestaña no puede quedarse en un cartel: las
        // proximas del catalogo son la respuesta a "no veo ninguna carrera".
        if (catalogo.isNotEmpty) _OpenForRegistration(marathons: catalogo),
      ],
    );
  }
}

/// Las proximas del catalogo, al pie de "Upcoming". No son carreras del
/// usuario: son a las que todavia se puede apuntar, y por eso llevan su propio
/// encabezado en vez de mezclarse con las tarjetas de dorsal.
class _OpenForRegistration extends StatelessWidget {
  const _OpenForRegistration({required this.marathons});

  final List<Marathon> marathons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(title: context.l10n.racesUpcomingMarathons),
        const SizedBox(height: AppSpacing.md),
        for (final marathon in marathons)
          _MarathonRow(
            marathon: marathon,
            onTap: () => context.push(Routes.marathonDetailOf(marathon.id)),
          ),
      ],
    );
  }
}

class _MarathonRow extends StatelessWidget {
  const _MarathonRow({required this.marathon, required this.onTap});

  final Marathon marathon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: EventImage(imageUrl: marathon.heroImageUrl),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marathon.name,
                        style: context.text.titleMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${Fmt.dayMonth(marathon.date)} · ${marathon.city} · '
                        '${Fmt.distanceShort(marathon.distanceKm)}',
                        style: context.text.bodySm.copyWith(
                          color: c.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // "Registration open" es el caso normal y no dice nada que la
                // fila no diga ya; lo que urge —cierra, se lleno— si.
                if (marathon.status != RegistrationStatus.open) ...[
                  const SizedBox(width: AppSpacing.sm),
                  AppBadge(
                    label: marathon.status.label(context.l10n),
                    tone: marathon.status == RegistrationStatus.closingSoon
                        ? AppTone.warning
                        : AppTone.neutral,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalsCard extends ConsumerWidget {
  const _TotalsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.l10n;
    final totals = ref.watch(raceTotalsProvider);
    final miles = ref.watch(useMilesProvider);
    if (totals == null) {
      return const Skeleton(
        width: double.infinity,
        height: 132,
        radius: AppRadius.xxl,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: c.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: c.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Total(
                  value: '${totals.racesJoined}',
                  label: t.racesJoined,
                ),
              ),
              Expanded(
                child: _Total(
                  value: Fmt.distance(totals.distanceRacedKm, miles: miles),
                  label: t.racesDistanceRaced,
                ),
              ),
              Expanded(
                child: _Total(
                  value: Fmt.money(
                    totals.totalSpent.amount,
                    totals.totalSpent.currency,
                  ),
                  label: t.racesTotalSpent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            totals.bestMarathon == null
                ? t.racesNoMarathonYet
                : t.racesBestMarathon(Fmt.durationShort(totals.bestMarathon!)),
            style: context.text.bodySm.copyWith(
              color: c.onPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppDurations.slow,
            builder: (context, t, child) => Opacity(opacity: t, child: child),
            child: Text(
              value,
              style: context.text.headingMd.copyWith(color: c.onPrimary),
            ),
          ),
        ),
        Text(
          label,
          style: context.text.labelSm.copyWith(
            color: c.onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.showCompleted, required this.onChanged});

  final bool showCompleted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final labels = [context.l10n.racesUpcoming, context.l10n.racesCompleted];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: c.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          for (final (index, label) in labels.indexed)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(index == 1),
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: (index == 1) == showCompleted
                        ? c.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: context.text.labelSm.copyWith(
                      color: (index == 1) == showCompleted
                          ? c.primary
                          : c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RacesSkeleton extends StatelessWidget {
  const _RacesSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenH,
      AppSpacing.base,
      AppSpacing.screenH,
      AppSpacing.xxl,
    ),
    children: const [
      Skeleton(width: 160, height: 28),
      SizedBox(height: AppSpacing.lg),
      Skeleton(width: double.infinity, height: 132, radius: AppRadius.xxl),
      SizedBox(height: AppSpacing.lg),
      Skeleton(width: double.infinity, height: 48, radius: AppRadius.pill),
      SizedBox(height: AppSpacing.lg),
      Skeleton(width: double.infinity, height: 150, radius: AppRadius.xl),
      SizedBox(height: AppSpacing.md),
      Skeleton(width: double.infinity, height: 150, radius: AppRadius.xl),
    ],
  );
}
