import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Entrada con fundido y un leve ascenso, con [delay] para escalonar listas.
///
/// Implicita a proposito: el retardo es el tramo inicial de la curva, asi que
/// no hay controlador, temporizador ni `dispose` que olvidar. Con movimiento
/// reducido el hijo aparece tal cual.
class FadeInUp extends StatelessWidget {
  const FadeInUp({required this.child, this.delay = Duration.zero, super.key});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;

    final total = AppDurations.slow + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: AppDurations.curve,
      ),
      child: child,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * AppSpacing.base),
          child: child,
        ),
      ),
    );
  }
}
