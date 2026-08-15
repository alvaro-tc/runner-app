import 'package:flutter/material.dart';
import 'package:paceup/shared/widgets/atoms/blob_illustration.dart';

enum OnboardingArt {
  plan(Icons.calendar_month_rounded, 3),
  track(Icons.my_location_rounded, 11),
  race(Icons.emoji_events_rounded, 21);

  const OnboardingArt(this.icon, this.seed);
  final IconData icon;
  final int seed;
}

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({required this.art, super.key});

  final OnboardingArt art;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: BlobIllustration(
          icon: art.icon,
          seed: art.seed,
          size: constraints.biggest.shortestSide * 0.9,
        ),
      ),
    );
  }
}
