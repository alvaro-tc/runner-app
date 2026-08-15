import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:paceup/core/extensions/context_x.dart';

/// Event artwork. Falls back to a painted brand pattern whenever the entity has
/// no image URL (which is every record in the fake data layer) or the download
/// fails, so no screen ever renders a grey box.
class EventImage extends StatelessWidget {
  const EventImage({
    required this.imageUrl,
    required this.seedText,
    this.icon = Icons.directions_run_rounded,
    super.key,
  });

  final String imageUrl;

  /// Drives the generated pattern so each event looks consistently different.
  final String seedText;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _fallback(context);
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, _) => _fallback(context),
      errorWidget: (context, _, _) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) => CustomPaint(
    painter: _PatternPainter(
      seed: seedText.hashCode,
      gradient: context.colors.routeGradient,
      lineColor: context.colors.onPrimary.withValues(alpha: 0.16),
    ),
    child: Center(
      child: Icon(
        icon,
        size: 48,
        color: context.colors.onPrimary.withValues(alpha: 0.7),
      ),
    ),
  );
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({
    required this.seed,
    required this.gradient,
    required this.lineColor,
  });

  final int seed;
  final Gradient gradient;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    final rnd = math.Random(seed);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = lineColor;

    // A few sweeping route-like curves, deterministic per seed.
    for (var i = 0; i < 4; i++) {
      final path = Path()..moveTo(-20, size.height * rnd.nextDouble());
      for (var x = 0.0; x <= size.width + 20; x += size.width / 5) {
        path.lineTo(x, size.height * (0.15 + 0.7 * rnd.nextDouble()));
      }
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.seed != seed || old.lineColor != lineColor;
}
