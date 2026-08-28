import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/core/utils/validators.dart';
import 'package:camrun/features/profile/domain/entities/user_profile.dart';
import 'package:camrun/features/profile/presentation/providers/profile_provider.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/app_text_field.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
  bool _uploadingPhoto = false;
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
    // Un perfil recien creado no tiene peso ni altura: el campo sale vacio,
    // no con un 0 que el usuario tendria que borrar para poder guardar.
    _weight.text = p.weightKg > 0 ? p.weightKg.toStringAsFixed(1) : '';
    _height.text = p.heightCm > 0 ? p.heightCm.toStringAsFixed(0) : '';
    _birthDate = p.birthDate;
    _gender = p.gender;
  }

  /// Vacio es 0: el mapper omite del PATCH lo que no llega a positivo.
  double _numero(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

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
        // Peso y altura son opcionales: se validan solo si hay algo escrito.
        ..['weight'] = _weight.text.trim().isEmpty
            ? null
            : Validators.positiveNumber(
                _weight.text,
                notANumber: t.validationWeightNotANumber,
                notPositive: t.validationWeightNotPositive,
              )
        ..['height'] = _height.text.trim().isEmpty
            ? null
            : Validators.positiveNumber(
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
            weightKg: _numero(_weight.text),
            heightCm: _numero(_height.text),
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

  /// Elige la foto y la sube. La camara y la galeria se ofrecen antes de que
  /// el sistema pida el permiso, para que el usuario sepa a que dice que si.
  Future<void> _changePhoto() async {
    final t = context.l10n;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.editPhotoFromGallery),
              onTap: () => context.pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(t.editPhotoTakePhoto),
              onTap: () => context.pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    // Cuadrada y reducida antes de salir del telefono: el servidor la
    // reescala igual, y subir 12 MP por datos moviles es lo que hace que el
    // usuario abandone.
    final photo = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    final error = await ref
        .read(profileProvider.notifier)
        .uploadAvatar(photo.path);
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);
    context.showSnack(error == null ? t.editPhotoUpdated : error.localized(t));
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
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AppAvatar(
                            initials: data.initials,
                            imageUrl: data.avatarUrl,
                            size: 92,
                          ),
                          if (_uploadingPhoto)
                            const SizedBox(
                              width: 92,
                              height: 92,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                        ],
                      ),
                      TextButton(
                        onPressed: _uploadingPhoto ? null : _changePhoto,
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
