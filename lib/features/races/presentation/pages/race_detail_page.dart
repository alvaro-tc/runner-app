import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/features/races/presentation/providers/races_provider.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/event_image.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/countdown_pill.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:camrun/shared/widgets/molecules/tiles.dart';
import 'package:camrun/shared/widgets/organisms/route_map_view.dart';
import 'package:camrun/shared/widgets/organisms/splits_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RaceDetailPage extends ConsumerWidget {
  const RaceDetailPage({required this.entryId, this.locked = false, super.key});

  final String entryId;

  /// Sin salida. Es lo que ve quien ya cruzo la meta mientras la maraton sigue
  /// en marcha: la pantalla es la app entera, asi que un boton de atras no
  /// llevaria a ningun sitio. Ver `MarathonGateView`.
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final entry = ref.watch(raceDetailProvider(entryId));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: locked
            ? null
            : Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: AppIconButton(
                  icon: Icons.arrow_back_rounded,
                  semanticsLabel: t.commonBack,
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.races),
                ),
              ),
        title: Text(locked ? t.raceFinishedLockedTitle : t.raceDetailTitle),
      ),
      body: entry.when(
        loading: () => const Center(child: Skeleton(width: 180, height: 20)),
        error: (error, _) => ErrorStateView(
          message: error is Failure ? error.localized(t) : t.raceDetailNotFound,
          onRetry: () => ref.invalidate(raceDetailProvider(entryId)),
        ),
        data: (data) => _Body(entry: data),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.entry});

  final RaceEntry entry;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.raceCancelTitle),
        content: Text(
          t.raceCancelBody(entry.marathon.name, entry.paymentMethod),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(t.raceKeepMyPlace),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              t.raceCancelEntry,
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    final error = await ref.read(racesProvider.notifier).cancel(entry.id);
    if (!context.mounted) return;
    context.showSnack(error?.localized(t) ?? t.raceCancelled);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.l10n;
    final miles = ref.watch(useMilesProvider);
    final result = entry.result;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.xxl,
      ),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          child: SizedBox(
            height: 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                EventImage(imageUrl: entry.marathon.heroImageUrl),
                DecoratedBox(
                  decoration: BoxDecoration(gradient: c.heroOverlay),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(entry.marathon.name, style: context.text.headingLg),
        Text(
          '${Fmt.fullDate(entry.marathon.date)} · ${entry.marathon.location}',
          style: context.text.bodySm.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppBadge(
              label: t.commonBib(entry.bibNumber),
              icon: Icons.confirmation_num_outlined,
            ),
            AppBadge(label: entry.status.label(t), tone: AppTone.neutral),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (result != null)
          ..._resultBlocks(context, result, miles)
        else
          ..._upcomingBlocks(context, ref),
        const SizedBox(height: AppSpacing.xl),
        Text(t.raceRegistration, style: context.text.headingMd),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              SessionSummaryRow(
                label: t.raceRegisteredOn,
                value: Fmt.fullDate(entry.registeredAt),
              ),
              SessionSummaryRow(
                label: t.raceAmountPaid,
                value: Fmt.money(
                  entry.amountPaid.amount,
                  entry.amountPaid.currency,
                ),
              ),
              SessionSummaryRow(
                label: t.raceMethod,
                value: entry.paymentMethod,
              ),
              SessionSummaryRow(
                label: t.raceStatus,
                value: entry.paymentStatus.label(t),
                valueColor: switch (entry.paymentStatus) {
                  PaymentStatus.paid => c.success,
                  PaymentStatus.pending => c.warning,
                  PaymentStatus.failed => c.error,
                  PaymentStatus.refunded => c.error,
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: t.raceDownloadReceipt,
          variant: AppButtonVariant.outline,
          icon: Icons.receipt_long_outlined,
          onPressed: () => context.showSnack(t.raceReceiptComingSoon),
        ),
        if (result != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: t.raceShareResult,
            variant: AppButtonVariant.secondary,
            icon: Icons.ios_share_rounded,
            onPressed: () => context.showSnack(t.raceShareComingSoon),
          ),
        ] else if (entry.isUpcoming) ...[
          if (entry.canStart) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: t.raceGoToStartLine,
              icon: Icons.play_arrow_rounded,
              onPressed: () => context.push(Routes.raceStartOf(entry.id)),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: t.raceCancelRegistration,
            variant: AppButtonVariant.ghost,
            onPressed: () => _cancel(context, ref),
          ),
        ],
      ],
    );
  }

  List<Widget> _resultBlocks(
    BuildContext context,
    RaceResult result,
    bool miles,
  ) {
    final c = context.colors;
    final t = context.l10n;
    return [
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: SizedBox(
          height: 220,
          child: RouteMapView(
            route: result.route,
            interactive: false,
            markerEveryKm: 5,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.55,
        children: [
          MetricTile(
            icon: Icons.flag_rounded,
            value: Fmt.clock(result.finishTime),
            label: t.commonFinishTime,
            compact: true,
          ),
          MetricTile(
            icon: Icons.sensors_rounded,
            value: Fmt.clock(result.chipTime),
            label: t.raceChipTime,
            compact: true,
          ),
          MetricTile(
            icon: Icons.speed_rounded,
            value: Fmt.paceWithUnit(result.avgPacePerKm, miles: miles),
            label: t.commonAveragePace,
            compact: true,
          ),
          MetricTile(
            icon: Icons.rocket_launch_outlined,
            value: Fmt.speed(result.avgSpeedKmh, miles: miles),
            label: t.commonAverageSpeed,
            compact: true,
          ),
          MetricTile(
            icon: Icons.straighten_rounded,
            value: Fmt.distance(result.distanceKm, miles: miles),
            label: t.commonDistance,
            compact: true,
          ),
          MetricTile(
            icon: Icons.terrain_rounded,
            value: Fmt.elevation(result.elevationGainM),
            label: t.commonElevationGain,
            compact: true,
          ),
          if (result.bestKm != null)
            MetricTile(
              icon: Icons.bolt_rounded,
              value: Fmt.paceWithUnit(result.bestKm!, miles: miles),
              label: t.raceBestKm,
              compact: true,
              tone: c.success,
            ),
          if (result.overallRank != null && result.totalParticipants != null)
            MetricTile(
              icon: Icons.leaderboard_outlined,
              value: Fmt.rank(result.overallRank!, result.totalParticipants!),
              label: t.raceOverallRank,
              compact: true,
            ),
          if (result.ageGroupRank != null)
            MetricTile(
              icon: Icons.groups_outlined,
              value: '#${result.ageGroupRank}',
              label: t.raceAgeGroupRank,
              compact: true,
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(t.commonSplits, style: context.text.headingMd),
      const SizedBox(height: AppSpacing.md),
      SplitsChart(splits: result.splits, miles: miles),
    ];
  }

  List<Widget> _upcomingBlocks(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.l10n;
    final remaining = entry.marathon.date.difference(DateTime.now());
    return [
      Row(
        children: [
          Expanded(child: Text(t.raceStartsIn, style: context.text.headingMd)),
          CountdownPill(remaining: remaining),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            StatRow(
              icon: Icons.inventory_2_outlined,
              title: t.raceKitCollection,
              subtitle: t.raceKitCollectionSubtitle,
            ),
            const AppDivider(),
            StatRow(
              icon: Icons.flag_outlined,
              title: t.raceStartTime,
              subtitle: t.raceStartTimeSubtitle,
            ),
            const AppDivider(),
            StatRow(
              icon: Icons.backpack_outlined,
              title: t.raceBagDrop,
              subtitle: t.raceBagDropSubtitle,
            ),
          ],
        ),
      ),
    ];
  }
}
