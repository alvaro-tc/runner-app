import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/theme/app_spacing.dart';

/// Gradient completion arc with a centred label. Used by the weekly plan strip
/// and by the "hold to finish" control in a live session.
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    required this.progress,
    this.size = AppSizes.dayRing,
    this.strokeWidth = 4,
    this.label,
    this.child,
    this.emphasised = false,
    this.animate = true,
    super.key,
  });

  /// 0..1, clamped.
  final double progress;
  final double size;
  final double strokeWidth;
  final String? label;
  final Widget? child;

  /// Today's column gets a thicker arc.
  final bool emphasised;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final target = progress.clamp(0.0, 1.0);
    final stroke = emphasised ? strokeWidth + 2 : strokeWidth;

    Widget ring(double value) => Center(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: value,
            strokeWidth: stroke,
            track: c.ringTrack,
            gradient: c.brandGradient,
          ),
          child: Center(
            child:
                child ??
                (label == null
                    ? null
                    : Text(
                        label!,
                        style: context.text.labelSm.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      )),
          ),
        ),
      ),
    );

    if (!animate || context.reduceMotion) return ring(target);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: AppDurations.slow,
      curve: AppDurations.curve,
      builder: (context, value, _) => ring(value),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.track,
    required this.gradient,
  });

  final double progress;
  final double strokeWidth;
  final Color track;
  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inner = rect.deflate(strokeWidth / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = track;

    canvas.drawArc(inner, 0, math.pi * 2, false, base);
    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);

    canvas.drawArc(inner, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.strokeWidth != strokeWidth;
}

/// Rest days show a filled circle with an icon instead of an arc.
class RestDayDot extends StatelessWidget {
  const RestDayDot({this.size = AppSizes.dayRing, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.primaryContainer,
        ),
        child: Icon(
          Icons.bedtime_outlined,
          size: size * 0.36,
          color: c.primary,
        ),
      ),
    );
  }
}
