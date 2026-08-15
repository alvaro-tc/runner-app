import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/app/router/app_routes.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/formatters/formatters.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';
import 'package:paceup/features/home/presentation/providers/marathon_providers.dart';
import 'package:paceup/features/profile/domain/entities/user_profile.dart';
import 'package:paceup/features/profile/presentation/providers/profile_provider.dart';
import 'package:paceup/features/races/presentation/providers/races_provider.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';
import 'package:paceup/shared/widgets/atoms/app_icon_button.dart';
import 'package:paceup/shared/widgets/atoms/app_indicators.dart';
import 'package:paceup/shared/widgets/atoms/app_text_field.dart';
import 'package:paceup/shared/widgets/atoms/skeleton.dart';
import 'package:paceup/shared/widgets/molecules/states.dart';
import 'package:paceup/shared/widgets/molecules/tiles.dart';

/// Three-step entry flow: details, category and extras, then review and pay.
/// Payment is a mock selection — no card data is ever collected.
class MarathonRegisterPage extends ConsumerStatefulWidget {
  const MarathonRegisterPage({required this.marathonId, super.key});

  final String marathonId;

  @override
  ConsumerState<MarathonRegisterPage> createState() =>
      _MarathonRegisterPageState();
}

class _MarathonRegisterPageState extends ConsumerState<MarathonRegisterPage> {
  static const _serviceFee = Money(4.5);
  static const _shirtSizes = ['XS', 'S', 'M', 'L', 'XL'];
  static const _paymentMethods = ['Card •••• 4242', 'Wallet'];

  final _page = PageController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();

  int _step = 0;
  String _shirtSize = 'M';
  String? _categoryId;
  final _selectedExtras = <String>{};
  String _paymentMethod = _paymentMethods.first;
  bool _acceptedTerms = false;
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _page.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  Money _total(Marathon marathon) {
    var amount = marathon.entryFee.amount + _serviceFee.amount;
    final category = marathon.categories
        .where((c) => c.id == _categoryId)
        .firstOrNull;
    if (category != null) amount += category.surcharge.amount;
    for (final extra in marathon.extras) {
      if (_selectedExtras.contains(extra.id)) amount += extra.price.amount;
    }
    return Money(amount, marathon.entryFee.currency);
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _page.animateToPage(
      step,
      duration: AppDurations.base,
      curve: AppDurations.curve,
    );
  }

  Future<void> _submit(Marathon marathon) async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    final (entry, failure) = await ref
        .read(racesProvider.notifier)
        .register(
          marathon: marathon,
          amountPaid: _total(marathon),
          paymentMethod: _paymentMethod,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (failure != null || entry == null) {
      setState(() => _submitError = failure?.message);
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(
        bibNumber: entry.bibNumber,
        marathonName: marathon.name,
        onViewRace: () => context
          ..pop()
          ..go(Routes.raceDetailOf(entry.id)),
        onHome: () => context
          ..pop()
          ..go(Routes.home),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marathon = ref.watch(marathonProvider(widget.marathonId));
    final profile = ref.watch(profileProvider).value;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: AppIconButton(
            icon: Icons.arrow_back_rounded,
            semanticsLabel: 'Go back',
            onPressed: () => _step == 0 ? context.pop() : _goTo(_step - 1),
          ),
        ),
        title: const Text('Registration'),
      ),
      body: marathon.when(
        loading: () => const Center(child: Skeleton(width: 200, height: 20)),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(marathonProvider(widget.marathonId)),
        ),
        data: (data) => _body(data, profile),
      ),
    );
  }

  Widget _body(Marathon marathon, UserProfile? profile) {
    _categoryId ??= marathon.categories.firstOrNull?.id;
    return Column(
      children: [
        _Stepper(step: _step),
        Expanded(
          child: PageView(
            controller: _page,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _detailsStep(profile),
              _categoryStep(marathon),
              _reviewStep(marathon),
            ],
          ),
        ),
        _footer(marathon),
      ],
    );
  }

  // ------------------------------------------------------------- step one

  Widget _detailsStep(UserProfile? profile) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      children: [
        Text('Your details', style: context.text.headingMd),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Taken from your profile. Change them in Profile if anything is out '
          'of date.',
          style: context.text.bodySm.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReadOnlyField(label: 'Full name', value: profile?.fullName ?? '—'),
        _ReadOnlyField(
          label: 'Date of birth',
          value: profile == null ? '—' : Fmt.fullDate(profile.birthDate),
        ),
        _ReadOnlyField(label: 'Gender', value: profile?.gender.label ?? '—'),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Emergency contact name',
          controller: _emergencyName,
          hint: 'Who should we call?',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Emergency contact phone',
          controller: _emergencyPhone,
          hint: '+62 812 0000 0000',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Shirt size', style: context.text.labelSm),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final size in _shirtSizes)
              AppChip(
                label: size,
                selected: _shirtSize == size,
                onTap: () => setState(() => _shirtSize = size),
              ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------- step two

  Widget _categoryStep(Marathon marathon) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      children: [
        Text('Category & extras', style: context.text.headingMd),
        const SizedBox(height: AppSpacing.lg),
        if (marathon.categories.isEmpty)
          Text(
            'This event runs a single distance: '
            '${Fmt.distance(marathon.distanceKm)}.',
            style: context.text.bodyMd.copyWith(color: c.textSecondary),
          )
        else
          for (final category in marathon.categories)
            _SelectableTile(
              title: category.label,
              subtitle: Fmt.distance(category.distanceKm),
              trailing: category.surcharge.amount == 0
                  ? 'Included'
                  : Fmt.money(
                      category.surcharge.amount,
                      category.surcharge.currency,
                    ),
              selected: _categoryId == category.id,
              onTap: () => setState(() => _categoryId = category.id),
            ),
        const SizedBox(height: AppSpacing.lg),
        Text('Optional extras', style: context.text.titleMd),
        const SizedBox(height: AppSpacing.sm),
        if (marathon.extras.isEmpty)
          Text(
            'No add-ons for this event.',
            style: context.text.bodyMd.copyWith(color: c.textSecondary),
          )
        else
          for (final extra in marathon.extras)
            _SelectableTile(
              title: extra.label,
              subtitle: extra.description,
              trailing: Fmt.money(extra.price.amount, extra.price.currency),
              selected: _selectedExtras.contains(extra.id),
              isCheckbox: true,
              onTap: () => setState(() {
                _selectedExtras.contains(extra.id)
                    ? _selectedExtras.remove(extra.id)
                    : _selectedExtras.add(extra.id);
              }),
            ),
      ],
    );
  }

  // ----------------------------------------------------------- step three

  Widget _reviewStep(Marathon marathon) {
    final c = context.colors;
    final category = marathon.categories
        .where((c) => c.id == _categoryId)
        .firstOrNull;
    final total = _total(marathon);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      children: [
        Text('Review & pay', style: context.text.headingMd),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              SessionSummaryRow(
                label:
                    'Entry fee${category == null ? '' : ' · ${category.label}'}',
                value: Fmt.money(
                  marathon.entryFee.amount + (category?.surcharge.amount ?? 0),
                  total.currency,
                ),
              ),
              for (final extra in marathon.extras)
                if (_selectedExtras.contains(extra.id))
                  SessionSummaryRow(
                    label: extra.label,
                    value: Fmt.money(extra.price.amount, total.currency),
                  ),
              SessionSummaryRow(
                label: 'Service fee',
                value: Fmt.money(_serviceFee.amount, total.currency),
              ),
              const AppDivider(),
              SessionSummaryRow(
                label: 'Total',
                value: Fmt.money(total.amount, total.currency),
                emphasise: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Payment method', style: context.text.titleMd),
        const SizedBox(height: AppSpacing.sm),
        for (final method in _paymentMethods)
          _SelectableTile(
            title: method,
            subtitle: method.startsWith('Card')
                ? 'Charged when your place is confirmed'
                : 'Uses your PaceUp balance',
            selected: _paymentMethod == method,
            onTap: () => setState(() => _paymentMethod = method),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            AppCheckbox(
              value: _acceptedTerms,
              semanticsLabel: 'Accept event terms',
              onChanged: (v) => setState(() => _acceptedTerms = v),
            ),
            Expanded(
              child: Text(
                'I accept the event rules and the refund policy.',
                style: context.text.bodySm.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        ),
        if (_submitError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _submitError!,
            style: context.text.bodySm.copyWith(color: c.error),
          ),
        ],
      ],
    );
  }

  Widget _footer(Marathon marathon) {
    final c = context.colors;
    final isLast = _step == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: context.text.labelSm.copyWith(color: c.textSecondary),
                ),
                Text(
                  Fmt.money(_total(marathon).amount, _total(marathon).currency),
                  style: context.text.headingMd,
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: AppButton(
                label: isLast ? 'Pay and register' : 'Continue',
                isLoading: _submitting,
                onPressed: isLast
                    ? (_acceptedTerms ? () => _submit(marathon) : null)
                    : () => _goTo(_step + 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step});

  final int step;

  static const _labels = ['Details', 'Category', 'Pay'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.base,
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: AppDurations.base,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= step ? c.primary : c.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    _labels[i],
                    style: context.text.labelSm.copyWith(
                      color: i <= step ? c.primary : c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.labelSm),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md + 2,
            ),
            decoration: BoxDecoration(
              color: c.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(value, style: context.text.bodyMd),
          ),
        ],
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.isCheckbox = false,
  });

  final String title;
  final String? subtitle;
  final String? trailing;
  final bool selected;
  final bool isCheckbox;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected ? c.primaryContainer : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: selected ? c.primary : c.border),
            ),
            child: Row(
              children: [
                Icon(
                  isCheckbox
                      ? (selected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded)
                      : (selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded),
                  size: 20,
                  color: selected ? c.primary : c.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.titleMd),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: context.text.bodySm.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: context.text.titleMd.copyWith(color: c.primary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({
    required this.bibNumber,
    required this.marathonName,
    required this.onViewRace,
    required this.onHome,
  });

  final String bibNumber;
  final String marathonName;
  final VoidCallback onViewRace;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AppDurations.slow,
              curve: Curves.elasticOut,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.successBg,
                ),
                child: Icon(Icons.check_rounded, size: 38, color: c.success),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "You're in",
              style: context.text.headingLg,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your place at $marathonName is confirmed.',
              textAlign: TextAlign.center,
              style: context.text.bodyMd.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.base),
            AppBadge(
              label: 'BIB $bibNumber',
              icon: Icons.confirmation_num_outlined,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: 'View my race', onPressed: onViewRace),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Back to home',
              variant: AppButtonVariant.ghost,
              onPressed: onHome,
            ),
          ],
        ),
      ),
    );
  }
}
