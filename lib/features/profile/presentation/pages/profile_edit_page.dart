import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/formatters/formatters.dart';
import 'package:paceup/core/services/settings_provider.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/core/utils/validators.dart';
import 'package:paceup/features/profile/domain/entities/user_profile.dart';
import 'package:paceup/features/profile/presentation/providers/profile_provider.dart';
import 'package:paceup/l10n/l10n_labels.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';
import 'package:paceup/shared/widgets/atoms/app_icon_button.dart';
import 'package:paceup/shared/widgets/atoms/app_indicators.dart';
import 'package:paceup/shared/widgets/atoms/app_text_field.dart';
import 'package:paceup/shared/widgets/atoms/skeleton.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();

  final _errors = <String, String?>{};
  DateTime? _birthDate;
  Gender? _gender;
  bool _dirty = false;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _city.dispose();
    _country.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  void _hydrate(UserProfile p) {
    _loaded = true;
    _name.text = p.fullName;
    _email.text = p.email;
    _city.text = p.city;
    _country.text = p.country;
    _weight.text = p.weightKg.toStringAsFixed(1);
    _height.text = p.heightCm.toStringAsFixed(0);
    _birthDate = p.birthDate;
    _gender = p.gender;
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final t = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.editDiscardTitle),
        content: Text(t.editDiscardBody),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(t.editKeepEditing),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              t.commonDiscard,
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _save(UserProfile original) async {
    final t = context.l10n;
    setState(() {
      _errors
        ..['name'] = Validators.required(
          _name.text,
          t.validationFullNameRequired,
        )
        ..['email'] = Validators.email(t, _email.text)
        ..['city'] = Validators.required(_city.text, t.validationCityRequired)
        ..['weight'] = Validators.positiveNumber(
          _weight.text,
          notANumber: t.validationWeightNotANumber,
          notPositive: t.validationWeightNotPositive,
        )
        ..['height'] = Validators.positiveNumber(
          _height.text,
          notANumber: t.validationHeightNotANumber,
          notPositive: t.validationHeightNotPositive,
        );
    });
    if (_errors.values.any((e) => e != null)) return;

    setState(() => _saving = true);
    final error = await ref
        .read(profileProvider.notifier)
        .save(
          original.copyWith(
            fullName: _name.text.trim(),
            email: _email.text.trim(),
            city: _city.text.trim(),
            country: _country.text.trim(),
            birthDate: _birthDate,
            gender: _gender,
            weightKg: double.parse(_weight.text.replaceAll(',', '.')),
            heightCm: double.parse(_height.text.replaceAll(',', '.')),
          ),
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _dirty = error != null;
    });
    if (error != null) {
      context.showSnack(error.localized(t));
      return;
    }
    context
      ..pop()
      ..showSnack(t.editProfileUpdated);
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1995),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      helpText: context.l10n.registerDateOfBirth,
    );
    if (picked == null) return;
    setState(() {
      _birthDate = picked;
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final profile = ref.watch(profileProvider);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: AppIconButton(
              icon: Icons.arrow_back_rounded,
              semanticsLabel: t.commonBack,
              onPressed: () async {
                if (await _confirmLeave() && context.mounted) context.pop();
              },
            ),
          ),
          title: Text(t.editProfileTitle),
        ),
        body: profile.when(
          loading: () => const Center(child: Skeleton(width: 180, height: 20)),
          error: (error, _) => Center(child: Text(error.localized(t))),
          data: (data) {
            if (!_loaded) _hydrate(data);
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                Center(
                  child: Column(
                    children: [
                      AppAvatar(initials: data.initials, size: 92),
                      TextButton(
                        onPressed: () =>
                            context.showSnack(t.editPhotoComingSoon),
                        child: Text(t.editChangePhoto),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: t.registerFullName,
                  controller: _name,
                  errorText: _errors['name'],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _touch(),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: t.authEmailLabel,
                  controller: _email,
                  errorText: _errors['email'],
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _touch(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: t.editCity,
                        controller: _city,
                        errorText: _errors['city'],
                        onChanged: (_) => _touch(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        label: t.editCountry,
                        controller: _country,
                        onChanged: (_) => _touch(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(t.registerDateOfBirth, style: context.text.labelSm),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: _pickBirthDate,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    height: AppSizes.controlHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: c.border, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _birthDate == null
                                ? t.editPickADate
                                : Fmt.fullDate(_birthDate!),
                            style: context.text.bodyMd,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: c.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(t.registerGender, style: context.text.labelSm),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final gender in Gender.values)
                      AppChip(
                        label: gender.label(t),
                        selected: _gender == gender,
                        onTap: () => setState(() {
                          _gender = gender;
                          _dirty = true;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: t.editWeightKg,
                        controller: _weight,
                        errorText: _errors['weight'],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => _touch(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        label: t.editHeightCm,
                        controller: _height,
                        errorText: _errors['height'],
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _touch(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(t.profileUnits, style: context.text.labelSm),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final unit in DistanceUnit.values)
                      AppChip(
                        label: unit == DistanceUnit.km
                            ? t.settingsKilometres
                            : t.settingsMiles,
                        selected: ref.watch(distanceUnitProvider) == unit,
                        onTap: () =>
                            ref.read(settingsProvider.notifier).setUnit(unit),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: t.editSaveChanges,
                  isLoading: _saving,
                  onPressed: _dirty ? () => _save(data) : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
