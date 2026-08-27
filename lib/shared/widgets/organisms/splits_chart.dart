import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/formatters/formatters.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/features/train/domain/entities/training_run.dart';

/// Per-kilometre pace bars with the average drawn across them. Faster than
/// average reads green, slower reads neutral, and the best km is highlighted.
class SplitsChart extends StatelessWidget {
  const SplitsChart({required this.splits, this.miles = false, super.key});

  final List<KmSplit> splits;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (splits.isEmpty) {
      return Text(
        context.l10n.splitsTooShort,
        style: context.text.bodySm.copyWith(color: c.textSecondary),
      );
    }

    final paces = [for (final s in splits) s.pace.inSeconds.toDouble()];
    final average = paces.reduce((a, b) => a + b) / paces.length;
    final fastest = paces.reduce((a, b) => a < b ? a : b);
    // Bars grow downward in pace terms, so invert: shorter pace = taller bar.
    final worst = paces.reduce((a, b) => a > b ? a : b);
    final span = (worst - fastest).clamp(1, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170,
          child: BarChart(
            BarChartData(
              maxY: 1.15,
              minY: 0,
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: splits.length > 12 ? 5 : 1,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        '${value.toInt() + 1}',
                        style: context.text.labelSm.copyWith(
                          color: c.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 0.3 + (worst - average) / span * 0.7,
                    color: c.textSecondary,
                    strokeWidth: 1,
                    dashArray: const [6, 4],
                  ),
                ],
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => c.inkPill,
                  getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                    '${context.l10n.runSplitKm(group.x + 1)}\n'
                    '${Fmt.paceWithUnit(splits[group.x].pace, miles: miles)}',
                    context.text.bodySm.copyWith(color: c.onInkPill),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < splits.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: 0.3 + (worst - paces[i]) / span * 0.7,
                        width: splits.length > 20 ? 6 : 14,
                        color: paces[i] == fastest
                            ? c.success
                            : paces[i] < average
                            ? c.primary
                            : c.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _Legend(color: c.success, label: context.l10n.splitsFastestKm),
            const SizedBox(width: AppSpacing.base),
            _Legend(color: c.primary, label: context.l10n.splitsUnderAverage),
            const SizedBox(width: AppSpacing.base),
            _Legend(
              color: c.primaryLight,
              label: context.l10n.splitsOverAverage,
            ),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.sm / 2),
        ),
      ),
      const SizedBox(width: AppSpacing.xs + 2),
      Text(
        label,
        style: context.text.labelSm.copyWith(
          color: context.colors.textSecondary,
          fontSize: 10,
        ),
      ),
    ],
  );
}
