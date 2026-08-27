import 'dart:math' as math;

import 'package:camrun/core/extensions/context_x.dart';
import 'package:flutter/material.dart';

/// Organic brand-coloured blob with a glyph on top. Stands in for the hand-drawn
/// artwork on the onboarding and welcome screens; drop a real asset into
/// [child] when the illustrations are ready.
class BlobIllustration extends StatelessWidget {
  const BlobIllustration({
    required this.icon,
    this.seed = 0,
    this.size = 240,
    super.key,
  });

  final IconData icon;
  final int seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BlobPainter(
          seed: seed,
          fill: c.primaryContainer,
          accent: c.primary.withValues(alpha: 0.18),
        ),
        child: Center(
          child: Icon(icon, size: size * 0.32, color: c.primary),
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({required this.seed, required this.fill, required this.accent});

  final int seed;
  final Color fill;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawPath(_blob(size, seed, 0.46), Paint()..color = fill)
      ..drawPath(_blob(size, seed + 7, 0.36), Paint()..color = accent);
  }

  Path _blob(Size size, int seed, double radiusFactor) {
    final rnd = math.Random(seed);
    final center = size.center(Offset.zero);
    final base = size.shortestSide * radiusFactor;
    const steps = 8;
    final points = <Offset>[
      for (var i = 0; i < steps; i++)
        () {
          final angle = i / steps * math.pi * 2;
          final r = base * (0.85 + rnd.nextDouble() * 0.3);
          return center + Offset(math.cos(angle) * r, math.sin(angle) * r);
        }(),
    ];

    // Close the loop with quadratic segments through the midpoints so the
    // outline stays smooth rather than polygonal.
    final path = Path();
    Offset mid(Offset a, Offset b) =>
        Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    path.moveTo(
      mid(points.last, points.first).dx,
      mid(points.last, points.first).dy,
    );
    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      final m = mid(current, next);
      path.quadraticBezierTo(current.dx, current.dy, m.dx, m.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_BlobPainter old) =>
      old.seed != seed || old.fill != fill || old.accent != accent;
}
