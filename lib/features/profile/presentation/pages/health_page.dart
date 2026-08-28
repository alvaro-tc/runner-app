import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/profile/domain/entities/user_profile.dart';
import 'package:camrun/features/profile/presentation/providers/profile_provider.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:camrun/shared/widgets/atoms/app_text_field.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lesiones, sueno e hidratacion: lo que guarda `PATCH /users/me/health`.
class HealthPage extends ConsumerWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: AppIconButton(
            icon: Icons.arrow_back_rounded,
            semanticsLabel: t.commonBack,
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(t.profileHealth),
      ),
      body: profile.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.screenH),
          child: Column(
            children: [
              Skeleton(width: double.infinity, height: 56),
              SizedBox(height: AppSpacing.md),
              Skeleton(width: double.infinity, height: 120),
            ],
          ),
        ),
        error: (error, _) => ErrorStateView(
          message: error.localized(t),
          onRetry: () => ref.invalidate(profileProvider),
        ),
        // La clave ata el formulario al perfil cargado: si llega otro, los
        // campos se rehacen con sus valores en vez de quedarse con los viejos.
        data: (data) => _Form(key: ValueKey(data.id), profile: data),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final List<TextEditingController> _zones = [
    for (final i in widget.profile.injuries)
      TextEditingController(text: i.zone),
  ];
  late Duration _sleep = widget.profile.sleep.averageLast7Days;
  late HydrationHabit _hydration = widget.profile.hydration;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _zones) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.l10n;
    setState(() => _saving = true);
    final error = await ref
        .read(profileProvider.notifier)
        .saveHealth(
          // `notes` y `since` de las que ya existian se conservan por posicion:
          // el formulario solo edita la zona, y el PATCH reescribe la lista.
          injuries: [
            for (final (index, c) in _zones.indexed)
              if (c.text.trim().isNotEmpty)
                Injury(
                  zone: c.text.trim(),
                  notes: widget.profile.injuries.elementAtOrNull(index)?.notes,
                  since: widget.profile.injuries.elementAtOrNull(index)?.since,
                ),
          ],
          sleep: _sleep,
          hydration: _hydration,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      context.showSnack(error.localized(t));
      return;
    }
    context
      ..pop()
      ..showSnack(t.healthSaved);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      children: [
        Text(t.profileInjuryFlags, style: context.text.headingMd),
        const SizedBox(height: AppSpacing.md),
        if (_zones.isEmpty)
          Text(
            t.healthNoInjuries,
            style: context.text.bodyMd.copyWith(color: c.textSecondary),
          ),
        for (final (index, controller) in _zones.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppTextField(
                    label: t.healthInjuryZone,
                    hint: t.healthInjuryZoneHint,
                    controller: controller,
                  ),
                ),
                AppIconButton(
                  icon: Icons.close_rounded,
                  semanticsLabel: t.commonDelete,
                  onPressed: () => setState(() {
                    _zones.removeAt(index).dispose();
                  }),
                ),
              ],
            ),
          ),
        AppButton(
          label: t.healthAddInjury,
          icon: Icons.add_rounded,
          variant: AppButtonVariant.outline,
          size: AppButtonSize.md,
          onPressed: () =>
              setState(() => _zones.add(TextEditingController())),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(t.healthSleepLabel, style: context.text.headingMd),
        Text(
          Fmt.durationShort(_sleep),
          style: context.text.displayLg.copyWith(fontSize: 30),
        ),
        Slider(
          value: _sleep.inMinutes.toDouble(),
          max: 720,
          // Cuartos de hora: el sueno medio no se afina al minuto.
          divisions: 48,
          label: Fmt.durationShort(_sleep),
          onChanged: (v) =>
              setState(() => _sleep = Duration(minutes: v.round())),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(t.profileHydration, style: context.text.headingMd),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<HydrationHabit>(
          segments: [
            for (final habit in HydrationHabit.values)
              ButtonSegment(value: habit, label: Text(habit.label(t))),
          ],
          selected: {_hydration},
          onSelectionChanged: (s) => setState(() => _hydration = s.first),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: t.commonSave,
          isLoading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
