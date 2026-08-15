import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/app/router/app_routes.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/formatters/formatters.dart';
import 'package:paceup/core/services/settings_provider.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/features/races/domain/entities/race_entry.dart';
import 'package:paceup/features/races/presentation/providers/races_provider.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';
import 'package:paceup/shared/widgets/atoms/app_icon_button.dart';
import 'package:paceup/shared/widgets/atoms/app_indicators.dart';
import 'package:paceup/shared/widgets/atoms/event_image.dart';
import 'package:paceup/shared/widgets/atoms/skeleton.dart';
import 'package:paceup/shared/widgets/molecules/countdown_pill.dart';
import 'package:paceup/shared/widgets/molecules/states.dart';
import 'package:paceup/shared/widgets/molecules/tiles.dart';
import 'package:paceup/shared/widgets/organisms/route_map_view.dart';
import 'package:paceup/shared/widgets/organisms/splits_chart.dart';

class RaceDetailPage extends ConsumerWidget {
  const RaceDetailPage({required this.entryId, super.key});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(racesProvider);
    final entry = ref.watch(raceEntryProvider(entryId));

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: AppIconButton(
            icon: Icons.arrow_back_rounded,
            semanticsLabel: 'Go back',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(Routes.races),
          ),
        ),
        title: const Text('My race'),
      ),
      body: entries.isLoading && entry == null
          ? const Center(child: Skeleton(width: 180, height: 20))
          : entry == null
          ? ErrorStateView(
              message: 'We could not find that registration.',
              onRetry: () => context.go(Routes.races),
            )
          : _Body(entry: entry),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.entry});

  final RaceEntry entry;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this registration?'),
        content: Text(
          'Your place at ${entry.marathon.name} is released and the entry fee '
          'is refunded to ${entry.paymentMethod}. Re-entry depends on '
          'availability.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Keep my place'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              'Cancel entry',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    final error = await ref.read(racesProvider.notifier).cancel(entry.id);
    if (!context.mounted) return;
    context.showSnack(error ?? 'Registration cancelled. Refund on its way.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
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
                EventImage(
                  imageUrl: entry.marathon.heroImageUrl,
                  seedText: entry.marathon.id,
                ),
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
              label: 'BIB ${entry.bibNumber}',
              icon: Icons.confirmation_num_outlined,
            ),
            AppBadge(label: entry.status.label, tone: AppTone.neutral),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (result != null)
          ..._resultBlocks(context, result, miles)
        else
          ..._upcomingBlocks(context, ref),
        const SizedBox(height: AppSpacing.xl),
        Text('Registration', style: context.text.headingMd),
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
                label: 'Registered on',
                value: Fmt.fullDate(entry.registeredAt),
              ),
              SessionSummaryRow(
                label: 'Amount paid',
                value: Fmt.money(
                  entry.amountPaid.amount,
                  entry.amountPaid.currency,
                ),
              ),
              SessionSummaryRow(label: 'Method', value: entry.paymentMethod),
              SessionSummaryRow(
                label: 'Status',
                value: entry.paymentStatus.label,
                valueColor: switch (entry.paymentStatus) {
                  PaymentStatus.paid => c.success,
                  PaymentStatus.pending => c.warning,
                  PaymentStatus.refunded => c.error,
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Download receipt',
          variant: AppButtonVariant.outline,
          icon: Icons.receipt_long_outlined,
          onPressed: () => context.showSnack(
            'Receipts download once the billing service is connected.',
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Share result',
            variant: AppButtonVariant.secondary,
            icon: Icons.ios_share_rounded,
            onPressed: () =>
                context.showSnack('A shareable finisher card is on the way.'),
          ),
        ] else if (entry.isUpcoming) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Cancel registration',
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
            label: 'Finish time',
            compact: true,
          ),
          MetricTile(
            icon: Icons.sensors_rounded,
            value: Fmt.clock(result.chipTime),
            label: 'Chip time',
            compact: true,
          ),
          MetricTile(
            icon: Icons.speed_rounded,
            value: Fmt.paceWithUnit(result.avgPacePerKm, miles: miles),
            label: 'Average pace',
            compact: true,
          ),
          MetricTile(
            icon: Icons.rocket_launch_outlined,
            value: Fmt.speed(result.avgSpeedKmh, miles: miles),
            label: 'Average speed',
            compact: true,
          ),
          MetricTile(
            icon: Icons.straighten_rounded,
            value: Fmt.distance(result.distanceKm, miles: miles),
            label: 'Distance',
            compact: true,
          ),
          MetricTile(
            icon: Icons.terrain_rounded,
            value: Fmt.elevation(result.elevationGainM),
            label: 'Elevation gain',
            compact: true,
          ),
          if (result.bestKm != null)
            MetricTile(
              icon: Icons.bolt_rounded,
              value: Fmt.paceWithUnit(result.bestKm!, miles: miles),
              label: 'Best km',
              compact: true,
              tone: c.success,
            ),
          if (result.overallRank != null && result.totalParticipants != null)
            MetricTile(
              icon: Icons.leaderboard_outlined,
              value: Fmt.rank(result.overallRank!, result.totalParticipants!),
              label: 'Overall rank',
              compact: true,
            ),
          if (result.ageGroupRank != null)
            MetricTile(
              icon: Icons.groups_outlined,
              value: '#${result.ageGroupRank}',
              label: 'Age group rank',
              compact: true,
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      Text('Splits', style: context.text.headingMd),
      const SizedBox(height: AppSpacing.md),
      SplitsChart(splits: result.splits, miles: miles),
    ];
  }

  List<Widget> _upcomingBlocks(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final remaining = entry.marathon.date.difference(DateTime.now());
    return [
      Row(
        children: [
          Expanded(child: Text('Starts in', style: context.text.headingMd)),
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
        child: const Column(
          children: [
            StatRow(
              icon: Icons.inventory_2_outlined,
              title: 'Kit collection',
              subtitle: 'Expo opens two days before, 10:00–20:00',
            ),
            AppDivider(),
            StatRow(
              icon: Icons.flag_outlined,
              title: 'Start time',
              subtitle: 'Corrals close 20 minutes before your wave',
            ),
            AppDivider(),
            StatRow(
              icon: Icons.backpack_outlined,
              title: 'Bag drop',
              subtitle: 'At the start village, opens 90 minutes prior',
            ),
          ],
        ),
      ),
    ];
  }
}
