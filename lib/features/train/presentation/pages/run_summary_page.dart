import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:camrun/features/train/presentation/providers/history_provider.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:camrun/shared/widgets/atoms/app_text_field.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:camrun/shared/widgets/molecules/tiles.dart';
import 'package:camrun/shared/widgets/organisms/route_map_view.dart';
import 'package:camrun/shared/widgets/organisms/splits_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Post-run summary. The same layout serves the read-only history detail —
/// [readOnly] just hides the feeling picker, the notes field and Save/Discard.
class RunSummaryPage extends ConsumerStatefulWidget {
  const RunSummaryPage({required this.runId, this.readOnly = false, super.key});

  final String runId;
  final bool readOnly;

  @override
  ConsumerState<RunSummaryPage> createState() => _RunSummaryPageState();
}

class _RunSummaryPageState extends ConsumerState<RunSummaryPage> {
  final _notes = TextEditingController();
  RunFeeling? _feeling;
  bool _saving = false;
  bool _initialised = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save(TrainingRun run) async {
    final t = context.l10n;
    setState(() => _saving = true);
    final error = await ref
        .read(historyProvider.notifier)
        .save(run.copyWith(feeling: _feeling, notes: _notes.text.trim()));
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      context.showSnack(error.localized(t));
      return;
    }
    context
      ..go(Routes.train)
      ..showSnack(t.summarySaved);
  }

  Future<void> _delete(TrainingRun run) async {
    final t = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.readOnly ? t.summaryDeleteTitle : t.runDiscardTitle),
        content: Text(
          widget.readOnly ? t.summaryDeleteBody : t.summaryDiscardBody,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(t.summaryKeepIt),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              widget.readOnly ? t.commonDelete : t.commonDiscard,
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;

    final error = await ref.read(historyProvider.notifier).delete(run.id);
    if (!mounted) return;
    if (error != null) {
      context.showSnack(error.localized(t));
      return;
    }
    context.go(Routes.train);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final history = ref.watch(historyProvider);
    final run = ref.watch(runProvider(widget.runId));

    if (!_initialised && run != null) {
      _initialised = true;
      _feeling = run.feeling;
      _notes.text = run.notes ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: AppIconButton(
            icon: Icons.arrow_back_rounded,
            semanticsLabel: t.commonBack,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(Routes.train),
          ),
        ),
        title: Text(widget.readOnly ? t.summaryDetailTitle : t.summaryTitle),
      ),
      body: history.isLoading && run == null
          ? const Center(child: Skeleton(width: 180, height: 20))
          : run == null
          ? ErrorStateView(
              message: t.summaryNotInHistory,
              onRetry: () => context.go(Routes.train),
            )
          : _body(run),
    );
  }

  Widget _body(TrainingRun run) {
    final c = context.colors;
    final t = context.l10n;
    final miles = ref.watch(useMilesProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.xxl,
      ),
      children: [
        Text(run.localizedTitle(t), style: context.text.headingLg),
        Text(
          '${Fmt.weekdayDayMonth(run.startedAt)} · '
          '${Fmt.timeOfDay(run.startedAt)}',
          style: context.text.bodySm.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: SizedBox(
            height: 220,
            child: RouteMapView(route: run.route, interactive: false),
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
              icon: Icons.straighten_rounded,
              value: Fmt.distance(run.distanceKm, miles: miles),
              label: t.commonDistance,
              compact: true,
            ),
            MetricTile(
              icon: Icons.schedule_rounded,
              value: Fmt.clock(run.elapsed),
              label: t.commonTime,
              compact: true,
            ),
            MetricTile(
              icon: Icons.speed_rounded,
              value: Fmt.paceWithUnit(run.avgPacePerKm, miles: miles),
              label: t.commonAveragePace,
              compact: true,
            ),
            MetricTile(
              icon: Icons.rocket_launch_outlined,
              value: Fmt.speed(run.avgSpeedKmh, miles: miles),
              label: t.commonAverageSpeed,
              compact: true,
            ),
            MetricTile(
              icon: Icons.terrain_rounded,
              value: Fmt.elevation(run.elevationGainM),
              label: t.commonElevationGain,
              compact: true,
            ),
            MetricTile(
              icon: Icons.local_fire_department_outlined,
              value: '${run.calories ?? 0}',
              label: t.commonCalories,
              compact: true,
              tone: c.warning,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(t.commonSplits, style: context.text.headingMd),
        const SizedBox(height: AppSpacing.md),
        SplitsChart(splits: run.splits, miles: miles),
        if (!widget.readOnly) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(t.summaryHowDidItFeel, style: context.text.headingMd),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final feeling in RunFeeling.values) ...[
                Expanded(
                  child: _FeelingButton(
                    feeling: feeling,
                    selected: _feeling == feeling,
                    onTap: () => setState(() => _feeling = feeling),
                  ),
                ),
                if (feeling != RunFeeling.values.last)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: t.summaryNotesLabel,
            controller: _notes,
            hint: t.summaryNotesHint,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: t.summarySaveRun,
            isLoading: _saving,
            onPressed: () => _save(run),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: t.commonDiscard,
            variant: AppButtonVariant.ghost,
            onPressed: () => _delete(run),
          ),
        ] else ...[
          if (run.feeling != null || (run.notes?.isNotEmpty ?? false)) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(t.summaryYourNotes, style: context.text.headingMd),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${run.feeling == null ? '' : '${run.feeling!.emoji} ${run.feeling!.label(t)}. '}'
              '${run.notes ?? ''}',
              style: context.text.bodyMd.copyWith(color: c.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: t.summaryDeleteRun,
            variant: AppButtonVariant.danger,
            onPressed: () => _delete(run),
          ),
        ],
      ],
    );
  }
}

class _FeelingButton extends StatelessWidget {
  const _FeelingButton({
    required this.feeling,
    required this.selected,
    required this.onTap,
  });

  final RunFeeling feeling;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    return Semantics(
      button: true,
      selected: selected,
      label: feeling.label(t),
      child: Material(
        color: selected ? c.primaryContainer : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: selected ? c.primary : c.border),
            ),
            child: Column(
              children: [
                Text(feeling.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  feeling.label(t),
                  style: context.text.labelSm.copyWith(
                    color: selected ? c.primary : c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
