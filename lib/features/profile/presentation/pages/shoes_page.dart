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
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// El armario: anadir y retirar zapatillas. Los kilometros los pone el
/// servidor con cada salida, aqui no se tocan.
class ShoesPage extends ConsumerWidget {
  const ShoesPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final nueva =
        await showModalBottomSheet<
          ({String brand, String model, double retireAtKm})
        >(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _AddShoesSheet(),
        );
    if (nueva == null || !context.mounted) return;

    final t = context.l10n;
    final error = await ref
        .read(profileProvider.notifier)
        .addShoe(
          brand: nueva.brand,
          model: nueva.model,
          retireAtKm: nueva.retireAtKm,
        );
    if (context.mounted) {
      context.showSnack(error == null ? t.shoesAdded : error.localized(t));
    }
  }

  Future<void> _retire(
    BuildContext context,
    WidgetRef ref,
    ShoeInfo shoe,
  ) async {
    final t = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.shoesRetireTitle),
        content: Text(t.shoesRetireBody),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(t.commonCancel),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              t.shoesRetire,
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    final error = await ref.read(profileProvider.notifier).removeShoe(shoe.id);
    if (context.mounted) {
      context.showSnack(error == null ? t.shoesRetired : error.localized(t));
    }
  }

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
        title: Text(t.profileShoes),
      ),
      body: profile.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.screenH),
          child: Column(
            children: [
              Skeleton(width: double.infinity, height: 92),
              SizedBox(height: AppSpacing.md),
              Skeleton(width: double.infinity, height: 92),
            ],
          ),
        ),
        error: (error, _) => ErrorStateView(
          message: error.localized(t),
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            if (data.shoes.isEmpty)
              EmptyState(
                icon: Icons.directions_walk_rounded,
                title: t.shoesEmpty,
                message: t.shoesEmptyBody,
              )
            else
              for (final shoe in data.shoes)
                _ShoeCard(
                  shoe: shoe,
                  miles: ref.watch(useMilesProvider),
                  onRetire: () => _retire(context, ref, shoe),
                ),
            const SizedBox(height: AppSpacing.base),
            AppButton(
              label: t.shoesAdd,
              icon: Icons.add_rounded,
              onPressed: () => _add(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoeCard extends StatelessWidget {
  const _ShoeCard({
    required this.shoe,
    required this.miles,
    required this.onRetire,
  });

  final ShoeInfo shoe;
  final bool miles;
  final VoidCallback onRetire;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final tone = shoe.needsReplacing ? c.warning : c.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_walk_rounded, size: 20, color: tone),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(shoe.model, style: context.text.titleMd)),
              if (shoe.isPrimary) AppBadge(label: t.shoesPrimary),
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                semanticsLabel: t.shoesRetire,
                onPressed: onRetire,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.shoesWear(
              Fmt.distance(shoe.distanceKm, miles: miles, decimals: 0),
              Fmt.distance(shoe.retireAtKm, miles: miles, decimals: 0),
            ),
            style: context.text.bodySm.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: shoe.wear,
              minHeight: 4,
              backgroundColor: c.ringTrack,
              valueColor: AlwaysStoppedAnimation(tone),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marca, modelo y el umbral de cambio. Los kilometros no se piden: unas
/// zapatillas nuevas empiezan a cero y el servidor las va sumando.
class _AddShoesSheet extends StatefulWidget {
  const _AddShoesSheet();

  @override
  State<_AddShoesSheet> createState() => _AddShoesSheetState();
}

class _AddShoesSheetState extends State<_AddShoesSheet> {
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _retireAt = TextEditingController(text: '700');
  final _errors = <String, String?>{};

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _retireAt.dispose();
    super.dispose();
  }

  void _submit() {
    final t = context.l10n;
    setState(() {
      _errors
        ..['brand'] = Validators.required(
          _brand.text,
          t.validationShoeBrandRequired,
        )
        ..['model'] = Validators.required(
          _model.text,
          t.validationShoeModelRequired,
        )
        ..['retireAt'] = Validators.positiveNumber(
          _retireAt.text,
          notANumber: t.validationDistanceNotANumber,
          notPositive: t.validationDistanceNotPositive,
        );
    });
    if (_errors.values.any((e) => e != null)) return;

    context.pop((
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      retireAtKm: double.parse(_retireAt.text.replaceAll(',', '.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenH,
        right: AppSpacing.screenH,
        top: AppSpacing.xl,
        // Sobre el teclado: sin esto los campos quedan debajo de el.
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.shoesAdd, style: context.text.headingMd),
          const SizedBox(height: AppSpacing.base),
          AppTextField(
            label: t.shoesBrand,
            hint: t.shoesBrandHint,
            controller: _brand,
            errorText: _errors['brand'],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: t.shoesModel,
            hint: t.shoesModelHint,
            controller: _model,
            errorText: _errors['model'],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: t.shoesRetireAt,
            controller: _retireAt,
            errorText: _errors['retireAt'],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: t.commonSave, onPressed: _submit),
        ],
      ),
    );
  }
}
