import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/app/router/app_routes.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/formatters/formatters.dart';
import 'package:paceup/core/services/settings_provider.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/features/train/domain/entities/training_run.dart';
import 'package:paceup/features/train/presentation/providers/history_provider.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';
import 'package:paceup/shared/widgets/atoms/app_icon_button.dart';
import 'package:paceup/shared/widgets/atoms/app_text_field.dart';
import 'package:paceup/shared/widgets/atoms/skeleton.dart';
import 'package:paceup/shared/widgets/molecules/states.dart';
import 'package:paceup/shared/widgets/molecules/tiles.dart';
import 'package:paceup/shared/widgets/organisms/route_map_view.dart';
import 'package:paceup/shared/widgets/organisms/splits_chart.dart';

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
    setState(() => _saving = true);
    final error = await ref
        .read(historyProvider.notifier)
        .save(run.copyWith(feeling: _feeling, notes: _notes.text.trim()));
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      context.showSnack(error);
      return;
    }
    context
      ..go(Routes.train)
      ..showSnack('Run saved');
  }

  Future<void> _delete(TrainingRun run) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.readOnly ? 'Delete this run?' : 'Discard this run?'),
        content: Text(
          widget.readOnly
              ? 'The route, the splits and the time all go with it. '
                    'This cannot be undone.'
              : 'Nothing about this run will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              widget.readOnly ? 'Delete' : 'Discard',
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
      context.showSnack(error);
      return;
    }
    context.go(Routes.train);
  }

  @override
  Widget build(BuildContext context) {
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
            semanticsLabel: 'Go back',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(Routes.train),
          ),
        ),
        title: Text(widget.readOnly ? 'Run detail' : 'Run summary'),
      ),
      body: history.isLoading && run == null
          ? const Center(child: Skeleton(width: 180, height: 20))
          : run == null
          ? ErrorStateView(
              message: 'That run is not in your history any more.',
              onRetry: () => context.go(Routes.train),
            )
          : _body(run),
    );
  }

  Widget _body(TrainingRun run) {
    final c = context.colors;
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
        Text(run.title, style: context.text.headingLg),
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
              label: 'Distance',
              compact: true,
            ),
            MetricTile(
              icon: Icons.schedule_rounded,
              value: Fmt.clock(run.elapsed),
              label: 'Time',
              compact: true,
            ),
            MetricTile(
              icon: Icons.speed_rounded,
              value: Fmt.paceWithUnit(run.avgPacePerKm, miles: miles),
              label: 'Average pace',
              compact: true,
            ),
            MetricTile(
              icon: Icons.rocket_launch_outlined,
              value: Fmt.speed(run.avgSpeedKmh, miles: miles),
              label: 'Average speed',
              compact: true,
            ),
            MetricTile(
              icon: Icons.terrain_rounded,
              value: Fmt.elevation(run.elevationGainM),
              label: 'Elevation gain',
              compact: true,
            ),
            MetricTile(
              icon: Icons.local_fire_department_outlined,
              value: '${run.calories ?? 0}',
              label: 'Calories',
              compact: true,
              tone: c.warning,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Splits', style: context.text.headingMd),
        const SizedBox(height: AppSpacing.md),
        SplitsChart(splits: run.splits, miles: miles),
        if (!widget.readOnly) ...[
          const SizedBox(height: AppSpacing.xl),
          Text('How did it feel?', style: context.text.headingMd),
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
            label: 'Notes',
            controller: _notes,
            hint: 'Legs, weather, anything worth remembering',
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Save run',
            isLoading: _saving,
            onPressed: () => _save(run),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Discard',
            variant: AppButtonVariant.ghost,
            onPressed: () => _delete(run),
          ),
        ] else ...[
          if (run.feeling != null || (run.notes?.isNotEmpty ?? false)) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Your notes', style: context.text.headingMd),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${run.feeling == null ? '' : '${run.feeling!.emoji} ${run.feeling!.label}. '}'
              '${run.notes ?? ''}',
              style: context.text.bodyMd.copyWith(color: c.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Delete this run',
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
    return Semantics(
      button: true,
      selected: selected,
      label: feeling.label,
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
                  feeling.label,
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
