import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/auth/presentation/providers/auth_provider.dart';
import 'package:camrun/features/profile/domain/entities/user_profile.dart';
import 'package:camrun/features/profile/presentation/providers/profile_provider.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:camrun/shared/widgets/molecules/tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      body: profile.when(
        loading: () => const Center(child: Skeleton(width: 180, height: 20)),
        error: (error, _) => SafeArea(
          child: ErrorStateView(
            message: error.localized(context.l10n),
            onRetry: () => ref.invalidate(profileProvider),
          ),
        ),
        data: (data) => _Body(profile: data),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.profile});

  final UserProfile profile;

  static const _bannerHeight = 200.0;
  static const _avatarSize = AppSizes.avatarProfile;

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.profileLogOutTitle),
        content: Text(t.profileLogOutBody),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(t.profileStaySignedIn),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              t.profileLogOut,
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    await ref.read(authProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.l10n;
    final unit = ref.watch(distanceUnitProvider);
    final miles = unit.isMiles;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: _bannerHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // A scrim over a pale container just reads as grey, so the
                    // banner carries the brand gradient instead.
                    DecoratedBox(
                      decoration: BoxDecoration(gradient: c.routeGradient),
                    ),
                    Center(
                      child: Icon(
                        Icons.terrain_rounded,
                        size: 64,
                        color: c.onPrimary.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: _bannerHeight - AppSpacing.xxl,
                left: 0,
                right: 0,
                child: Container(
                  height: AppSpacing.xxl + AppSpacing.base,
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.sheet),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: _bannerHeight - _avatarSize / 2,
                left: 0,
                right: 0,
                child: Center(
                  child: AppAvatar(
                    initials: profile.initials,
                    imageUrl: profile.avatarUrl,
                    size: _avatarSize,
                    ringWidth: 4,
                    ringColor: c.background,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _avatarSize / 2 + AppSpacing.sm),
          AppBadge(label: t.commonBib(profile.bibNumber)),
          const SizedBox(height: AppSpacing.sm),
          Text(profile.fullName, style: context.text.headingLg),
          Text(
            profile.location,
            style: context.text.bodyMd.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.base),
          AppButton(
            label: t.profileEditProfile,
            size: AppButtonSize.md,
            isFullWidth: false,
            onPressed: () => context.push(Routes.profileEdit),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HighlightCard(profile: profile, miles: miles),
                const SizedBox(height: AppSpacing.xl),
                Text(t.profileYourWeek, style: context.text.headingMd),
                _Card(
                  children: [
                    StatRow(
                      icon: Icons.healing_outlined,
                      title: t.profileInjuryFlags,
                      value: profile.injuryFlags.isEmpty
                          ? t.profileInjuryNone
                          : profile.injuryFlags,
                      tone: c.success,
                      onTap: () => context.push(Routes.profileHealth),
                    ),
                    const AppDivider(),
                    StatRow(
                      icon: Icons.bedtime_outlined,
                      title: t.profileSleep,
                      subtitle: t.profileSleepSubtitle,
                      value: Fmt.durationShort(profile.sleep.averageLast7Days),
                      onTap: () => context.push(Routes.profileHealth),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(t.commonSettings, style: context.text.headingMd),
                _Card(
                  children: [
                    StatRow(
                      icon: Icons.palette_outlined,
                      title: t.profileAppearance,
                      value: switch (ref.watch(themeModeProvider)) {
                        ThemeMode.light => t.themeLight,
                        ThemeMode.dark => t.themeDark,
                        ThemeMode.system => t.themeSystem,
                      },
                      onTap: () => context.push(Routes.profileAppearance),
                    ),
                    const AppDivider(),
                    StatRow(
                      icon: Icons.translate_rounded,
                      title: t.languageTitle,
                      value: ref.watch(languageProvider).label(t),
                      onTap: () => context.push(Routes.profileLanguage),
                    ),
                    const AppDivider(),
                    StatRow(
                      icon: Icons.straighten_rounded,
                      title: t.profileUnits,
                      value: unit.label,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setUnit(miles ? DistanceUnit.km : DistanceUnit.mi),
                    ),
                    const AppDivider(),
                    StatRow(
                      icon: Icons.settings_outlined,
                      title: t.profileNotificationsPrivacyHelp,
                      onTap: () => context.push(Routes.profileSettings),
                    ),
                    const AppDivider(),
                    StatRow(
                      icon: Icons.logout_rounded,
                      title: t.profileLogOut,
                      tone: c.error,
                      onTap: () => _logOut(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.profile, required this.miles});

  final UserProfile profile;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: () => context.showSnack(context.l10n.profileStatsComingSoon),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.profileRunningHighlight,
                      style: context.text.titleMd.copyWith(color: c.primary),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: c.primary),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _Highlight(
                        icon: Icons.calendar_month_rounded,
                        value: Fmt.distance(
                          profile.highlights.weeklyMileageKm,
                          miles: miles,
                        ),
                        label: context.l10n.profileWeeklyMileage,
                      ),
                    ),
                    VerticalDivider(color: c.primary.withValues(alpha: 0.25)),
                    Expanded(
                      child: _Highlight(
                        icon: Icons.landscape_outlined,
                        value: Fmt.distance(
                          profile.highlights.longestRunKm,
                          miles: miles,
                        ),
                        label: context.l10n.profileLongestRun,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.surface),
          child: Icon(icon, size: 18, color: c.primary),
        ),
        const SizedBox(height: AppSpacing.md),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: context.text.displayLg.copyWith(fontSize: 30),
          ),
        ),
        Text(
          label,
          style: context.text.labelSm.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Column(children: children),
    );
  }
}
