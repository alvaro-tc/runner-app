import 'dart:math' as math;

import 'package:camrun/core/extensions/context_x.dart';
import 'package:flutter/material.dart';

/// El anillo de la semana: cuanto se ha corrido sobre la meta.
///
/// Dibujado a mano y no con un `CircularProgressIndicator` porque necesita tres
/// cosas que ese no da: el degradado de la marca girando con el arco, el punto
/// luminoso en la punta y el barrido animado desde el valor anterior cuando se
/// desliza de semana.
class GoalRing extends StatelessWidget {
  const GoalRing({
    required this.progress,
    required this.child,
    this.size = 128,
    this.stroke = 11,
    super.key,
  });

  /// 0 a 1. Por encima de 1 se recorta: el anillo lleno ya dice "meta hecha",
  /// y una segunda vuelta se leeria como media vuelta.
  final double progress;
  final Widget child;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final target = progress.clamp(0.0, 1.0).toDouble();

    Widget paint(double value) => CustomPaint(
      painter: _RingPainter(
        progress: value,
        stroke: stroke,
        track: c.ringTrack,
        colors: [c.primary, c.primaryLight, c.accentBlue],
      ),
      child: Center(child: child),
    );

    return SizedBox(
      width: size,
      height: size,
      child: context.reduceMotion
          ? paint(target)
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: target),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => paint(value),
            ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.track,
    required this.colors,
  });

  final double progress;
  final double stroke;
  final Color track;
  final List<Color> colors;

  static const _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final center = rect.center;

    canvas.drawCircle(
      center,
      rect.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      _start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          transform: const GradientRotation(_start),
          colors: colors,
        ).createShader(rect),
    );

    // La punta: un circulito mas claro que marca donde se quedo la semana.
    final tip = Offset(
      center.dx + rect.width / 2 * math.cos(_start + sweep),
      center.dy + rect.height / 2 * math.sin(_start + sweep),
    );
    canvas
      ..drawCircle(
        tip,
        stroke * 0.75,
        Paint()..color = colors.last.withValues(alpha: 0.25),
      )
      ..drawCircle(
        tip,
        stroke * 0.32,
        Paint()..color = const Color(0xFFFFFFFF),
      );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.stroke != stroke;
}
