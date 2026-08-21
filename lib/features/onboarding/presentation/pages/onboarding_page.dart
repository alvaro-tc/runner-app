import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/app/router/app_routes.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/services/settings_provider.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/features/onboarding/presentation/widgets/onboarding_illustration.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = <({String title, String body, OnboardingArt art})>[
    (
      title: 'Train with a plan that adapts',
      body:
          'Tell PaceUp the race you are chasing. It lays out the weeks, moves '
          'sessions when life gets in the way, and keeps the goal in sight.',
      art: OnboardingArt.plan,
    ),
    (
      title: 'Track every run in real time',
      body:
          'GPS draws your route as you go. Pace, splits and elapsed time stay '
          'on screen, so you always know whether to push or hold back.',
      art: OnboardingArt.track,
    ),
    (
      title: 'Race, and keep every medal',
      body:
          'Enter events from inside the app, then keep your bib, your finish '
          'time and your splits together in one place.',
      art: OnboardingArt.race,
    ),
  ];

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(settingsProvider.notifier).markOnboardingSeen();
    context.go(Routes.welcome);
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: AppDurations.base,
      curve: AppDurations.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: context.text.button.copyWith(color: c.textSecondary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Column(
                    children: [
                      Expanded(
                        flex: 6,
                        child: OnboardingIllustration(art: slide.art),
                      ),
                      Expanded(
                        flex: 4,
                        // Short screens and large text scales push the copy
                        // past the available height, so it scrolls rather than
                        // overflowing.
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenH,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Column(
                                children: [
                                  Text(
                                    slide.title,
                                    textAlign: TextAlign.center,
                                    style: context.text.headingMd,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    slide.body,
                                    textAlign: TextAlign.center,
                                    style: context.text.bodyMd.copyWith(
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: AppDurations.base,
                    curve: AppDurations.curve,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    height: 8,
                    width: i == _index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: i == _index ? c.primary : c.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.xl,
                AppSpacing.screenH,
                AppSpacing.xxl,
              ),
              child: AnimatedSize(
                duration: AppDurations.base,
                curve: AppDurations.curve,
                child: AppButton(
                  label: _isLast ? 'Get started' : 'Next',
                  onPressed: _next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
