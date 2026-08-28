import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/home/presentation/providers/home_provider.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/event_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RaceCard extends ConsumerWidget {
  const RaceCard({required this.entry, required this.onTap, super.key});

  final RaceEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.l10n;
    final result = entry.result;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: c.border),
              boxShadow: c.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: EventImage(
                          imageUrl: entry.marathon.heroImageUrl,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.marathon.name,
                            style: context.text.titleMd,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${Fmt.dayMonth(entry.marathon.date)} · '
                            '${entry.marathon.city}',
                            style: context.text.bodySm.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppBadge(
                      label: t.commonBib(entry.bibNumber),
                      tone: AppTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppBadge(
                      label: switch (entry.paymentStatus) {
                        // El monto solo esta en el detalle: la lista no trae
                        // los cobros. Sin el se dice "Paid" a secas, en vez de
                        // un "Paid 0,00" que seria mentira.
                        PaymentStatus.paid =>
                          entry.amountPaid.amount == 0
                              ? t.paymentStatusPaid
                              : t.racesPaidAmount(
                                  Fmt.money(
                                    entry.amountPaid.amount,
                                    entry.amountPaid.currency,
                                  ),
                                ),
                        _ => entry.paymentStatus.label(t),
                      },
                      tone: switch (entry.paymentStatus) {
                        PaymentStatus.paid => AppTone.success,
                        PaymentStatus.pending => AppTone.warning,
                        PaymentStatus.failed => AppTone.error,
                        PaymentStatus.refunded => AppTone.error,
                      },
                    ),
                    if (entry.isUpcoming)
                      AppBadge(
                        label: Fmt.relativeShort(
                          entry.marathon.date.difference(
                            ref.watch(nowProvider)(),
                          ),
                          t,
                        ),
                        icon: Icons.schedule_rounded,
                      ),
                  ],
                ),
                if (result != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  const AppDivider(),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                Fmt.clock(result.finishTime),
                                style: context.text.headingLg,
                              ),
                            ),
                            Text(
                              t.commonFinishTime,
                              style: context.text.labelSm.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          value: Fmt.paceWithUnit(result.avgPacePerKm),
                          label: t.racesAvgPace,
                        ),
                      ),
                      if (result.overallRank != null &&
                          result.totalParticipants != null)
                        Expanded(
                          child: _MiniStat(
                            value: '#${result.overallRank}',
                            label: t.racesOfTotal(result.totalParticipants!),
                          ),
                        ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: t.racesViewDetails,
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.sm,
                    onPressed: onTap,
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(value, style: context.text.titleMd),
      ),
      Text(
        label,
        style: context.text.labelSm.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    ],
  );
}
